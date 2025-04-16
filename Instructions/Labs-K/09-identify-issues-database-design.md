## 실습 9 – 데이터베이스 디자인 문제 식별

**모듈:** Azure SQL에서 쿼리 성능 최적화

---

# 데이터베이스 디자인 문제 식별

**예상 소요 시간: 15분**

**시나리오:**

수강생은 학습한 내용을 바탕으로 AdventureWorks 내 디지털 전환 프로젝트의 결과물을 파악합니다. Azure Portal 및 기타 도구를 검토하여 네이티브 도구를 활용하여 성능 관련 문제를 식별하고 해결하는 방법을 결정합니다. 마지막으로, 수강생은 정규화, 데이터 형식 선택 및 인덱스 디자인과 관련된 문제에 대해 데이터베이스 디자인을 평가할 수 있게 됩니다.

여러분은 성능 관련 문제를 식별하고 발견된 문제를 해결하기 위한 실행 가능한 솔루션을 제공하는 데이터베이스 관리자로 고용되었습니다. AdventureWorks는 10년 이상 자전거 및 자전거 부품을 소비자와 유통업체에 직접 판매해 왔습니다. 여러분의 임무는 쿼리 성능 문제를 식별하고 이 모듈에서 배운 기술을 사용하여 해결하는 것입니다.

> &#128221; 이 연습에서는 T-SQL 코드를 복사하여 붙여넣습니다. 코드를 실행하기 전에 코드가 올바르게 복사되었는지 확인하십시오.

---

**1단계: 환경 설정**

랩 가상 머신이 제공되고 미리 구성된 경우 **C:\LabFiles** 폴더에 랩 파일이 준비되어 있을 것입니다. *잠시 확인하여 파일이 이미 있는지 확인하고, 있다면 이 섹션을 건너뜁니다*. 그러나 자신의 컴퓨터를 사용하거나 랩 파일이 없는 경우 계속 진행하려면 *GitHub*에서 복제해야 합니다.

1.  제공된 랩 가상 머신 또는 제공되지 않은 경우 로컬 컴퓨터에서 Visual Studio Code 세션을 시작합니다.

2.  명령 팔레트(Ctrl+Shift+P)를 열고 **Git: Clone**을 입력합니다. **Git: Clone** 옵션을 선택합니다.

3.  **리포지토리 URL** 필드에 다음 URL을 붙여넣고 **Enter** 키를 누릅니다.

    ```url
    https://github.com/MicrosoftLearning/dp-300-database-administrator.git
    ```

4.  랩 가상 머신 또는 제공되지 않은 경우 로컬 컴퓨터의 **C:\LabFiles** 폴더에 리포지토리를 저장합니다(폴더가 없으면 만듭니다).

---

**2단계: 데이터베이스 복원**

**AdventureWorks2017** 데이터베이스가 이미 복원되어 있다면 이 섹션을 건너뛸 수 있습니다.

1.  제공된 랩 가상 머신 또는 제공되지 않은 경우 로컬 컴퓨터에서 SQL Server Management Studio(SSMS) 세션을 시작합니다.

2.  SSMS가 열리면 기본적으로 **서버에 연결** 대화 상자가 나타납니다. 기본 인스턴스를 선택하고 **연결**을 선택합니다. **서버 인증서 신뢰** 확인란을 선택해야 할 수 있습니다.

    > &#128221; 자체 SQL Server 인스턴스를 사용하는 경우 적절한 서버 인스턴스 이름과 자격 증명을 사용하여 연결해야 합니다.

3.  **데이터베이스** 폴더를 선택한 다음 **새 쿼리**를 선택합니다.

4.  새 쿼리 창에 아래 T-SQL을 복사하여 붙여넣습니다. 쿼리를 실행하여 데이터베이스를 복원합니다.

    ```sql
    RESTORE DATABASE AdventureWorks2017
    FROM DISK = 'C:\LabFiles\dp-300-database-administrator\Allfiles\Labs\Shared\AdventureWorks2017.bak'
    WITH RECOVERY,
          MOVE 'AdventureWorks2017'
            TO 'C:\LabFiles\AdventureWorks2017.mdf',
          MOVE 'AdventureWorks2017_log'
            TO 'C:\LabFiles\AdventureWorks2017_log.ldf';
    ```

    > &#128221; **C:\LabFiles**라는 폴더가 있어야 합니다. 이 폴더가 없으면 생성하거나 데이터베이스 및 백업 파일에 대한 다른 위치를 지정하십시오.

