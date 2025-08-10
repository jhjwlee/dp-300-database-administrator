

### **Lab 11 – Azure Resource Manager 템플릿을 사용하여 Azure SQL Database 배포 및 수정하기**

**모듈:** Azure SQL의 데이터베이스 작업 자동화

---

### **개요**

**예상 소요 시간: 20분**

당신은 데이터베이스 관리의 일상적인 운영을 자동화하는 임무를 맡은 시니어 데이터 엔지니어입니다. 이 자동화 작업의 목표는 AdventureWorks의 데이터베이스가 최상의 성능으로 계속 운영되도록 보장하고, 특정 기준에 따라 경고를 제공하는 방법을 구축하는 것입니다. AdventureWorks는 IaaS(Infrastructure as a Service)와 PaaS(Platform as a Service) 환경 모두에서 SQL Server를 사용하고 있습니다.

이 실습에서는 단순한 배포를 넘어, **Azure Resource Manager (ARM) 템플릿**을 직접 수정하여 인프라를 코드로 관리(Infrastructure as Code)하는 실질적인 경험을 하게 됩니다.

### **용어 및 개념 설명**

*   **Azure Resource Manager (ARM) template**: Azure 리소스를 선언적으로 정의하는 JSON 파일입니다. 인프라를 코드로(Infrastructure as Code, IaC) 관리할 수 있게 해주어, 리소스 배포를 자동화하고, 일관성 있게 유지하며, 반복 가능하게 만듭니다.
*   **SKU (Stock Keeping Unit)**: Azure에서는 리소스의 가격 등급(Pricing Tier)과 성능, 용량 등을 정의하는 단위를 의미합니다. 예를 들어, SQL Database의 SKU는 `Basic`, `Standard`, `Premium` 등으로 나뉘며, 각각 다른 성능과 비용을 가집니다.
*   **Firewall rule (방화벽 규칙)**: 특정 IP 주소나 IP 주소 범위에서 Azure SQL Server로 들어오는 네트워크 트래픽을 허용하거나 차단하는 보안 규칙입니다. 데이터베이스를 무단 액세스로부터 보호하는 첫 번째 방어선입니다.

---

### **실습 1: ARM 템플릿 탐색 및 사용자 지정 배포 준비**

1.  Microsoft Edge 브라우저에서 새 탭을 열고, SQL Database 리소스 배포를 위한 ARM 템플릿이 있는 아래 GitHub 리포지토리 경로로 이동합니다.

    ```url
    https://github.com/Azure/azure-quickstart-templates/tree/master/quickstarts/microsoft.sql/sql-database
    ```

2.  `azuredeploy.json` 파일을 마우스 오른쪽 버튼으로 클릭하고, **링크를 새 탭에서 열기**를 선택하여 ARM 템플릿의 내용을 확인합니다.

3.  템플릿의 구조를 잠시 살펴보세요. `parameters`, `variables`, `resources` 등의 섹션으로 구성되어 있음을 확인할 수 있습니다. 이 구조가 Azure에 어떤 리소스를 어떻게 배포할지 정의합니다.

4.  **azuredeploy.json** 탭으로 돌아와, 템플릿의 전체 내용을 복사(Ctrl+A, Ctrl+C)합니다. 이번 실습에서는 "Deploy to Azure" 버튼을 사용하지 않고, 이 코드를 직접 수정하여 배포할 것입니다.

### **실습 2: ARM 템플릿 수정 및 배포 (Hands-on)**

이제부터 이 실습의 핵심인 **핸즈온** 파트입니다. 복사한 템플릿을 Azure Portal에서 직접 수정하여 데이터베이스의 사양을 변경하고 새로운 규칙을 추가해 보겠습니다.

1.  Azure Portal에 로그인합니다. 상단 검색창에 **Deploy a custom template**을 검색하고, 검색 결과에서 해당 서비스를 선택합니다.

    ![Deploy a custom template 검색](../images/dp-300-module-11-lab-custom-01.png)

2.  **Custom deployment** 페이지에서 **Build your own template in the editor**를 선택합니다.

    ![Build your own template in the editor 선택](../images/dp-300-module-11-lab-custom-02.png)

3.  **Edit template** 화면이 나타나면, 기존에 있던 모든 내용을 삭제하고, 이전에 GitHub에서 복사했던 **azuredeploy.json** 템플릿 내용을 붙여넣기(Ctrl+V) 합니다.

#### **수정 1: 데이터베이스 SKU 변경하기**

기본 템플릿은 `Standard` 등급의 데이터베이스를 생성합니다. 개발 및 테스트 용도로 비용을 절감하기 위해 이를 `Basic` 등급으로 변경해 보겠습니다.

4.  편집기에서 `sku` 라는 단어를 검색(Ctrl+F)하여 아래와 같은 부분을 찾습니다.

    ```json
    "sku": {
        "name": "Standard",
        "tier": "Standard"
    },
    ```

5.  이 `sku` 블록을 다음과 같이 `Basic` 등급으로 수정합니다. `name`과 `tier` 값을 모두 변경해야 합니다.

    ```json
    "sku": {
        "name": "Basic",
        "tier": "Basic",
        "capacity": 5
    },
    ```
    > **설명:** `Basic` 등급은 5 DTU(Database Transaction Unit)와 2GB의 저장 공간을 제공하는 가장 기본적인 서비스 계층입니다. `capacity`는 DTU를 의미합니다. 이처럼 `sku` 객체를 수정하여 원하는 성능과 비용의 데이터베이스를 선택할 수 있습니다.

