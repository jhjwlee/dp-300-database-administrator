## 실습 3 – Microsoft Entra ID를 사용하여 Azure SQL Database에 대한 액세스 권한 부여

**모듈:** 데이터베이스 서비스에 대한 보안 환경 구현

---

# 데이터베이스 인증 및 권한 부여 구성

**예상 소요 시간: 25분**

수강생은 학습한 내용을 바탕으로 Azure Portal 및 *AdventureWorksLT* 데이터베이스 내에서 보안을 구성하고 구현합니다.

여러분은 데이터베이스 환경의 보안을 보장하기 위해 선임 데이터베이스 관리자로 고용되었습니다.

> &#128221; 이 연습에서는 T-SQL 코드를 복사하여 붙여넣고 기존 SQL 리소스를 사용합니다. 코드를 실행하기 전에 코드가 올바르게 복사되었는지 확인하십시오.

## 환경 설정

랩 가상 머신이 제공되고 미리 구성된 경우 **C:\LabFiles** 폴더에 랩 파일이 준비되어 있을 것입니다. *잠시 확인하여 파일이 이미 있는지 확인하고, 있다면 이 섹션을 건너뜁니다*. 그러나 자신의 컴퓨터를 사용하거나 랩 파일이 없는 경우 계속 진행하려면 *GitHub*에서 복제해야 합니다.

1.  제공된 랩 가상 머신 또는 제공되지 않은 경우 로컬 컴퓨터에서 Visual Studio Code 세션을 시작합니다.

2.  명령 팔레트(Ctrl+Shift+P)를 열고 **Git: Clone**을 입력합니다. **Git: Clone** 옵션을 선택합니다.

3.  **리포지토리 URL** 필드에 다음 URL을 붙여넣고 **Enter** 키를 누릅니다.

    ```url
    https://github.com/MicrosoftLearning/dp-300-database-administrator.git
    ```

4.  랩 가상 머신 또는 제공되지 않은 경우 로컬 컴퓨터의 **C:\LabFiles** 폴더에 리포지토리를 저장합니다(폴더가 없으면 만듭니다).

## Azure에서 SQL Server 설정

Azure에 로그인하고 Azure에서 실행 중인 기존 Azure SQL Server 인스턴스가 있는지 확인합니다. *Azure에서 이미 실행 중인 SQL Server 인스턴스가 있는 경우 이 섹션을 건너뜁니다*.

1.  제공된 랩 가상 머신 또는 제공되지 않은 경우 로컬 컴퓨터에서 Visual Studio Code 세션을 시작하고 이전 섹션에서 복제한 리포지토리로 이동합니다.

2.  **/Allfiles/Labs** 폴더를 마우스 오른쪽 버튼으로 클릭하고 **통합 터미널에서 열기**를 선택합니다.

3.  Azure CLI를 사용하여 Azure에 연결합니다. 다음 명령을 입력하고 **Enter** 키를 누릅니다.

    ```bash
    az login
    ```

    > &#128221; 브라우저 창이 열립니다. Azure 자격 증명을 사용하여 로그인하십시오.

4.  Azure에 로그인했으면, 리소스 그룹이 아직 없는 경우 리소스 그룹을 만들고 해당 리소스 그룹 아래에 SQL 서버와 데이터베이스를 만듭니다. 다음 명령을 입력하고 **Enter** 키를 누릅니다. *스크립트 완료까지 몇 분 정도 걸릴 수 있습니다*.

    ```bash
    cd ./Setup
    ./deploy-sql-database.ps1
    ```

    > &#128221; 기본적으로 이 스크립트는 **contoso-rg**라는 리소스 그룹을 생성하거나, 이름이 *contoso-rg*로 시작하는 리소스가 있는 경우 해당 리소스를 사용합니다. 또한 기본적으로 모든 리소스를 **미국 서부 2(westus2)** 지역에 생성합니다. 마지막으로 **SQL 관리자 암호**에 대해 임의의 12자 암호를 생성합니다. **-rgName**, **-location** 및 **-sqlAdminPw** 매개변수 중 하나 이상을 사용하여 이러한 값을 사용자 지정 값으로 변경할 수 있습니다. 암호는 Azure SQL 암호 복잡성 요구 사항을 충족해야 하며, 길이는 12자 이상이어야 하고 대문자, 소문자, 숫자 및 특수 문자를 각각 하나 이상 포함해야 합니다.

    > &#128221; 스크립트는 현재 공용 IP 주소를 SQL 서버 방화벽 규칙에 추가합니다.

5.  스크립트가 완료되면 리소스 그룹 이름, SQL 서버 이름 및 데이터베이스 이름, 관리자 사용자 이름과 암호를 반환합니다. 나중에 실습에서 필요하므로 이 값들을 기록해 두십시오.

---

## Microsoft Entra를 사용하여 Azure SQL Database에 대한 액세스 권한 부여

