
## 개요: 실습의 목표와 흐름

이 실습은 **"ETL to ML"** 이라는 현대적인 데이터 프로젝트의 전 과정을 경험하는 것을 목표로 합니다.

*   **ETL (Extract, Transform, Load)**: 원본 데이터(항공 운항 정시 데이터)를 추출(Extract)하여 클라우드 스토리지에 저장하고, Azure Data Factory를 사용해 Azure SQL 데이터베이스로 적재(Load)한 후, SQL을 통해 분석하기 좋은 형태로 가공(Transform)합니다.
*   **to ML (Machine Learning)**: 정제된 데이터를 바탕으로 Azure Machine Learning의 AutoML(자동화된 기계 학습) 기능을 사용해 '항공편이 15분 이상 지연될지'를 예측하는 분류 모델을 만듭니다.

이 과정을 통해 데이터 엔지니어링부터 데이터 과학까지 이어지는 파이프라인을 직접 구축하고 이해하게 됩니다.


---

# **1일 실습: Azure SQL + 항공편 지연 (정시 운항 실적) — ETL부터 ML까지**

**소요 시간**: 휴식 포함 약 7시간  
**목표**: 실제 항공편 정시 운항 실적 데이터를 수집 → 스토리지에 저장(Landing) → Azure SQL에 적재(Load) → 데이터 분석 → `ArrDelayed15`(15분 이상 도착 지연 여부)를 예측하는 간단한 머신러닝 모델 구축

### **아키텍처 (Architecture)**

**Storage (landing) → Data Factory (Copy) → Azure SQL (staging → curated) → Power BI/Synapse (선택) → Azure ML (AutoML)**

*   **개념 설명: 데이터 흐름과 각 서비스의 역할**
    *   **Storage (Azure Blob Storage)**: 원본 데이터가 처음으로 클라우드에 저장되는 공간입니다. '랜딩 존(Landing Zone)'이라고도 불리며, 가공되지 않은 순수한 원본(raw data)을 그대로 보관하는 역할을 합니다.
    *   **Data Factory (ADF)**: 클라우드 기반의 데이터 통합 및 ETL 서비스입니다. 여기서는 스토리지에 있는 CSV 파일을 Azure SQL 데이터베이스로 복사하는 파이프라인(작업 흐름)을 만듭니다.
    *   **Azure SQL**: Microsoft의 관리형 클라우드 데이터베이스(PaaS)입니다.
        *   **Staging (스테이징)**: 원본 데이터를 거의 그대로 임시 저장하는 테이블 영역입니다. 데이터 타입 검증이나 최소한의 정리를 위해 사용됩니다.
        *   **Curated (큐레이팅/정제)**: 스테이징 데이터를 최종 분석 및 활용에 적합하도록 깨끗하게 정제하고 구조화하여 저장하는 테이블 영역입니다. '골드(Gold) 레코드'라고도 부릅니다.
    *   **Power BI / Synapse (선택 사항)**: 정제된 데이터를 시각적으로 분석(Power BI)하거나, 더 큰 규모의 데이터 웨어하우징 및 빅데이터 분석(Azure Synapse Analytics)에 활용할 수 있습니다.
    *   **Azure ML (AutoML)**: Azure의 머신러닝 플랫폼입니다.
        *   **AutoML (자동화된 Machine Learning)**: 데이터만 제공하면 피처 엔지니어링, 알고리즘 선택, 하이퍼파라미터 튜닝 등 모델 개발의 여러 단계를 자동으로 수행하여 최적의 모델을 찾아주는 기능입니다.

---

### **사전 준비 사항 (Prerequisites)**

*   Azure 구독(Subscription)의 소유자(Owner) 또는 기여자(Contributor) 권한
*   필요 도구: Azure Portal, Azure Data Studio (또는 SSMS), Power BI (선택), Python 3.10+ (선택)