5.  **메시지** 탭 아래에 데이터베이스가 성공적으로 복원되었음을 나타내는 메시지가 표시되어야 합니다.

---

**3단계: 쿼리 검토 및 문제 식별**

1.  **새 쿼리**를 선택합니다. 다음 T-SQL 코드를 쿼리 창에 복사하여 붙여넣습니다. **실행**을 선택하여 이 쿼리를 실행합니다.

    ```sql
    USE AdventureWorks2017
    GO

    SELECT BusinessEntityID, NationalIDNumber, LoginID, HireDate, JobTitle
    FROM HumanResources.Employee
    WHERE NationalIDNumber = 14417807;
    ```

2.  쿼리를 실행하기 전에 **실행** 버튼 오른쪽에 있는 **실제 실행 계획 포함** 아이콘을 선택하거나 **CTRL+M**을 누릅니다. 이렇게 하면 쿼리를 실행할 때 실행 계획이 표시됩니다. **실행**을 선택하여 이 쿼리를 실행합니다.

3.  결과 창에서 **실행 계획** 탭을 선택하여 실행 계획으로 이동합니다. **SELECT** 연산자에 노란색 삼각형과 느낌표가 있는 것을 확인할 수 있습니다. 이는 해당 연산자와 관련된 경고 메시지가 있음을 나타냅니다. 경고 아이콘 위에 마우스를 올려 메시지를 확인하고 경고 메시지를 읽습니다.

    > &#128221; 경고 메시지는 쿼리에 **암시적 변환(implicit conversion)**이 있음을 나타냅니다. 이는 SQL Server 쿼리 최적화 프로그램이 쿼리를 실행하기 위해 쿼리의 열 중 하나의 데이터 형식을 다른 데이터 형식으로 변환해야 했음을 의미합니다.

---

**4단계: 경고 메시지 수정 방법 식별**

*[HumanResources].[Employee]* 테이블 구조는 다음 데이터 정의 언어(DDL) 문으로 정의됩니다. 이전 SQL 쿼리에서 사용된 필드를 이 DDL과 비교하여 검토하고 해당 유형에 주의하십시오.

```sql
CREATE TABLE [HumanResources].[Employee](
     [BusinessEntityID] [int] NOT NULL,
     [NationalIDNumber] [nvarchar](15) NOT NULL, -- NationalIDNumber는 NVARCHAR(텍스트) 형식임
     [LoginID] [nvarchar](256) NOT NULL,
     [OrganizationNode] [hierarchyid] NULL,
     [OrganizationLevel] AS ([OrganizationNode].[GetLevel]()),
     [JobTitle] [nvarchar](50) NOT NULL,
     [BirthDate] [date] NOT NULL,
     [MaritalStatus] [nchar](1) NOT NULL,
     [Gender] [nchar](1) NOT NULL,
     [HireDate] [date] NOT NULL,
     [SalariedFlag] [dbo].[Flag] NOT NULL,
     [VacationHours] [smallint] NOT NULL,
     [SickLeaveHours] [smallint] NOT NULL,
     [CurrentFlag] [dbo].[Flag] NOT NULL,
     [rowguid] [uniqueidentifier] ROWGUIDCOL NOT NULL,
     [ModifiedDate] [datetime] NOT NULL
) ON [PRIMARY]
```

