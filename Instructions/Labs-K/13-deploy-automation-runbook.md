## 실습 13 – 인덱스를 자동으로 다시 작성하는 자동화 Runbook 배포

**모듈:** Azure SQL에 대한 데이터베이스 작업 자동화

---

# 인덱스를 자동으로 다시 작성하는 자동화 Runbook 배포

**예상 소요 시간: 30분**

**시나리오:**

여러분은 데이터베이스 관리의 일상적인 운영을 자동화하기 위해 선임 데이터베이스 관리자로 고용되었습니다. 이 자동화는 AdventureWorks용 데이터베이스가 최고 성능으로 계속 작동하도록 보장하고 특정 기준에 따라 경고하는 방법을 제공하기 위한 것입니다. AdventureWorks는 Infrastructure as a Service(IaaS) 및 Platform as a Service(PaaS) 제품 모두에서 SQL Server를 활용합니다.

> &#128221; 이 연습에서는 T-SQL 코드를 복사하여 붙여넣고 기존 SQL 리소스를 사용해야 할 수 있습니다. 코드를 실행하기 전에 코드가 올바르게 복사되었는지 확인하십시오.

---

**1단계: 환경 설정**

랩 가상 머신이 제공되고 미리 구성된 경우 **C:\LabFiles** 폴더에 랩 파일이 준비되어 있을 것입니다. *잠시 확인하여 파일이 이미 있는지 확인하고, 있다면 이 섹션을 건너뜁니다*. 그러나 자신의 컴퓨터를 사용하거나 랩 파일이 없는 경우 계속 진행하려면 *GitHub*에서 복제해야 합니다.

1.  제공된 랩 가상 머신 또는 제공되지 않은 경우 로컬 컴퓨터에서 Visual Studio Code 세션을 시작합니다.

2.  명령 팔레트(Ctrl+Shift+P)를 열고 **Git: Clone**을 입력합니다. **Git: Clone** 옵션을 선택합니다.

3.  **Repository URL** 필드에 다음 URL을 붙여넣고 **Enter** 키를 누릅니다.

    ```url
    https://github.com/MicrosoftLearning/dp-300-database-administrator.git
    ```

4.  랩 가상 머신 또는 제공되지 않은 경우 로컬 컴퓨터의 **C:\LabFiles** 폴더에 리포지토리를 저장합니다(폴더가 없으면 만듭니다).

---

**2단계: Azure에서 SQL Server 설정**

Azure에 로그인하고 Azure에서 실행 중인 기존 Azure SQL Server 인스턴스가 있는지 확인합니다. *Azure에서 이미 실행 중인 SQL Server 인스턴스가 있는 경우 이 섹션을 건너뜁니다*.

1.  제공된 랩 가상 머신 또는 제공되지 않은 경우 로컬 컴퓨터에서 Visual Studio Code 세션을 시작하고 이전 섹션에서 복제한 리포지토리로 이동합니다.

2.  **/Allfiles/Labs** 폴더를 마우스 오른쪽 버튼으로 클릭하고 **Open in Integrated Terminal**을 선택합니다.

3.  Azure CLI를 사용하여 Azure에 연결합니다. 다음 명령을 입력하고 **Enter** 키를 누릅니다.

    ```bash
    az login
    ```

    > &#128221; 브라우저 창이 열립니다. Azure 자격 증명을 사용하여 로그인하십시오.

4.  Azure에 로그인했으면, 리소스 그룹이 아직 없는 경우 리소스 그룹을 만들고 해당 리소스 그룹 아래에 SQL server와 database를 만듭니다. 다음 명령을 입력하고 **Enter** 키를 누릅니다. *스크립트 완료까지 몇 분 정도 걸릴 수 있습니다*.

    ```bash
    cd ./Setup
    ./deploy-sql-database.ps1
    ```

    > &#128221; 기본적으로 이 스크립트는 **contoso-rg**라는 `resource group`을 생성하거나, 이름이 *contoso-rg*로 시작하는 리소스가 있는 경우 해당 리소스를 사용합니다. 또한 기본적으로 모든 리소스를 **West US 2** `region` (westus2)에 생성합니다. 마지막으로 **SQL admin password**에 대해 임의의 12자 암호를 생성합니다. **-rgName**, **-location** 및 **-sqlAdminPw** 매개변수 중 하나 이상을 사용하여 이러한 값을 사용자 지정 값으로 변경할 수 있습니다. 암호는 Azure SQL 암호 복잡성 요구 사항을 충족해야 하며, 길이는 12자 이상이어야 하고 대문자, 소문자, 숫자 및 특수 문자를 각각 하나 이상 포함해야 합니다.

    > &#128221; 스크립트는 현재 Public IP address를 SQL server 방화벽 규칙에 추가합니다.

