## 실습 4 – Azure SQL Database 방화벽 규칙 구성

**모듈:** 데이터베이스 서비스에 대한 보안 환경 구현

**섹션:** 보안 환경 구현

**예상 소요 시간: 30분**

**시나리오:**

수강생은 학습한 내용을 바탕으로 Azure Portal 및 *AdventureWorksLT* 데이터베이스 내에서 보안을 구성하고 구현합니다.

여러분은 선임 데이터베이스 관리자로 고용되어 데이터베이스 환경의 보안을 보장하는 임무를 맡았습니다. 이 작업은 Azure SQL Database에 중점을 둡니다.

📝 이 연습에서는 T-SQL 코드를 복사하여 붙여넣고 기존 SQL 리소스를 사용합니다. 코드를 실행하기 전에 코드가 올바르게 복사되었는지 확인하십시오.

---

**1단계: 환경 설정**

랩 가상 머신이 제공되고 미리 구성된 경우 **C:\LabFiles** 폴더에 랩 파일이 준비되어 있을 것입니다. 잠시 확인하여 파일이 이미 있는지 확인하고, 있다면 이 섹션을 건너뜁니다. 그러나 자신의 컴퓨터를 사용하거나 랩 파일이 없는 경우 계속 진행하려면 GitHub에서 복제해야 합니다.

1.  제공된 랩 가상 머신 또는 제공되지 않은 경우 로컬 컴퓨터에서 Visual Studio Code 세션을 시작합니다.

2.  명령 팔레트(Ctrl+Shift+P)를 열고 **Git: Clone**을 입력합니다. **Git: Clone** 옵션을 선택합니다.

3.  **리포지토리 URL** 필드에 다음 URL을 붙여넣고 Enter 키를 누릅니다.

    ```
    https://github.com/MicrosoftLearning/dp-300-database-administrator.git
    ```

4.  랩 가상 머신 또는 제공되지 않은 경우 로컬 컴퓨터의 **C:\LabFiles** 폴더에 리포지토리를 저장합니다(폴더가 없으면 만듭니다).

---

**2단계: Azure에서 SQL Server 설정**

Azure에 로그인하고 Azure에서 실행 중인 기존 Azure SQL Server 인스턴스가 있는지 확인합니다. Azure에서 이미 실행 중인 SQL Server 인스턴스가 있는 경우 이 섹션을 건너뜁니다.

1.  제공된 랩 가상 머신 또는 제공되지 않은 경우 로컬 컴퓨터에서 Visual Studio Code 세션을 시작하고 이전 섹션에서 복제한 리포지토리로 이동합니다.

2.  **/Allfiles/Labs** 폴더를 마우스 오른쪽 버튼으로 클릭하고 **통합 터미널에서 열기**를 선택합니다.

3.  Azure CLI를 사용하여 Azure에 연결합니다. 다음 명령을 입력하고 Enter 키를 누릅니다.

    ```bash
    az login
    ```

    📝 브라우저 창이 열립니다. Azure 자격 증명을 사용하여 로그인하십시오.

4.  Azure에 로그인했으면, 리소스 그룹이 아직 없는 경우 리소스 그룹을 만들고 해당 리소스 그룹 아래에 SQL 서버와 데이터베이스를 만듭니다. 다음 명령을 입력하고 Enter 키를 누릅니다. 스크립트 완료까지 몇 분 정도 걸릴 수 있습니다.

    ```bash
    cd ./Setup
    ./deploy-sql-database.ps1
    ```

    📝 기본적으로 이 스크립트는 **contoso-rg**라는 리소스 그룹을 생성하거나, 이름이 *contoso-rg*로 시작하는 리소스가 있는 경우 해당 리소스를 사용합니다. 또한 기본적으로 모든 리소스를 **미국 서부 2(westus2)** 지역에 생성합니다. 마지막으로 **SQL 관리자 암호**에 대해 임의의 12자 암호를 생성합니다. **-rgName**, **-location** 및 **-sqlAdminPw** 매개변수 중 하나 이상을 사용하여 이러한 값을 사용자 지정 값으로 변경할 수 있습니다. 암호는 Azure SQL 암호 복잡성 요구 사항을 충족해야 하며, 길이는 12자 이상이어야 하고 대문자, 소문자, 숫자 및 특수 문자를 각각 하나 이상 포함해야 합니다.

    📝 스크립트는 현재 공용 IP 주소를 SQL 서버 방화벽 규칙에 추가합니다.