1.  실행 계획에 표시된 경고 메시지에 따라 어떤 변경을 권장하시겠습니까?

    1.  어떤 필드가 암시적 변환을 유발하는지, 그리고 그 이유는 무엇인지 식별합니다.
    2.  쿼리를 검토하면:

        ```sql
        SELECT BusinessEntityID, NationalIDNumber, LoginID, HireDate, JobTitle
        FROM HumanResources.Employee
        WHERE NationalIDNumber = 14417807; -- 여기서 14417807은 숫자로 비교됨
        ```

        **WHERE** 절에서 *NationalIDNumber* 열과 비교되는 값이 따옴표로 묶이지 않은 숫자(**14417807**)로 비교됨을 알 수 있습니다.

        테이블 구조를 검토하면 *NationalIDNumber* 열이 **INT**(정수) 데이터 형식이 아닌 **NVARCHAR**(문자열) 데이터 형식을 사용하고 있음을 알 수 있습니다. 이러한 불일치로 인해 데이터베이스 최적화 프로그램은 숫자를 *NVARCHAR* 값으로 암시적으로 변환하게 되며, 이는 최적이 아닌 계획을 생성하여 쿼리 성능에 추가적인 오버헤드를 유발합니다.

암시적 변환 경고를 수정하기 위해 구현할 수 있는 두 가지 접근 방식이 있습니다. 다음 단계에서 각각을 조사할 것입니다.

---

**5단계: 해결 방법 1 - 코드 변경**

1.  암시적 변환을 해결하기 위해 코드를 어떻게 변경하시겠습니까? 코드를 변경하고 쿼리를 다시 실행하십시오.

    아직 켜져 있지 않다면 **실제 실행 계획 포함**(CTRL+M)을 켜는 것을 잊지 마십시오.

    이 시나리오에서는 값 양쪽에 작은따옴표를 추가하는 것만으로 숫자에서 문자 형식으로 변경됩니다. 이 쿼리에 대한 쿼리 창을 열어 두십시오.

    업데이트된 SQL 쿼리 실행:

    ```sql
    SELECT BusinessEntityID, NationalIDNumber, LoginID, HireDate, JobTitle
    FROM HumanResources.Employee
    WHERE NationalIDNumber = '14417807'; -- 값을 문자열로 비교
    ```

    > &#128221; 경고 메시지가 사라지고 쿼리 계획이 개선되었음을 확인합니다. *WHERE* 절을 변경하여 *NationalIDNumber* 열과 비교되는 값이 테이블의 열 데이터 형식과 일치하도록 함으로써, 최적화 프로그램은 암시적 변환을 제거하고 더 최적의 계획을 생성할 수 있었습니다.

---

**6단계: 해결 방법 2 - 데이터 형식 변경**

1.  테이블 구조를 변경하여 암시적 변환 경고를 수정할 수도 있습니다.

    인덱스를 수정하기 위해 아래 쿼리를 새 쿼리 창에 복사하여 붙여넣고 열의 데이터 형식을 변경합니다. **실행**을 선택하거나 <kbd>F5</kbd> 키를 눌러 쿼리 실행을 시도합니다.

    ```sql
    ALTER TABLE [HumanResources].[Employee] ALTER COLUMN [NationalIDNumber] INT NOT NULL;
    ```

    *NationalIDNumber* 열 데이터 형식을 INT로 변경하면 변환 문제가 해결됩니다. 그러나 이 변경은 데이터베이스 관리자로서 해결해야 하는 또 다른 문제를 야기합니다. 위 쿼리를 실행하면 다음과 같은 오류 메시지가 발생합니다.

    <span style="color:red">메시지 5074, 수준 16, 상태 1, 줄 1
    인덱스 'AK_Employee_NationalIDNumber'이(가) 'NationalIDNumber' 열에 종속되어 있습니다.
    메시지 4922, 수준 16, 상태 9, 줄 1
    하나 이상의 개체가 이 열에 액세스하므로 ALTER TABLE ALTER COLUMN NationalIDNumber이(가) 실패했습니다.</span>

    *NationalIDNumber* 열은 이미 존재하는 비클러스터형 인덱스의 일부이므로, 데이터 형식을 변경하려면 인덱스를 다시 빌드/재생성해야 합니다. **이는 프로덕션 환경에서 장시간의 다운타임으로 이어질 수 있으며, 이는 디자인 시 올바른 데이터 형식을 선택하는 것의 중요성을 강조합니다.**