*   **용어 설명**
    *   **Azure 구독**: Azure 서비스를 사용하고 비용을 지불하기 위한 계정 단위입니다.
    *   **Owner/Contributor**: 구독 내에서 리소스를 생성, 수정, 삭제할 수 있는 권한(RBAC 역할)입니다.
    *   **Azure Data Studio / SSMS**: Azure SQL을 포함한 SQL Server 계열 데이터베이스에 연결하고 쿼리를 실행할 수 있는 클라이언트 도구입니다.

---

### **Step 0. 핵심 리소스 배포 (ARM)**

1.  `arm-template.json` 파일을 다운로드하고 Azure Portal에서 "사용자 지정 템플릿 배포"를 통해 배포합니다.
2.  설정할 매개변수:
    *   `sqlAdminLogin`, `sqlAdminPassword` (SQL 서버 관리자 계정 및 암호)
    *   이름들은 기본값을 유지하고, 위치(location)는 가장 가까운 리전(region)을 선택합니다.
3.  출력(Outputs) 확인: 배포 후 생성된 스토리지 계정 이름, ADF 이름, AML 워크스페이스, SQL 서버/DB 이름을 확인합니다.

> 약 5분 소요. 배포 과정에서 SQL 서버 방화벽에 **"Azure 서비스 및 리소스가 이 서버에 액세스하도록 허용"** 규칙이 자동으로 추가됩니다.

*   **개념 설명: ARM 템플릿 (Azure Resource Manager Template)**
    *   **정의**: Azure 리소스를 코드로 정의하고 배포(IaC, Infrastructure as Code)하는 JSON 파일입니다.
    *   **장점**: 클릭 몇 번으로 스토리지, 데이터베이스, 데이터 팩토리 등 필요한 모든 인프라를 한 번에, 반복적으로, 일관되게 생성할 수 있어 수동 설정의 실수를 줄이고 배포를 자동화할 수 있습니다.
    *   이 실습의 `arm-template.json`은 필요한 모든 Azure 서비스를 미리 정의해 놓은 '설계도'입니다.

---

### **Step 1. 실제 데이터 가져오기 (BTS 정시 운항 실적)**