#### **수정 2: 서버 방화벽 규칙(Firewall Rule) 추가하기**

생성된 SQL Server에 외부에서 접속할 수 있도록 방화벽 규칙을 추가해 보겠습니다.

6.  `"type": "Microsoft.Sql/servers"` 리소스 정의가 끝나는 지점( `]` 괄호 바로 위)을 찾습니다. 그리고 그 안에 새로운 리소스로 방화벽 규칙을 추가합니다. 아래의 JSON 코드를 복사하여 `databases` 리소스 블록 **다음**에 붙여넣으세요. (쉼표`,`에 주의하세요)

    > **중요:** 아래 코드는 `"resources": [` 배열 안에, 기존 `databases` 객체 블록이 끝난 후, 쉼표(`,`)를 추가하고 그 뒤에 삽입되어야 합니다.

    ```json
    ,
    {
        "type": "firewallrules",
        "apiVersion": "2020-11-01-preview",
        "name": "AllowAllWindowsAzureIps",
        "dependsOn": [
            "[resourceId('Microsoft.Sql/servers', parameters('serverName'))]"
        ],
        "properties": {
            "startIpAddress": "0.0.0.0",
            "endIpAddress": "0.0.0.0"
        }
    }
    ```

7.  수정된 `Microsoft.Sql/servers` 리소스는 최종적으로 아래와 같은 구조를 가집니다.

    ![수정된 템플릿 구조 예시](../images/dp-300-module-11-lab-custom-03.png)

    > **핸즈온 의미 설명:**
    > *   **`"type": "firewallrules"`**: SQL Server 하위에 방화벽 규칙 리소스를 생성하겠다고 선언하는 부분입니다.
    > *   **`dependsOn`**: ARM 템플릿의 핵심 기능 중 하나로, 리소스 생성 순서를 정의합니다. 이 규칙은 `Microsoft.Sql/servers` 리소스(즉, SQL Server)가 성공적으로 생성된 **이후에** 만들어져야 함을 명시합니다. 의존성 관리를 통해 배포 안정성을 높일 수 있습니다.
    > *   **`properties`**: `startIpAddress`와 `endIpAddress`를 `0.0.0.0`으로 설정하여 모든 Azure 서비스가 이 서버에 접근할 수 있도록 허용하는 규칙입니다. (참고: 실제 운영 환경에서는 보안을 위해 특정 IP 주소 범위를 지정해야 합니다.)

8.  템플릿 수정이 완료되었으면 **Save** 버튼을 클릭합니다.

### **실습 3: 수정된 템플릿 배포 및 결과 확인**

1.  이제 **Custom deployment** 설정 페이지로 돌아왔습니다. 아래 정보를 사용하여 빈 필드를 채웁니다.

    *   **Resource group:** 기존에 사용하던 `contoso-rg`로 시작하는 리소스 그룹을 선택합니다.
    *   **Server Name:** `uniquestring` 함수에 의해 자동으로 고유한 이름이 제안됩니다. 그대로 두거나 원하는 이름으로 변경할 수 있습니다.
    *   **Sql DBName:** `SampleDB` 기본값을 그대로 사용합니다.
    *   **Administrator Login:** `labadmin`
    *   **Administrator Login Password:** `<강력한 암호를 입력하세요>`

2.  **Review + create**를 선택한 후, 유효성 검사가 통과되면 **Create**를 선택합니다. 배포는 약 5분 정도 소요됩니다.

3.  배포가 완료되면 **Go to resource group** 버튼을 클릭합니다.

4.  리소스 그룹으로 이동하여 배포된 리소스를 확인합니다.
    *   템플릿에 의해 생성된 **SQL server** 리소스를 클릭합니다.
    *   **결과 확인 1:** 왼쪽 메뉴의 **Settings** 섹션에서 **Networking**을 선택합니다. **Firewall rules** 탭에 우리가 템플릿에 추가했던 `AllowAllWindowsAzureIps` 규칙이 생성된 것을 확인할 수 있습니다.
    *   **결과 확인 2:** 다시 SQL server의 **Overview** 페이지로 돌아와, 하단에 있는 **SQL databases** 목록에서 `SampleDB`를 클릭합니다. `Pricing tier`가 우리가 수정한 대로 **Basic**으로 표시되는지 확인합니다.

    ![결과 확인](../images/dp-300-module-11-lab-custom-04.png)

---

### **리소스 정리**

이 실습에서 생성한 리소스가 다른 용도로 필요하지 않다면, 아래 절차에 따라 정리해 주십시오. 리소스 그룹 전체를 삭제하거나, 이 실습에서 생성한 리소스만 선택하여 삭제할 수 있습니다. (기존 실습의 정리 절차와 동일)

---

### **결론**

이 실습을 성공적으로 완료하셨습니다.

당신은 이제 단순히 버튼을 클릭하는 것을 넘어, **ARM 템플릿의 코드를 직접 수정**하여 원하는 사양의 **Azure SQL Database**를 배포하고 **방화벽 규칙과 같은 부가적인 리소스를 함께 구성**하는 방법을 배웠습니다. 이를 통해 IaC(Infrastructure as Code)의 강력함과 유연성을 직접 체험했으며, 복잡한 Azure 환경을 자동화하고 관리하는 핵심 기술을 습득했습니다.