2.  이 문제를 해결하려면 아래 코드를 쿼리 창에 복사하여 붙여넣고 **실행**을 선택하여 실행합니다.

    ```sql
    USE AdventureWorks2017
    GO

    -- 먼저 인덱스 삭제
    DROP INDEX [AK_Employee_NationalIDNumber] ON [HumanResources].[Employee];
    GO

    -- 암시적 변환 경고를 해결하기 위해 열 데이터 형식 변경
    ALTER TABLE [HumanResources].[Employee] ALTER COLUMN [NationalIDNumber] INT NOT NULL;
    GO

    -- 인덱스 재생성
    CREATE UNIQUE NONCLUSTERED INDEX [AK_Employee_NationalIDNumber] ON [HumanResources].[Employee]( [NationalIDNumber] ASC );
    GO
    ```

3.  다음 쿼리를 실행하여 데이터 형식이 성공적으로 변경되었는지 확인합니다.

    ```sql
    SELECT c.name, t.name AS DataTypeName
    FROM sys.all_columns c INNER JOIN sys.types t
    	ON (c.system_type_id = t.system_type_id AND c.user_type_id = t.user_type_id) -- 수정: system_type_id도 비교
    WHERE OBJECT_ID('[HumanResources].[Employee]') = c.object_id
        AND c.name = 'NationalIDNumber';
    ```

4.  이제 실행 계획을 확인해 보겠습니다. 따옴표 없는 원본 쿼리를 다시 실행합니다.

    ```sql
    USE AdventureWorks2017
    GO

    -- 실제 실행 계획 포함 (CTRL+M)
    SELECT BusinessEntityID, NationalIDNumber, LoginID, HireDate, JobTitle
    FROM HumanResources.Employee
    WHERE NationalIDNumber = 14417807;
    ```

    쿼리 계획을 검토하고, 이제 암시적 변환 경고 없이 정수를 사용하여 *NationalIDNumber*로 필터링할 수 있음을 확인합니다. SQL 쿼리 최적화 프로그램은 이제 가장 최적의 계획을 생성하고 실행할 수 있습니다.

> &#128221; 열의 데이터 형식을 변경하면 암시적 변환 문제를 해결할 수 있지만 항상 최상의 솔루션은 아닙니다. 이 경우 *NationalIDNumber* 열의 데이터 형식을 **INT** 데이터 형식으로 변경하면 해당 열의 인덱스를 삭제하고 다시 생성해야 하므로 프로덕션 환경에서 다운타임이 발생했을 것입니다. 변경하기 전에 열의 데이터 형식을 변경하는 것이 기존 쿼리 및 인덱스에 미치는 영향을 고려하는 것이 중요합니다. 또한 *NationalIDNumber* 열이 **NVARCHAR** 데이터 형식이어야 하는 다른 쿼리가 있을 수 있으므로 데이터 형식을 변경하면 해당 쿼리가 중단될 수 있습니다.

---

**7단계: 정리**

데이터베이스나 랩 파일을 다른 용도로 사용하지 않는 경우 이 실습에서 만든 개체를 정리할 수 있습니다.

**C:\LabFiles 폴더 삭제**

1.  제공된 랩 가상 머신 또는 제공되지 않은 경우 로컬 컴퓨터에서 **파일 탐색기**를 엽니다.
2.  **C:\\** 로 이동합니다.
3.  **C:\LabFiles** 폴더를 삭제합니다.

**AdventureWorks2017 데이터베이스 삭제**

1.  제공된 랩 가상 머신 또는 제공되지 않은 경우 로컬 컴퓨터에서 SQL Server Management Studio(SSMS) 세션을 시작합니다.
2.  SSMS가 열리면 기본적으로 **서버에 연결** 대화 상자가 나타납니다. 기본 인스턴스를 선택하고 **연결**을 선택합니다. **서버 인증서 신뢰** 확인란을 선택해야 할 수 있습니다.
3.  **개체 탐색기**에서 **데이터베이스** 폴더를 확장합니다.
4.  **AdventureWorks2017** 데이터베이스를 마우스 오른쪽 버튼으로 클릭하고 **삭제**를 선택합니다.
5.  **개체 삭제** 대화 상자에서 **기존 연결 닫기** 확인란을 선택합니다.
6.  **확인**을 선택합니다.

---

이것으로 실습을 성공적으로 완료했습니다.

이 연습에서는 암시적 데이터 형식 변환으로 인해 발생하는 쿼리 문제를 식별하고 쿼리 계획을 개선하기 위해 수정하는 방법을 배웠습니다.