*   출처: 미국 교통 통계국(U.S. DOT BTS)의 "정시 운항 실적" 데이터 (1987년~현재). 관련 문서 및 다운로드 페이지를 참조하세요.
    *   개요: [Airline On-Time Statistics](https://www.transtats.bts.gov/OT_Delay/OT_DelayCause1.asp)
    *   실습을 가볍게 유지하기 위해 **단일 월의 CSV 파일** (예: 2016년 1월)을 사용합니다.

**수동 작업 (수업에 가장 간단한 방법):**

1.  BTS 사이트에서 한 달 치 데이터(ZIP 파일)를 다운로드합니다.
2.  압축을 풀어 파일명을 `on_time_sample.csv`로 변경합니다.
3.  Azure Portal을 통해 스토리지 계정 → **`landing`** 컨테이너 → **`flights/`** 폴더에 업로드합니다.

> 참고: BTS 데이터는 월별 ZIP/CSV 파일로 제공됩니다. 실습에서는 "한 달" 분량의 데이터로 충분합니다.

*   **개념 설명**
    *   **컨테이너(Container)**: Azure Blob Storage에서 파일을 정리하기 위한 최상위 폴더와 같은 개념입니다.

---

### **Step 2. Azure SQL 준비**

1.  Azure Data Studio를 사용하여 Azure SQL(`flights` 데이터베이스)에 연결합니다.
2.  `sql-create-and-transform.sql` 스크립트를 실행합니다.
    *   이 스크립트는 `flight.stg_on_time` (원본 저장용) 테이블과 `flight.on_time` (정제된 데이터용) 테이블을 생성합니다.
    *   데이터 복사 **후에** 이 스크립트의 일부(INSERT 문)를 다시 실행하여 `flight.on_time` 테이블에 데이터를 채우게 됩니다.

*   **개념 설명: 스키마(Schema)**
    *   SQL에서 `flight.` 과 같이 테이블 이름 앞에 붙는 부분은 스키마입니다. 관련된 테이블과 객체들을 논리적으로 그룹화하는 역할을 합니다. 여기서는 `flight` 라는 스키마 안에 스테이징과 정제 테이블을 모두 관리합니다.

---

### **Step 3. Azure Data Factory로 데이터 가져오기**

1.  ADF Studio에서 다음 JSON 파일들을 가져오기(Import) 합니다:
    *   `linkedService_ls_storage.json` → `REPLACEME` 부분을 실제 스토리지 계정 이름으로 교체합니다.
    *   `linkedService_ls_sql.json` → SQL 사용자/암호 및 서버 이름을 설정합니다.
    *   `dataset_ds_landing_flight_csv.json`
    *   `dataset_ds_sql_staging.json`
    *   `pipeline_pl_copy_flight_csv_to_sql.json`
2.  모든 변경 사항을 게시(Publish)한 후, 파이프라인을 **디버그(Debug) 또는 실행(Trigger)** 합니다.
3.  `flight.stg_on_time` 테이블의 행 수를 확인하여 데이터가 잘 들어왔는지 검증합니다:
    ```sql
    SELECT COUNT(*) FROM flight.stg_on_time;
    ```
4.  정제된 테이블로 데이터를 변환합니다:
    ```sql
    -- 필요한 경우, sql-create-and-transform.sql 스크립트 내부의 INSERT 매핑 부분을 다시 실행합니다.
    SELECT TOP 20 * FROM flight.on_time ORDER BY flight_date DESC;
    ```

*   **개념 설명: ADF 구성 요소**
    *   **Linked Service (연결된 서비스)**: 외부 데이터 저장소(Azure Storage, Azure SQL 등)나 컴퓨팅 환경에 대한 연결 정보(연결 문자열 등)를 정의합니다. '데이터베이스 접속 정보'와 유사합니다.
    *   **Dataset (데이터셋)**: 사용할 데이터의 구조(스키마)와 위치를 정의합니다. '특정 테이블'이나 '특정 CSV 파일'을 가리킵니다.
    *   **Pipeline (파이프라인)**: 데이터 복사(Copy), 변환(Transform) 등의 작업(Activity)들을 묶어 논리적인 실행 흐름을 정의합니다. 이 실습의 파이프라인은 'CSV 파일에서 SQL 테이블로 데이터를 복사'하는 하나의 작업으로 구성됩니다.
    *   **Debug/Trigger**: 파이프라인을 테스트(Debug)하거나 실제 실행(Trigger)하는 기능입니다.

---

### **Step 4. 간단한 분석 아이디어 (SQL)**

*   15분 이상 도착 지연이 잦은 상위 노선(출발지-목적지) 찾기
    ```sql
    SELECT TOP 10 origin, dest, COUNT(*) AS flights, SUM(CASE WHEN arr_delayed_15=1 THEN 1 ELSE 0 END) AS delayed,
           CAST(100.0*SUM(CASE WHEN arr_delayed_15=1 THEN 1 ELSE 0 END)/COUNT(*) AS decimal(5,2)) AS delay_rate_pct
    FROM flight.on_time
    GROUP BY origin, dest
    HAVING COUNT(*) > 200 -- 통계적 의미를 위해 운항 횟수가 200회 이상인 노선만 필터링
    ORDER BY delay_rate_pct DESC;
    ```
*   도착 시간대별 지연율 패턴 분석
    ```sql
    SELECT arr_hour = DATEPART(HOUR, arr_scheduled), -- 예정 도착 시간에서 '시간' 부분만 추출
           AVG(CAST(arr_delayed_15 AS float)) AS delay_rate
    FROM flight.on_time
    GROUP BY DATEPART(HOUR, arr_scheduled)
    ORDER BY arr_hour;
    ```
---

### **Step 5. 머신러닝 (Azure ML AutoML)**

1.  `aml/automl_flight_delay.py` 파일을 엽니다.
2.  SQL 서버 정보 및 자격 증명 부분을 교체합니다 (`REPLACEME`, `@@SQL_USER@@`, `@@SQL_PASSWORD@@`).
3.  `DefaultAzureCredential`이 AML 워크스페이스 구성 정보(`config.json`)를 찾을 수 있도록 하거나, 관련 환경 변수를 설정합니다.
4.  스크립트를 로컬 환경에서 실행합니다. 이 스크립트는 다음을 수행합니다:
    *   `flight.on_time` 테이블에서 샘플 데이터를 가져옵니다.
    *   AutoML 분류(Classification) 작업을 정의합니다 (레이블: `arr_delayed_15`).
    *   AML 서비스에 작업을 제출합니다 (10번의 시도, 30분 시간제한).
5.  AML Studio에서 결과를 확인하고, 가장 성능이 좋은 모델을 등록(Register)한 후 **관리형 온라인 엔드포인트(Managed Online Endpoint)**로 원클릭 배포합니다.

**선택 사항**: 노트북(Notebook)에서 배포된 엔드포인트를 호출하여 특정 날짜/노선에 대한 예측을 수행하고, 그 결과를 다시 SQL에 저장해볼 수 있습니다.

*   **개념 설명**
    *   **`DefaultAzureCredential`**: Azure SDK가 사용할 인증 정보를 자동으로 찾아주는 편리한 기능입니다. 환경 변수, 관리 ID, Azure CLI 로그인 정보 등 여러 위치에서 순차적으로 자격 증명을 찾습니다.
    *   **Label (레이블)**: 머신러닝에서 예측하고자 하는 목표 값입니다. 여기서는 '15분 이상 지연 여부'(`arr_delayed_15`)가 레이블입니다.
    *   **Managed Online Endpoint**: 학습된 모델을 실시간 예측 API로 쉽게 배포하고 관리할 수 있는 Azure ML의 기능입니다. 인프라 관리(확장, 업데이트, 보안 등)를 Azure가 대신 처리해주어 매우 편리합니다.

---

### **정리 (Cleanup)**

*   AML 엔드포인트를 생성했다면 중지하거나 삭제합니다.
*   실습이 끝난 후에는 리소스 그룹(Resource Group) 전체를 삭제하여 비용이 발생하지 않도록 합니다.

---

### **문제 해결 팁 (Troubleshooting)**

*   **ADF가 파일을 찾지 못할 때**: ADF의 시스템 할당 관리 ID(System-assigned MI)가 스토리지 계정에 대해 **"Storage Blob 데이터 기여자(Blob Data Contributor)"** 역할을 가지고 있는지 확인하세요 (ARM 템플릿이 이 설정을 자동으로 수행합니다).
*   **복사 중 데이터 타입 불일치**: 스키마 매핑을 명시적으로 설정하거나, 이 실습처럼 우선 문자열(varchar) 타입의 스테이징 테이블로 가져온 후, 변환 과정에서 정확한 타입으로 캐스팅(CAST)합니다.
*   **SQL 시간 필드**: 원본 데이터의 시간 필드(예: 1430)는 정수형입니다. 변환 스크립트(`sql-create-and-transform.sql`)가 이를 SQL의 `time(0)` 데이터 타입으로 변환합니다.

---

### 📄 `arm-template.json`: Azure 리소스 배포 템플릿 (해설)

이 JSON 파일은 실습에 필요한 모든 Azure 인프라를 정의한 '설계도'입니다. 전체를 번역하기보다 핵심 구조와 역할을 설명하겠습니다.

*   **`parameters`**: 템플릿 배포 시 사용자가 입력할 수 있는 값들입니다. (예: `sqlAdminLogin`, `sqlAdminPassword`). 기본값이 지정되어 있어 사용자가 최소한의 정보만 입력하도록 돕습니다.
*   **`variables`**: 템플릿 내부에서 반복적으로 사용될 값을 정의합니다. 여기서는 리소스 그룹 ID를 기반으로 고유한 스토리지 계정 이름을 생성하는 데 사용됩니다.
*   **`resources`**: **가장 중요한 부분**으로, 실제로 생성될 Azure 리소스들을 배열 형태로 정의합니다.
    *   `Microsoft.Storage/storageAccounts`: 데이터를 저장할 Azure Storage 계정.
    *   `Microsoft.Storage/.../containers`: 스토리지 계정 내에 `landing`, `curated` 라는 두 개의 컨테이너(폴더)를 생성.
    *   `Microsoft.KeyVault/vaults`: 암호나 키 같은 비밀 정보를 안전하게 저장하는 Key Vault.
    *   `Microsoft.Sql/servers`, `.../databases`: Azure SQL 서버와 `flights` 데이터베이스.
    *   `Microsoft.Sql/.../firewallRules`: Azure 서비스들이 SQL 서버에 접근할 수 있도록 방화벽 규칙을 설정.
    *   `Microsoft.DataFactory/factories`: ETL 작업을 수행할 Azure Data Factory. `identity: { "type": "SystemAssigned" }` 설정으로 관리 ID를 활성화합니다.
    *   `Microsoft.MachineLearningServices/workspaces`: 머신러닝 작업을 위한 Azure ML 워크스페이스.
    *   `Microsoft.Authorization/roleAssignments`: **ADF와 스토리지를 연결하는 핵심 부분**. Data Factory의 관리 ID(`principalId`)에게 스토리지(`scope`)에 대한 "Storage Blob 데이터 기여자"(`roleDefinitionId`) 권한을 부여합니다. 이로써 ADF는 암호 없이도 스토리지에 안전하게 접근할 수 있습니다.
*   **`outputs`**: 배포가 완료된 후 생성된 리소스들의 이름이나 속성을 출력해줍니다. 사용자가 포털에서 생성된 리소스 이름을 쉽게 확인할 수 있습니다.

---

### 📄 `automl_flight_delay.py`: AutoML 실행 파이썬 스크립트 (번역 및 주석 해설)

이 스크립트는 로컬 PC나 컴퓨팅 인스턴스에서 실행하여 Azure ML에서 AutoML 작업을 시작하는 역할을 합니다.

```python
# Azure ML AutoML 분류 - 항공편 지연(15분 이상 도착) 예측
# 사전 요구사항: pip install azure-ai-ml azure-identity pandas scikit-learn pyodbc
import os, pandas as pd
from sklearn.model_selection import train_test_split
from azure.identity import DefaultAzureCredential
from azure.ai.ml import MLClient
from azure.ai.ml import Input
from azure.ai.ml.automl import classification

# --- Azure SQL에서 데이터 로드 (연결 문자열 수정 필요) ---
import pyodbc
# ODBC 드라이버와 서버, DB, 사용자 정보를 사용하여 연결 문자열을 구성합니다.
cn = pyodbc.connect('Driver={ODBC Driver 18 for SQL Server};Server=tcp:REPLACEME.database.windows.net,1433;Database=flights;Uid=@@SQL_USER@@;Pwd=@@SQL_PASSWORD@@;Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;')

# pandas를 사용해 SQL 쿼리 결과를 DataFrame으로 직접 읽어옵니다.
# 성능을 위해 10만 건의 샘플만 사용하고, 취소/회항된 비행은 제외합니다.
df = pd.read_sql("""
SELECT TOP 100000
  year, month, day, dow,  -- 날짜 관련 피처
  carrier, origin, dest,  -- 항공사, 출발지, 목적지 (범주형 피처)
  CAST(DATEPART(HOUR, dep_scheduled) AS int) AS dep_hour, -- 예정 출발 시간(시)
  CAST(DATEPART(HOUR, arr_scheduled) AS int) AS arr_hour, -- 예정 도착 시간(시)
  distance, cancelled, diverted,
  CAST(arr_delayed_15 AS int) AS label -- 예측 목표(레이블)
FROM flight.on_time
WHERE cancelled = 0 AND diverted = 0
""", cn)

# --- 기본적인 데이터 인코딩 ---
# 머신러닝 모델은 문자열을 직접 이해하지 못하므로, 범주형 데이터를 숫자(코드)로 변환합니다.
# 예: 'DL' -> 0, 'AA' -> 1, 'UA' -> 2
for col in ['carrier','origin','dest']:
    df[col] = df[col].astype('category').cat.codes

# 데이터를 피처(X)와 레이블(y)로 분리합니다.
X = df.drop(columns=['label'])
y = df['label']

# 학습 데이터와 테스트 데이터로 분할합니다. (80% 학습, 20% 테스트)
# stratify=y 옵션은 학습/테스트 데이터셋의 지연/정시 비율을 원본 데이터와 동일하게 유지해줍니다.
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42, stratify=y)

# --- AML에 연결 ---
# Azure CLI 로그인 정보, 환경 변수 등에서 자동으로 자격 증명을 찾습니다.
cred = DefaultAzureCredential(exclude_interactive_browser_credential=False)
# 작업 디렉터리의 config.json 파일을 읽거나 환경 변수를 사용하여 AML 워크스페이스에 연결합니다.
ml_client = MLClient.from_config(cred)

# --- AutoML 분류 작업 정의 ---
job = classification(
    # 별도의 컴퓨팅 클러스터 없이 Azure가 관리하는 서버리스 컴퓨팅을 사용합니다.
    compute='serverless',
    # 실험을 그룹화할 이름
    experiment_name='flight-delay-automl',
    # 예측할 대상 컬럼 이름
    target_column_name='label',
    # 학습 데이터 (피처 + 레이블)
    training_data=pd.concat([X_train, y_train], axis=1),
    # 모델 성능 검증에 사용할 데이터
    validation_data=pd.concat([X_test, y_test], axis=1),
    # 최적 모델을 선택할 주요 성능 지표. AUC_weighted는 불균형 데이터셋에 적합합니다.
    primary_metric='AUC_weighted',
    # 데이터 전처리 및 피처 엔지니어링을 자동으로 수행하도록 설정합니다.
    featurization='auto',
    # 작업 제한 시간 및 시도 횟수를 설정하여 비용과 시간을 제어합니다.
    limits={'timeout_minutes': 30, 'max_trials': 10}
)

# 정의된 작업을 Azure ML 서비스에 제출합니다.
returned_job = ml_client.jobs.create_or_update(job)
print('AutoML 작업 제출 완료:', returned_job.name)
print('Azure ML Studio로 이동하여 진행 상황을 확인하고, 최적 모델을 등록한 후 관리형 온라인 엔드포인트로 배포하세요.')

```

*   **용어 설명**
    *   **AUC_weighted**: 모델 성능 평가 지표 중 하나인 AUC(Area Under the Curve)의 가중 평균입니다. 레이블의 분포가 불균형할 때(예: 지연보다 정시 도착이 훨씬 많을 때) 각 클래스의 중요도를 고려하여 모델을 더 공정하게 평가할 수 있습니다.
    *   **`serverless` compute**: AML에서 제공하는 온디맨드 컴퓨팅 옵션입니다. 사용자가 직접 클러스터를 생성하고 관리할 필요 없이, 작업이 제출되면 Azure가 필요한 컴퓨팅 자원을 할당하고 작업이 끝나면 자동으로 해제합니다. 프로토타이핑이나 간헐적인 작업에 매우 유용합니다.