5.  스크립트가 완료되면 리소스 그룹 이름, SQL 서버 이름 및 데이터베이스 이름, 관리자 사용자 이름과 암호를 반환합니다. 나중에 실습에서 필요하므로 이 값들을 기록해 두십시오.

---

**3단계: Azure SQL Database 방화벽 규칙 구성**

1.  제공된 랩 가상 머신 또는 제공되지 않은 경우 로컬 컴퓨터에서 브라우저 세션을 시작하고 https://portal.azure.com으로 이동합니다. Azure 자격 증명을 사용하여 포털에 연결합니다.

2.  Azure Portal 상단의 검색 상자에서 **SQL 서버**를 검색한 다음, 옵션 목록에서 **SQL 서버**를 선택합니다.

3.  SQL 서버 **dp300-lab-xxxxxxxx**를 선택합니다. 여기서 `xxxxxxxx`는 임의의 숫자 문자열입니다.

    📝 이 실습에서 생성하지 않은 자체 Azure SQL 서버를 사용하는 경우 해당 SQL 서버의 이름을 선택하십시오.

4.  SQL 서버의 **개요** 화면에서 서버 이름 오른쪽에 있는 **클립보드에 복사** 버튼을 선택합니다.

5.  **네트워킹 설정 표시**를 선택합니다. (또는 왼쪽 메뉴에서 **보안** > **네트워킹**을 선택)

6.  **네트워킹** 페이지의 **방화벽 규칙** 아래에서 목록을 검토하고 클라이언트 IP 주소가 나열되어 있는지 확인합니다. 목록에 없으면 **+ 클라이언트 IPv4 주소 추가 (사용자 IP 주소)**를 선택한 다음 **저장**을 선택합니다.

    📝 클라이언트 IP 주소가 자동으로 입력되었습니다. 클라이언트 IP 주소를 목록에 추가하면 SQL Server Management Studio(SSMS) 또는 다른 클라이언트 도구를 사용하여 Azure SQL Database에 연결할 수 있습니다. 클라이언트 IP 주소를 기록해 두십시오. 나중에 사용합니다.

7.  **SQL Server Management Studio(SSMS)**를 엽니다. **서버에 연결** 대화 상자에서 Azure SQL Database 서버 이름을 붙여넣고 다음 자격 증명으로 로그인합니다.

    *   **서버 이름:** `<Azure SQL Database 서버 이름 붙여넣기>`
    *   **인증:** SQL Server 인증
    *   **서버 관리자 로그인:** Azure SQL Database 서버 관리자 로그인
    *   **암호:** Azure SQL Database 서버 관리자 암호
    *   **연결**을 선택합니다.

8.  **개체 탐색기**에서 서버 노드를 확장하고 **데이터베이스**를 마우스 오른쪽 버튼으로 클릭합니다. **데이터 계층 응용 프로그램 가져오기**를 선택합니다.

9.  **데이터 계층 응용 프로그램 가져오기** 대화 상자의 첫 화면에서 **다음**을 클릭합니다.

10. **가져오기 설정** 화면에서 **찾아보기**를 클릭하고 `C:\LabFiles\dp-300-database-administrator\Allfiles\Labs\04` 폴더로 이동하여 `AdventureWorksLT.bacpac` 파일을 클릭한 다음 **열기**를 클릭합니다. **데이터 계층 응용 프로그램 가져오기** 화면으로 돌아와서 **다음**을 선택합니다.

11. **데이터베이스 설정** 화면에서 다음과 같이 변경합니다.

    *   **데이터베이스 이름:** `AdventureWorksFromBacpac`
    *   **Microsoft Azure SQL Database 버전:** 기본(Basic)
    *   **다음**을 선택합니다.

12. **요약** 화면에서 **마침**을 선택합니다. 이 작업은 몇 분 정도 걸릴 수 있습니다. 가져오기가 완료되면 아래와 같은 결과가 표시됩니다. 그런 다음 **닫기**를 선택합니다.