5.  스크립트가 완료되면 `resource group` 이름, SQL server 이름 및 database 이름, admin user name과 password를 반환합니다. *나중에 실습에서 필요하므로 이 값들을 기록해 두십시오*.

---

**3단계: Automation Account 만들기**

1.  제공된 랩 가상 머신 또는 제공되지 않은 경우 로컬 컴퓨터에서 브라우저 세션을 시작하고 [https://portal.azure.com](https://portal.azure.com/)으로 이동합니다. Azure 자격 증명을 사용하여 `Portal`에 연결합니다.

2.  Azure portal의 검색 창에 *automation*을 입력한 다음 검색 결과에서 **Automation Accounts**를 선택하고 **+ Create**를 선택합니다.

3.  **Create an Automation Account** 페이지에서 아래 정보를 입력한 다음 **Review + Create**를 선택합니다.

    *   **Resource Group:** `<사용자의 resource group>`
    *   **Automation account name:** `autoAccount`
    *   **Region:** 기본값을 사용합니다.

4.  검토 페이지에서 **Create**를 선택합니다.

    > &#128221; `Automation account` 생성에는 몇 분 정도 걸릴 수 있습니다.

---

**4단계: 기존 Azure SQL Database에 연결**

1.  Azure portal에서 **sql databases**를 검색하여 사용자의 데이터베이스로 이동합니다.

2.  SQL database **AdventureWorksLT**를 선택합니다.

3.  SQL Database 페이지의 기본 섹션에서 **Query editor (preview)**를 선택합니다.

4.  데이터베이스 관리자 계정을 사용하여 데이터베이스에 로그인하라는 자격 증명 메시지가 표시됩니다. 자격 증명을 입력하고 **OK**를 선택합니다.

    > &#128221; 오류 메시지 *Cannot open server 'your-sql-server-name' requested by the login. Client with IP address 'xxx.xxx.xxx.xxx' is not allowed to access the server.*가 표시될 수 있습니다. 그렇다면 현재 Public IP address를 SQL server 방화벽 규칙에 추가해야 합니다.

    방화벽 규칙을 설정해야 하는 경우 다음 단계를 따르십시오.

    1.  데이터베이스의 **Overview** 페이지 상단 메뉴 표시줄에서 **Set server firewall**을 선택합니다.
    2.  **Add your current IPv4 address (xxx.xxx.xxx.xxx)**를 선택한 다음 **Save**를 선택합니다.
    3.  저장되면 **AdventureWorksLT** 데이터베이스 페이지로 돌아가서 **Query editor (preview)**를 다시 선택합니다.
    4.  데이터베이스 관리자 계정을 사용하여 데이터베이스에 로그인하라는 자격 증명 메시지가 표시됩니다. 자격 증명을 입력하고 **OK**를 선택합니다.

5.  **Query editor (preview)**에서 **Open query**를 선택합니다.

6.  찾아보기 *폴더* 아이콘을 선택하고 **C:\LabFiles\dp-300-database-administrator\Allfiles\Labs\13** 폴더로 이동합니다. **usp_AdaptiveIndexDefrag.sql** 파일을 선택하고 **Open**을 선택한 다음 **OK**를 선택합니다.

7.  쿼리의 5행과 6행에 있는 **USE msdb** 및 **GO**를 삭제한 다음 **Run**을 선택합니다.

8.  **Stored Procedures** 폴더를 확장하여 새로 생성된 저장 프로시저를 확인합니다.

---

**5단계: Automation Account 자산 구성**

다음 단계는 runbook 생성을 준비하는 데 필요한 자산을 구성하는 것입니다.

1.  Azure portal의 상단 검색 상자에 **automation**을 입력하고 **Automation Accounts**를 선택합니다.

2.  생성한 **autoAccount** automation account를 선택합니다.

3.  Automation 블레이드의 **Shared Resources** 섹션에서 **Modules**를 선택합니다. 그런 다음 **Browse gallery**를 선택합니다.

4.  Gallery 내에서 **SqlServer**를 검색합니다.

5.  **SqlServer**를 선택하면 다음 화면으로 이동합니다. 그런 다음 **Select** 버튼을 선택합니다.

6.  **Add a module** 페이지에서 사용 가능한 최신 런타임 버전을 선택한 다음 **Import**를 선택합니다. 이렇게 하면 PowerShell 모듈이 Automation account로 가져옵니다.

7.  데이터베이스에 안전하게 로그인하기 위한 자격 증명을 만들어야 합니다. *Automation Account* 블레이드의 **Shared Resources** 섹션으로 이동하여 **Credentials**를 선택합니다.

8.  **+ Add a Credential**을 선택하고 아래 정보를 입력한 다음 **Create**를 선택합니다.

    *   **Name:** `SQLUser`
    *   **User name:** `sqladmin` (이전에 설정한 SQL 관리자 로그인 이름)
    *   **Password:** `<이전에 설정한 SQL 관리자 암호 입력>`
    *   **Confirm password:** `<암호 다시 입력>`

---

**6단계: PowerShell runbook 만들기**

1.  Azure portal에서 **sql databases**를 검색하여 사용자의 데이터베이스로 이동합니다.

2.  SQL database **AdventureWorksLT**를 선택합니다.

3.  **Overview** 페이지에서 Azure SQL Database의 **Server name**을 복사합니다 (서버 이름은 *dp300-lab*으로 시작해야 함). 나중에 붙여넣을 것입니다.

4.  Azure portal의 상단 검색 상자에 **automation**을 입력하고 **Automation Accounts**를 선택합니다.

5.  **autoAccount** automation account를 선택합니다.

6.  Automation account 블레이드의 **Process Automation** 섹션을 확장하고 **Runbooks**를 선택합니다.

7.  **+ Create a runbook**을 선택합니다.

    > &#128221; 배운 대로, 기존에 두 개의 runbook이 생성되어 있음을 참고하십시오. 이들은 automation account 배포 중에 자동으로 생성되었습니다.

8.  `Runbook name`으로 **IndexMaintenance**를 입력하고 `runbook type`으로 **PowerShell**을 선택합니다. 사용 가능한 최신 런타임 버전을 선택한 다음 **Review + Create**를 선택합니다.

9.  **Create runbook** 페이지에서 **Create**를 선택합니다.

10. Runbook이 생성되면 아래의 Powershell 코드 스니펫을 runbook 편집기에 복사하여 붙여넣습니다.

    > &#128221; Runbook을 저장하기 전에 코드가 올바르게 복사되었는지 확인하십시오.

    ```powershell
    # 여기에 이전 단계에서 복사한 Azure SQL Database 서버 이름을 붙여넣으세요.
    $AzureSQLServerName = '여기에-서버이름-붙여넣기.database.windows.net'
    $DatabaseName = 'AdventureWorksLT'

    # Automation Account에 저장된 'SQLUser' 자격 증명 가져오기
    $Cred = Get-AutomationPSCredential -Name "SQLUser"
    # Invoke-Sqlcmd를 사용하여 저장 프로시저 실행 및 출력/오류 캡처
    $SQLOutput = $(Invoke-Sqlcmd -ServerInstance $AzureSQLServerName -UserName $Cred.UserName -Password $Cred.GetNetworkCredential().Password -Database $DatabaseName -Query "EXEC dbo.usp_AdaptiveIndexDefrag" -Verbose) 4>&1

    # 결과를 Runbook 출력으로 작성
    Write-Output $SQLOutput
    ```

    > &#128221; 위 코드는 **AdventureWorksLT** 데이터베이스에서 저장 프로시저 **usp_AdaptiveIndexDefrag**를 실행하는 PowerShell 스크립트입니다. 이 스크립트는 **Invoke-Sqlcmd** cmdlet을 사용하여 SQL server에 연결하고 저장 프로시저를 실행합니다. **Get-AutomationPSCredential** cmdlet은 Automation account에 저장된 자격 증명을 검색하는 데 사용됩니다.

11. 스크립트의 첫 번째 줄(`$AzureSQLServerName = ''`)에 이전 단계에서 복사한 서버 이름을 붙여넣습니다. (작은따옴표 안에)

12. **Save**를 선택한 다음 **Publish**를 선택합니다.

13. 게시 작업을 확인하려면 **Yes**를 선택합니다.

14. 이제 *IndexMaintenance* runbook이 게시되었습니다.

---

**7단계: Runbook에 대한 Schedule 만들기**

다음으로 runbook을 정기적으로 실행하도록 예약합니다.

1.  **IndexMaintenance** runbook의 왼쪽 탐색 메뉴에서 **Resources** 아래의 **Schedules**를 선택합니다.

2.  **+ Add a schedule**을 선택합니다.

3.  **Link a schedule to your runbook**을 선택합니다.

4.  **+ Add a schedule**을 선택합니다.

5.  아래 정보를 입력한 다음 **Create**를 선택합니다.

    *   **Name:** `DailyIndexDefrag`
    *   **Description:** AdventureWorksLT 데이터베이스에 대한 일일 인덱스 조각 모음.
    *   **Starts:** (다음 날) 오전 4:00
    *   **Time zone:** `<사용자 위치와 일치하는 시간대 선택>`
    *   **Recurrence:** Recurring
    *   **Recur every:** 1 day
    *   **Set expiration:** No

    > &#128221; 시작 시간은 다음 날 오전 4:00으로 설정됩니다. 시간대는 로컬 시간대로 설정됩니다. 반복은 1일마다로 설정됩니다. 만료되지 않습니다.

6.  **Create**를 선택한 다음 **OK**를 선택합니다.

7.  이제 스케줄이 생성되어 runbook에 연결되었습니다. **OK**를 선택합니다.

Azure Automation은 Azure 및 비 Azure 환경 전반에 걸쳐 일관된 관리를 지원하는 클라우드 기반 자동화 및 구성 서비스를 제공합니다.

---

**8단계: 리소스 정리**

Azure SQL Server를 다른 용도로 사용하지 않는 경우, 이 실습에서 생성한 리소스를 정리할 수 있습니다.

**Resource Group 삭제**

이 실습을 위해 새 `resource group`을 생성했다면, 해당 `resource group`을 삭제하여 이 실습에서 생성한 모든 리소스를 제거할 수 있습니다.

1.  Azure portal의 왼쪽 탐색 창에서 **Resource groups**를 선택하거나, 상단 검색 창에서 **Resource groups**를 검색하여 결과에서 선택합니다.

2.  이 실습을 위해 생성한 `resource group`으로 이동합니다. `Resource group`에는 이 실습에서 생성한 Azure SQL Server 및 기타 리소스가 포함됩니다.

3.  상단 메뉴에서 **Delete resource group**을 선택합니다.

4.  **Delete resource group** 대화 상자에서 확인을 위해 `resource group`의 이름을 입력하고 **Delete**를 선택합니다.

5.  `Resource group`이 삭제될 때까지 기다립니다.

6.  Azure portal을 닫습니다.

**실습 리소스만 삭제**

이 실습을 위해 새 `resource group`을 생성하지 않았고 `resource group`과 이전 리소스를 그대로 두려면 이 실습에서 생성한 리소스만 삭제할 수 있습니다.

1.  Azure portal의 왼쪽 탐색 창에서 **Resource groups**를 선택하거나, 상단 검색 창에서 **Resource groups**를 검색하여 결과에서 선택합니다.

2.  이 실습을 위해 생성한 `resource group`으로 이동합니다. `Resource group`에는 이 실습에서 생성한 Azure SQL Server 및 기타 리소스가 포함됩니다.

3.  이전에 실습에서 지정한 SQL Server 이름으로 시작하는 모든 리소스(SQL Server, SQL Database, Automation Account 등)를 선택합니다.

4.  상단 메뉴에서 **Delete**를 선택합니다.

5.  **Delete resources** 대화 상자에서 **delete**를 입력하고 **Delete**를 선택합니다.

6.  다시 **Delete**를 선택하여 리소스 삭제를 확인합니다.

7.  리소스가 삭제될 때까지 기다립니다.

8.  Azure portal을 닫습니다.

**LabFiles 폴더 삭제**

이 실습을 위해 새 LabFiles 폴더를 만들었고 더 이상 필요하지 않은 경우, LabFiles 폴더를 삭제하여 이 실습에서 생성한 모든 파일을 제거할 수 있습니다.

1.  제공된 랩 가상 머신 또는 제공되지 않은 경우 로컬 컴퓨터에서 **File Explorer**를 엽니다.
2.  **C:\\** 드라이브로 이동합니다.
3.  **LabFiles** 폴더를 마우스 오른쪽 버튼으로 클릭하고 **Delete**를 선택합니다.
4.  폴더 삭제를 확인하려면 **Yes**를 선택합니다.

---

이것으로 실습을 성공적으로 완료했습니다.

이 연습을 완료함으로써 SQL server 데이터베이스의 인덱스 조각 모음을 매일 오전 4시에 실행하도록 자동화했습니다.