`CREATE USER [anna@contoso.com] FROM EXTERNAL PROVIDER` T-SQL 구문을 사용하여 Microsoft Entra 계정에서 포함된 데이터베이스 사용자로 로그인을 만들 수 있습니다. 포함된 데이터베이스 사용자는 데이터베이스와 연결된 Microsoft Entra 디렉터리의 ID에 매핑되며 `master` 데이터베이스에는 로그인이 없습니다.

Azure SQL Database에 Microsoft Entra 서버 로그인이 도입되면서 SQL Database의 가상 `master` 데이터베이스에서 Microsoft Entra 보안 주체로부터 로그인을 만들 수 있습니다. Microsoft Entra *사용자, 그룹 및 서비스 주체*로부터 Microsoft Entra 로그인을 만들 수 있습니다. 자세한 내용은 [Microsoft Entra 서버 보안 주체](/azure/azure-sql/database/authentication-azure-ad-logins)를 참조하십시오.

또한 Azure Portal만 사용하여 관리자를 만들 수 있으며 Azure 역할 기반 액세스 제어 역할은 Azure SQL Database 논리 서버로 전파되지 않습니다. Transact-SQL(T-SQL)을 사용하여 추가 서버 및 데이터베이스 권한을 부여해야 합니다. SQL 서버에 대한 Microsoft Entra 관리자를 만들어 보겠습니다.