13. SQL Server Management Studio로 돌아가서 **개체 탐색기**에서 **데이터베이스** 폴더를 확장합니다. 그런 다음 **AdventureWorksFromBacpac** 데이터베이스를 마우스 오른쪽 버튼으로 클릭하고 **새 쿼리**를 선택합니다.

14. 다음 T-SQL 쿼리를 쿼리 창에 붙여넣어 실행합니다.

    **중요:** `000.000.000.000`을 사용자 클라이언트 IP 주소로 바꾸십시오. **실행**을 선택합니다.

    ```sql
    -- 데이터베이스 수준 방화벽 규칙 만들기 (master 데이터베이스에서 실행해야 함)
    -- 참고: 이 실습에서는 서버 수준 방화벽 규칙을 사용했으므로,
    -- 이 데이터베이스 수준 규칙은 추가적인 예시 또는 다른 시나리오를 위한 것입니다.
    -- 현재 연결(AdventureWorksFromBacpac)에서 실행하면 오류 발생 가능성이 있습니다.
    -- 실행하려면 master 데이터베이스 컨텍스트에서 실행해야 합니다.
    -- USE master;
    -- GO
    -- EXECUTE sp_set_database_firewall_rule
    --         @name = N'AWFirewallRuleDB', -- 규칙 이름 변경 권장
    --         @start_ip_address = '000.000.000.000', -- 클라이언트 IP
    --         @end_ip_address = '000.000.000.000'; -- 클라이언트 IP
    -- GO
    -- -- 다시 AdventureWorksFromBacpac 컨텍스트로 돌아가려면:
    -- -- USE AdventureWorksFromBacpac;
    -- -- GO

    -- 실습 지침 상의 의도는 AdventureWorksFromBacpac 컨텍스트에서
    -- 아래 사용자 생성을 진행하는 것일 수 있습니다.
    -- 데이터베이스 수준 방화벽 규칙 생성은 참고용으로 주석 처리합니다.
    ```

    > **강사 참고:** 원본 실습 지침의 `sp_set_database_firewall_rule` 실행 부분은 사용자가 `AdventureWorksFromBacpac`에 연결된 상태에서 실행하도록 되어 있어 오류가 발생합니다. 이 저장 프로시저는 `master` 데이터베이스 컨텍스트에서 실행해야 합니다. 여기서는 해당 부분을 주석 처리하고, 다음 단계인 포함된 사용자 생성으로 바로 넘어가는 것이 실습 흐름상 더 적절합니다. 또는 수강생에게 `master` 데이터베이스로 컨텍스트를 변경 후 실행하도록 안내할 수 있습니다.

15. 다음으로 `AdventureWorksFromBacpac` 데이터베이스에 포함된 사용자를 만듭니다. (만약 위에서 데이터베이스 수준 방화벽 규칙을 위해 `master`로 변경했다면 다시 `AdventureWorksFromBacpac` 컨텍스트로 돌아와야 합니다.) 현재 쿼리 창이 `AdventureWorksFromBacpac` 컨텍스트인지 확인하고 다음 T-SQL을 실행합니다. (또는 새 쿼리 창을 열고 실행)

    ```sql
    USE [AdventureWorksFromBacpac]; -- 컨텍스트 확인/설정
    GO
    CREATE USER ContainedDemo WITH PASSWORD = 'P@ssw0rd01';
    GO
    ```

    📝 이 명령은 `AdventureWorksFromBacpac` 데이터베이스 내에 포함된 사용자를 만듭니다. 다음 단계에서 이 자격 증명을 테스트합니다.

16. **개체 탐색기**로 이동합니다. **연결**을 클릭한 다음 **데이터베이스 엔진**을 클릭합니다.

17. 이전 단계에서 만든 자격 증명으로 연결을 시도합니다. 다음 정보가 필요합니다.

    *   **로그인:** `ContainedDemo`
    *   **암호:** `P@ssw0rd01`
    *   **연결**을 클릭합니다.

18. 다음과 같은 오류가 발생합니다.

    `사용자 'ContainedDemo' 로그인 실패. (Microsoft SQL Server, 오류: 18456)`

    📝 이 오류는 연결이 사용자가 생성된 `AdventureWorksFromBacpac`이 아닌 `master` 데이터베이스에 로그인을 시도했기 때문에 발생합니다. 오류 메시지를 종료하려면 **확인**을 선택한 다음, **서버에 연결** 대화 상자에서 **옵션 >>**을 선택하여 연결 컨텍스트를 변경합니다.

19. **연결 속성** 탭에서 데이터베이스 이름 **AdventureWorksFromBacpac**을 입력한 다음 **연결**을 선택합니다.

20. `ContainedDemo` 사용자를 사용하여 성공적으로 인증할 수 있었음을 확인합니다. 이번에는 새로 만든 사용자가 액세스할 수 있는 유일한 데이터베이스인 `AdventureWorksFromBacpac`에 직접 로그인했습니다.

---

**4단계: 리소스 정리**

Azure SQL Server를 다른 용도로 사용하지 않는 경우, 이 실습에서 생성한 리소스를 정리할 수 있습니다.

**옵션 1: 리소스 그룹 삭제**

이 실습을 위해 새 리소스 그룹을 생성했다면, 해당 리소스 그룹을 삭제하여 이 실습에서 생성한 모든 리소스를 제거할 수 있습니다.

1.  Azure Portal의 왼쪽 탐색 창에서 **리소스 그룹**을 선택하거나, 상단 검색 창에서 **리소스 그룹**을 검색하여 결과에서 선택합니다.
2.  이 실습을 위해 생성한 리소스 그룹으로 이동합니다. 리소스 그룹에는 이 실습에서 생성한 Azure SQL Server 및 기타 리소스가 포함됩니다.
3.  상단 메뉴에서 **리소스 그룹 삭제**를 선택합니다.
4.  **리소스 그룹 삭제** 대화 상자에서 확인을 위해 리소스 그룹의 이름을 입력하고 **삭제**를 선택합니다.
5.  리소스 그룹이 삭제될 때까지 기다립니다.
6.  Azure Portal을 닫습니다.

**옵션 2: 실습 리소스만 삭제**

이 실습을 위해 새 리소스 그룹을 생성하지 않았고 리소스 그룹과 이전 리소스를 그대로 두려면 이 실습에서 생성한 리소스만 삭제할 수 있습니다.

1.  Azure Portal의 왼쪽 탐색 창에서 **리소스 그룹**을 선택하거나, 상단 검색 창에서 **리소스 그룹**을 검색하여 결과에서 선택합니다.
2.  이 실습을 위해 생성한 리소스 그룹으로 이동합니다. 리소스 그룹에는 이 실습에서 생성한 Azure SQL Server 및 기타 리소스가 포함됩니다.
3.  이전에 실습에서 지정한 SQL 서버 이름으로 시작하는 모든 리소스(SQL Server, SQL Database 등)를 선택합니다.
4.  상단 메뉴에서 **삭제**를 선택합니다.
5.  **리소스 삭제** 대화 상자에서 **delete**를 입력하고 **삭제**를 선택합니다.
6.  다시 **삭제**를 선택하여 리소스 삭제를 확인합니다.
7.  리소스가 삭제될 때까지 기다립니다.
8.  Azure Portal을 닫습니다.

**옵션 3: LabFiles 폴더 삭제**

이 실습을 위해 새 LabFiles 폴더를 만들었고 더 이상 필요하지 않은 경우, LabFiles 폴더를 삭제하여 이 실습에서 생성한 모든 파일을 제거할 수 있습니다.

1.  제공된 랩 가상 머신 또는 제공되지 않은 경우 로컬 컴퓨터에서 파일 탐색기를 열고 **C:\\** 드라이브로 이동합니다.
2.  **LabFiles** 폴더를 마우스 오른쪽 버튼으로 클릭하고 **삭제**를 선택합니다.
3.  폴더 삭제를 확인하려면 **예**를 선택합니다.

---

이것으로 실습을 성공적으로 완료했습니다.

이 연습에서는 서버 및 데이터베이스 방화벽 규칙을 구성하여 Azure SQL Database에서 호스팅되는 데이터베이스에 액세스했습니다. 또한 T-SQL 문을 사용하여 포함된 사용자를 만들고 SQL Server Management Studio를 사용하여 액세스를 확인했습니다.