1.  제공된 랩 가상 머신 또는 제공되지 않은 경우 로컬 컴퓨터에서 브라우저 세션을 시작하고 [https://portal.azure.com](https://portal.azure.com/)으로 이동합니다. Azure 자격 증명을 사용하여 포털에 연결합니다.

2.  Azure Portal 홈 페이지에서 **SQL 서버**를 검색하고 선택합니다.

3.  SQL 서버 **dp300-lab-xxxxxxxx**를 선택합니다. 여기서 *xxxxxxxx*는 임의의 숫자 문자열입니다.

    > &#128221; 이 실습에서 생성하지 않은 자체 Azure SQL 서버를 사용하는 경우 해당 SQL 서버의 이름을 선택하십시오.

4.  *개요* 블레이드에서 *Microsoft Entra 관리자* 옆의 **구성되지 않음**을 선택합니다.

5.  다음 화면에서 **관리자 설정**을 선택합니다.

6.  **Microsoft Entra ID** 사이드바에서 Azure Portal에 로그인한 Azure 사용자 이름을 검색한 다음 **선택**을 클릭합니다.

7.  **저장**을 선택하여 프로세스를 완료합니다. 이렇게 하면 사용자 이름이 서버의 Microsoft Entra 관리자가 됩니다.

8.  왼쪽에서 **개요**를 선택한 다음 **서버 이름**을 복사합니다.

9.  SQL Server Management Studio(SSMS)를 열고 **연결** > **데이터베이스 엔진**을 선택합니다. **서버 이름**에 서버 이름을 붙여넣습니다. 인증 유형을 **Microsoft Entra - 다단계 인증(Microsoft Entra MFA)**으로 변경합니다.

10. **연결**을 선택합니다.

## 데이터베이스 개체에 대한 액세스 관리

이 작업에서는 데이터베이스 및 해당 개체에 대한 액세스를 관리합니다. 가장 먼저 *AdventureWorksLT* 데이터베이스에 두 명의 사용자를 생성합니다.

1.  제공된 랩 가상 머신 또는 제공되지 않은 경우 로컬 컴퓨터의 SSMS에서 Azure 서버 관리자 계정 또는 Microsoft Entra 관리자 계정을 사용하여 *AdventureWorksLT* 데이터베이스에 로그인합니다.

2.  **개체 탐색기**를 사용하여 **데이터베이스**를 확장합니다.

3.  **AdventureWorksLT**를 마우스 오른쪽 버튼으로 클릭하고 **새 쿼리**를 선택합니다.

4.  새 쿼리 창에 아래 T-SQL을 복사하여 붙여넣습니다. 쿼리를 실행하여 두 사용자를 만듭니다.

    ```sql
    CREATE USER [DP300User1] WITH PASSWORD = 'Azur3Pa$$';
    GO

    CREATE USER [DP300User2] WITH PASSWORD = 'Azur3Pa$$';
    GO
    ```

    **참고:** 이 사용자들은 AdventureWorksLT 데이터베이스 범위 내에서 생성됩니다. 다음으로 사용자 지정 역할을 만들고 사용자를 추가합니다.

5.  동일한 쿼리 창에서 다음 T-SQL을 실행합니다.

    ```sql
    CREATE ROLE [SalesReader];
    GO

    ALTER ROLE [SalesReader] ADD MEMBER [DP300User1];
    GO

    ALTER ROLE [SalesReader] ADD MEMBER [DP300User2];
    GO
    ```

    다음으로 **SalesLT** 스키마에 새 저장 프로시저를 만듭니다.

6.  쿼리 창에서 아래 T-SQL을 실행합니다.

    ```sql
    CREATE OR ALTER PROCEDURE SalesLT.DemoProc
    AS
    SELECT P.Name, Sum(SOD.LineTotal) as TotalSales ,SOH.OrderDate
    FROM SalesLT.Product P
    INNER JOIN SalesLT.SalesOrderDetail SOD on SOD.ProductID = P.ProductID
    INNER JOIN SalesLT.SalesOrderHeader SOH on SOH.SalesOrderID = SOD.SalesOrderID
    GROUP BY P.Name, SOH.OrderDate
    ORDER BY TotalSales DESC
    GO
    ```

    다음으로 `EXECUTE AS USER` 구문을 사용하여 보안을 테스트합니다. 이를 통해 데이터베이스 엔진이 사용자의 컨텍스트에서 쿼리를 실행할 수 있습니다.

7.  다음 T-SQL을 실행합니다.

    ```sql
    EXECUTE AS USER = 'DP300User1'
    EXECUTE SalesLT.DemoProc
    ```

    다음 메시지와 함께 실패합니다:

    <span style="color:red">메시지 229, 수준 14, 상태 5, 프로시저 SalesLT.DemoProc, 줄 1 [Batch 시작 줄 0]
    개체 'DemoProc', 데이터베이스 'AdventureWorksLT', 스키마 'SalesLT'에 대한 EXECUTE 권한이 거부되었습니다.</span>

8.  다음으로 역할에 저장 프로시저를 실행할 수 있는 권한을 부여합니다. 아래 T-SQL을 실행합니다.

    ```sql
    REVERT;
    GRANT EXECUTE ON SCHEMA::SalesLT TO [SalesReader];
    GO
    ```

    첫 번째 명령은 실행 컨텍스트를 데이터베이스 소유자로 되돌립니다.

9.  이전 T-SQL을 다시 실행합니다.

    ```sql
    EXECUTE AS USER = 'DP300User1'
    EXECUTE SalesLT.DemoProc
    ```

---

## 리소스 정리

Azure SQL Server를 다른 용도로 사용하지 않는 경우, 이 실습에서 생성한 리소스를 정리할 수 있습니다.

### 리소스 그룹 삭제

이 실습을 위해 새 리소스 그룹을 생성했다면, 해당 리소스 그룹을 삭제하여 이 실습에서 생성한 모든 리소스를 제거할 수 있습니다.

1.  Azure Portal의 왼쪽 탐색 창에서 **리소스 그룹**을 선택하거나, 상단 검색 창에서 **리소스 그룹**을 검색하여 결과에서 선택합니다.

2.  이 실습을 위해 생성한 리소스 그룹으로 이동합니다. 리소스 그룹에는 이 실습에서 생성한 Azure SQL Server 및 기타 리소스가 포함됩니다.

3.  상단 메뉴에서 **리소스 그룹 삭제**를 선택합니다.

4.  **리소스 그룹 삭제** 대화 상자에서 확인을 위해 리소스 그룹의 이름을 입력하고 **삭제**를 선택합니다.

5.  리소스 그룹이 삭제될 때까지 기다립니다.

6.  Azure Portal을 닫습니다.

### 실습 리소스만 삭제

이 실습을 위해 새 리소스 그룹을 생성하지 않았고 리소스 그룹과 이전 리소스를 그대로 두려면 이 실습에서 생성한 리소스만 삭제할 수 있습니다.

1.  Azure Portal의 왼쪽 탐색 창에서 **리소스 그룹**을 선택하거나, 상단 검색 창에서 **리소스 그룹**을 검색하여 결과에서 선택합니다.

2.  이 실습을 위해 생성한 리소스 그룹으로 이동합니다. 리소스 그룹에는 이 실습에서 생성한 Azure SQL Server 및 기타 리소스가 포함됩니다.

3.  이전에 실습에서 지정한 SQL 서버 이름으로 시작하는 모든 리소스를 선택합니다.

4.  상단 메뉴에서 **삭제**를 선택합니다.

5.  **리소스 삭제** 대화 상자에서 **delete**를 입력하고 **삭제**를 선택합니다.

6.  다시 **삭제**를 선택하여 리소스 삭제를 확인합니다.

7.  리소스가 삭제될 때까지 기다립니다.

8.  Azure Portal을 닫습니다.

### LabFiles 폴더 삭제

이 실습을 위해 새 LabFiles 폴더를 만들었고 더 이상 필요하지 않은 경우, LabFiles 폴더를 삭제하여 이 실습에서 생성한 모든 파일을 제거할 수 있습니다.

1.  제공된 랩 가상 머신 또는 제공되지 않은 경우 로컬 컴퓨터에서 파일 탐색기를 열고 **C:\\** 드라이브로 이동합니다.
2.  **LabFiles** 폴더를 마우스 오른쪽 버튼으로 클릭하고 **삭제**를 선택합니다.
3.  폴더 삭제를 확인하려면 **예**를 선택합니다.

---

이것으로 실습을 성공적으로 완료했습니다.

이 연습에서는 Microsoft Entra ID를 사용하여 Azure 자격 증명에 Azure에서 호스팅되는 SQL Server에 대한 액세스 권한을 부여하는 방법을 살펴보았습니다. 또한 T-SQL 문을 사용하여 새 데이터베이스 사용자를 만들고 저장 프로시저를 실행할 수 있는 권한을 부여했습니다.
