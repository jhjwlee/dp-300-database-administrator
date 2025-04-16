## 실습 10 – SQL Database에서 성능이 저하된 쿼리의 문제 영역 격리

**모듈:** Azure SQL에서 쿼리 성능 최적화

---

# SQL Database에서 성능이 저하된 쿼리의 문제 영역 격리

**예상 소요 시간: 30분**

**시나리오:**

여러분은 *AdventureWorks2017* 데이터베이스를 쿼리할 때 현재 발생하고 있는 성능 문제를 해결하기 위해 선임 데이터베이스 관리자로 고용되었습니다. 여러분의 임무는 쿼리 성능 문제를 식별하고 이 모듈에서 배운 기술을 사용하여 해결하는 것입니다.

성능이 최적이 아닌 쿼리를 실행하고, 쿼리 계획을 검토하며, 데이터베이스 내에서 개선을 시도할 것입니다.

> &#128221; 이 연습에서는 T-SQL 코드를 복사하여 붙여넣습니다. 코드를 실행하기 전에 코드가 올바르게 복사되었는지 확인하십시오.

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

**2단계: 데이터베이스 복원**

**AdventureWorks2017** 데이터베이스가 이미 복원되어 있다면 이 섹션을 건너뛸 수 있습니다.

1.  제공된 랩 가상 머신 또는 제공되지 않은 경우 로컬 컴퓨터에서 SQL Server Management Studio (SSMS) 세션을 시작합니다.

2.  SSMS가 열리면 기본적으로 **Connect to Server** 대화 상자가 나타납니다. 기본 인스턴스를 선택하고 **Connect**를 선택합니다. **Trust server certificate** 확인란을 선택해야 할 수 있습니다.

    > &#128221; 자체 SQL Server 인스턴스를 사용하는 경우 적절한 서버 인스턴스 이름과 자격 증명을 사용하여 연결해야 합니다.

3.  **Databases** 폴더를 선택한 다음 **New Query**를 선택합니다.

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

5.  **Messages** 탭 아래에 데이터베이스가 성공적으로 복원되었음을 나타내는 메시지가 표시되어야 합니다.

---

**3단계: 실제 실행 계획 생성 (Actual Execution Plan)**

SQL Server Management Studio에서 실행 계획을 생성하는 방법에는 여러 가지가 있습니다.

1.  **New Query**를 선택합니다. 다음 T-SQL 코드를 쿼리 창에 복사하여 붙여넣습니다. **Execute**를 선택하여 이 쿼리를 실행합니다.

    **참고:** **SET SHOWPLAN_ALL ON**을 사용하면 별도의 탭에 그래픽 대신 결과 창에 쿼리의 텍스트 버전 실행 계획을 볼 수 있습니다.

    ```sql
    USE AdventureWorks2017;
    GO

    SET SHOWPLAN_ALL ON;
    GO

    SELECT BusinessEntityID
    FROM HumanResources.Employee
    WHERE NationalIDNumber = '14417807';
    GO

    SET SHOWPLAN_ALL OFF;
    GO
    ```

    결과 창에서 **SELECT** 문의 실제 쿼리 결과 대신 실행 계획의 텍스트 버전을 볼 수 있습니다.

2.  **StmtText** 열의 두 번째 행에 있는 텍스트를 잠시 살펴보십시오.

    ```console
    |--Index Seek(OBJECT:([AdventureWorks2017].[HumanResources].[Employee].[AK_Employee_NationalIDNumber]), SEEK:([AdventureWorks2017].[HumanResources].[Employee].[NationalIDNumber]=CONVERT_IMPLICIT(nvarchar(4000),[@1],0)) ORDERED FORWARD)
    ```

    위 텍스트는 실행 계획이 **AK_Employee_NationalIDNumber** 키에 대해 **Index Seek**를 사용함을 설명합니다. 또한 실행 계획이 **CONVERT_IMPLICIT** 단계를 수행해야 했음을 보여줍니다.

    쿼리 최적화 프로그램은 필요한 레코드를 가져오기 위해 적절한 인덱스를 찾을 수 있었습니다.

---

**4단계: 최적이 아닌 쿼리 계획 해결 (Resolve a suboptimal query plan)**

1.  아래 코드를 새 쿼리 창에 복사하여 붙여넣습니다.

    Execute 버튼 오른쪽에 있는 **Include Actual Execution Plan** 아이콘을 선택하거나 <kbd>CTRL</kbd>+<kbd>M</kbd>을 누릅니다. **Execute**를 선택하거나 <kbd>F5</kbd> 키를 눌러 쿼리를 실행합니다. 실행 계획과 메시지 탭의 `logical reads`를 기록해 두십시오.

    ```sql
    SET STATISTICS IO, TIME ON;

    SELECT [SalesOrderID] ,[CarrierTrackingNumber] ,[OrderQty] ,[ProductID], [UnitPrice] ,[ModifiedDate]
    FROM [AdventureWorks2017].[Sales].[SalesOrderDetail]
    WHERE [ModifiedDate] > '2012/01/01' AND [ProductID] = 772;
    ```

    실행 계획을 검토하면 **Key Lookup**이 있음을 알 수 있습니다. 아이콘 위에 마우스를 올리면 해당 속성이 쿼리에서 검색된 각 행에 대해 수행됨을 나타냅니다. 실행 계획이 **Key Lookup** 작업을 수행하는 것을 볼 수 있습니다.

    **Output List** 섹션의 열을 기록해 두십시오. 이 쿼리를 어떻게 개선하시겠습니까?

    `key lookup`을 제거하기 위해 변경해야 할 인덱스를 식별하려면 그 위에 있는 `index seek`를 검토해야 합니다. `index seek` 연산자 위에 마우스를 올리면 연산자의 속성이 나타납니다.

2.  **Key Lookups**는 쿼리에서 반환되거나 검색되는 모든 필드를 포함하는 커버링 인덱스(covering index)를 추가하여 제거할 수 있습니다. 이 예에서는 인덱스가 **ProductID** 열만 사용합니다. 다음은 인덱스의 현재 정의이며, **ProductID** 열이 유일한 키 열이므로 쿼리에 필요한 다른 열을 검색하기 위해 **Key Lookup**이 강제됩니다.

    ```sql
    CREATE NONCLUSTERED INDEX [IX_SalesOrderDetail_ProductID] ON [Sales].[SalesOrderDetail]
    ([ProductID] ASC)
    ```

    **Output List** 필드를 인덱스에 포함된 열(included columns)로 추가하면 **Key Lookup**이 제거됩니다. 인덱스가 이미 존재하므로 인덱스를 DROP하고 다시 생성하거나 **DROP_EXISTING=ON**을 설정하여 열을 추가해야 합니다. **ProductID** 열은 이미 인덱스의 일부이므로 포함된 열로 추가할 필요가 없습니다. **ModifiedDate**를 추가하여 인덱스에 대한 또 다른 성능 개선을 할 수 있습니다. **New Query** 창을 열고 다음 스크립트를 실행하여 인덱스를 삭제하고 다시 생성합니다.

    ```sql
    CREATE NONCLUSTERED INDEX [IX_SalesOrderDetail_ProductID]
    ON [Sales].[SalesOrderDetail] ([ProductID],[ModifiedDate]) -- ModifiedDate를 키 열에 추가
    INCLUDE ([CarrierTrackingNumber],[OrderQty],[UnitPrice]) -- 나머지 필요한 열을 INCLUDE 절에 추가
    WITH (DROP_EXISTING = on);
    GO
    ```

3.  1단계의 쿼리를 다시 실행합니다. `logical reads` 및 실행 계획 변경 사항을 기록해 두십시오. 이제 계획은 우리가 만든 비클러스터형 인덱스만 사용하면 됩니다.

> &#128221; 실행 계획을 검토하면 **key lookup**이 사라지고 비클러스터형 인덱스만 사용하고 있음을 알 수 있습니다.

---

**5단계: Query Store를 사용하여 회귀(Regression) 감지 및 처리**

다음으로, 워크로드를 실행하여 `Query Store`에 대한 쿼리 통계를 생성하고, **Top Resource Consuming Queries** 보고서를 검토하여 성능 저하를 식별하고, 더 나은 실행 계획을 강제 적용하는 방법을 확인합니다.

1.  **New Query**를 선택합니다. 다음 T-SQL 코드를 쿼리 창에 복사하여 붙여넣습니다. **Execute**를 선택하여 이 쿼리를 실행합니다.

    이 스크립트는 AdventureWorks2017 데이터베이스에 대해 `Query Store` 기능을 활성화하고 데이터베이스를 `Compatibility Level` 100으로 설정합니다.

    ```sql
    USE [master];
    GO

    ALTER DATABASE [AdventureWorks2017] SET QUERY_STORE = ON;
    GO

    ALTER DATABASE [AdventureWorks2017] SET QUERY_STORE (OPERATION_MODE = READ_WRITE);
    GO

    ALTER DATABASE [AdventureWorks2017] SET COMPATIBILITY_LEVEL = 100; -- SQL Server 2008 호환성 수준
    GO
    ```

    `Compatibility Level`을 변경하는 것은 데이터베이스를 과거 시점으로 되돌리는 것과 같습니다. 이는 SQL Server가 사용할 수 있는 기능을 SQL Server 2008에서 사용할 수 있었던 기능으로 제한합니다.

2.  SQL Server Management Studio에서 **File** > **Open** > **File** 메뉴를 선택합니다.

3.  **C:\LabFiles\dp-300-database-administrator\Allfiles\Labs\10\CreateRandomWorkloadGenerator.sql** 파일로 이동합니다.

4.  SQL Server Management Studio에서 열리면 **Execute**를 선택하여 쿼리를 실행합니다. (이 스크립트는 워크로드 생성을 위한 저장 프로시저를 만듭니다.)

5.  새 쿼리 편집기에서 **C:\LabFiles\dp-300-database-administrator\Allfiles\Labs\10\ExecuteRandomWorkload.sql** 파일을 열고 **Execute**를 선택하여 쿼리를 실행합니다. (이 스크립트는 방금 만든 저장 프로시저를 실행하여 부하를 생성합니다.)

6.  실행이 완료된 후 스크립트를 **한 번 더 실행**하여 서버에 추가 부하를 생성합니다. 이 쿼리에 대한 쿼리 탭은 열어 둡니다.

7.  다음 코드를 새 쿼리 창에 복사하여 붙여넣고 **Execute**를 선택하여 실행합니다.

    이 스크립트는 데이터베이스 `Compatibility Level`을 SQL Server 2022(**160**)로 변경합니다. 이제 SQL Server 2008 이후의 모든 기능과 개선 사항을 데이터베이스에서 사용할 수 있습니다.

    ```sql
    USE [master];
    GO

    ALTER DATABASE [AdventureWorks2017] SET COMPATIBILITY_LEVEL = 160; -- SQL Server 2022 호환성 수준
    GO
    ```

8.  **ExecuteRandomWorkload.sql** 파일의 쿼리 탭으로 돌아가서 다시 실행합니다. (이제 최신 호환성 수준에서 워크로드를 실행합니다.)

---

**6단계: Top Resource Consuming Queries 보고서 검토**

1.  `Query Store` 노드를 보려면 SQL Server Management Studio에서 AdventureWorks2017 데이터베이스를 새로 고쳐야 합니다. 데이터베이스 이름을 마우스 오른쪽 버튼으로 클릭하고 **Refresh**를 선택합니다. 그러면 데이터베이스 아래에 `Query Store` 노드가 표시됩니다.

2.  **Query Store** 노드를 확장하여 사용 가능한 모든 보고서를 확인합니다. **Top Resource Consuming Queries** 보고서를 선택합니다.

3.  보고서가 열리면 보고서의 오른쪽 상단 모서리에 있는 메뉴 드롭다운을 선택한 다음 **Configure**를 선택합니다.

4.  구성 화면에서 최소 쿼리 계획 수에 대한 필터를 **2**로 변경합니다. 그런 다음 **OK**를 선택합니다.

5.  보고서의 왼쪽 상단 부분에 있는 막대 차트에서 가장 왼쪽 막대를 선택하여 기간이 가장 긴 쿼리를 선택합니다.

    이렇게 하면 `Query Store`에서 가장 오래 걸린 쿼리에 대한 쿼리 및 계획 요약이 표시됩니다. 보고서의 오른쪽 상단 모서리에 있는 *Plan summary* 차트와 보고서 하단의 *query plan*을 확인하십시오.

---

**7단계: 더 나은 실행 계획 강제 적용 (Force a better execution plan)**

1.  아래 그림과 같이 보고서의 계획 요약 부분으로 이동합니다. 기간이 매우 다른 두 개의 실행 계획이 있음을 알 수 있습니다.

2.  보고서의 오른쪽 상단 창에서 기간이 가장 짧은 Plan ID(차트의 Y축에서 더 낮은 위치로 표시됨)를 선택합니다. Plan Summary 차트 옆에 있는 Plan ID를 선택합니다.

3.  요약 차트 아래에서 **Force Plan**을 선택합니다. 확인 창이 나타나면 **Yes**를 선택합니다.

    계획이 강제 적용되면 **Forced Plan** 버튼이 회색으로 비활성화되고 계획 요약 창의 계획에 강제 적용되었음을 나타내는 확인 표시가 나타납니다.

    쿼리 최적화 프로그램이 사용할 실행 계획에 대해 잘못된 선택을 하는 경우가 있을 수 있습니다. 이런 일이 발생하면 더 나은 성능을 보인다고 알고 있는 계획을 사용하도록 SQL Server에 강제할 수 있습니다.

---

**8단계: 쿼리 힌트를 사용하여 성능에 영향 주기**

다음으로 워크로드를 실행하고, 쿼리를 변경하여 매개 변수를 사용하고, 쿼리에 `query hint`를 적용한 다음 다시 실행합니다.

연습을 계속하기 전에 **Window** 메뉴를 선택한 다음 **Close All Documents**를 선택하여 현재 열려 있는 모든 쿼리 창을 닫습니다. 팝업에서 **No**를 선택합니다.

1.  **New Query**를 선택한 다음, 쿼리를 실행하기 전에 **Include Actual Execution Plan** 아이콘을 선택하거나 <kbd>CTRL</kbd>+<kbd>M</kbd>을 사용합니다.

2.  아래 쿼리를 실행합니다. 실행 계획에 `index seek` 연산자가 표시되는지 확인합니다.

    ```sql
    USE AdventureWorks2017;
    GO

    SELECT SalesOrderId, OrderDate
    FROM Sales.SalesOrderHeader
    WHERE SalesPersonID=288;
    ```

3.  새 쿼리 창에서 다음 쿼리를 실행합니다. 두 실행 계획을 비교하십시오.

    ```sql
    USE AdventureWorks2017;
    GO

    SELECT SalesOrderId, OrderDate
    FROM Sales.SalesOrderHeader
    WHERE SalesPersonID=277;
    ```

    이번에 유일한 변경 사항은 SalesPersonID 값이 277로 설정된 것입니다. 실행 계획에서 `Clustered Index Scan` 작업을 확인합니다.

보시다시피, 인덱스 통계를 기반으로 쿼리 최적화 프로그램은 **WHERE** 절의 값이 다르기 때문에 다른 실행 계획을 선택했습니다.

*SalesPersonID* 값만 변경했는데 왜 다른 계획이 있습니까?

이 쿼리는 **WHERE** 절에 상수를 사용하므로 최적화 프로그램은 이러한 각 쿼리를 고유한 것으로 간주하고 매번 다른 실행 계획을 생성합니다.

---

**9단계: 변수를 사용하고 Query Hint를 사용하도록 쿼리 변경**

1.  SalesPersonID에 변수 값을 사용하도록 쿼리를 변경합니다.

2.  T-SQL **DECLARE** 문을 사용하여 <strong>@SalesPersonID</strong>를 선언하여 **WHERE** 절에 값을 하드코딩하는 대신 값을 전달할 수 있도록 합니다. 암시적 변환을 피하기 위해 변수의 데이터 형식이 대상 테이블의 열 데이터 형식과 일치하는지 확인해야 합니다. 실제 쿼리 계획을 활성화한 상태로 쿼리를 실행합니다.

    ```sql
    USE AdventureWorks2017;
    GO

    SET STATISTICS IO, TIME ON;

    DECLARE @SalesPersonID INT;

    SELECT @SalesPersonID = 288;

    SELECT SalesOrderId, OrderDate
    FROM Sales.SalesOrderHeader
    WHERE SalesPersonID = @SalesPersonID;
    ```

    실행 계획을 검토하면 결과를 얻기 위해 `index scan`을 사용하고 있음을 알 수 있습니다. 쿼리 최적화 프로그램은 런타임까지 지역 변수의 값을 알 수 없으므로 좋은 최적화를 수행할 수 없었습니다.

3.  `query hint`를 제공하여 쿼리 최적화 프로그램이 더 나은 선택을 하도록 도울 수 있습니다. **OPTION (RECOMPILE)**을 사용하여 위 쿼리를 다시 실행합니다.

    ```sql
    USE AdventureWorks2017;
    GO

    SET STATISTICS IO, TIME ON;

    DECLARE @SalesPersonID INT;

    SELECT @SalesPersonID = 288;

    SELECT SalesOrderId, OrderDate
    FROM Sales.SalesOrderHeader
    WHERE SalesPersonID = @SalesPersonID
    OPTION (RECOMPILE); -- RECOMPILE 힌트 추가
    ```

    쿼리 최적화 프로그램이 더 효율적인 실행 계획을 선택할 수 있었음을 확인합니다. **RECOMPILE** 옵션은 쿼리 컴파일러가 변수를 해당 값으로 대체하도록 합니다.

    통계를 비교하면 메시지 탭에서 `query hint`가 없는 쿼리에 비해 `logical reads`의 차이가 **68%** 더 많음(689 대 409)을 알 수 있습니다.

---

**10단계: 정리**

데이터베이스나 랩 파일을 다른 용도로 사용하지 않는 경우 이 실습에서 만든 개체를 정리할 수 있습니다.

**C:\LabFiles 폴더 삭제**

1.  제공된 랩 가상 머신 또는 제공되지 않은 경우 로컬 컴퓨터에서 **File Explorer**를 엽니다.
2.  **C:\\** 로 이동합니다.
3.  **C:\LabFiles** 폴더를 삭제합니다.

**AdventureWorks2017 데이터베이스 삭제**

1.  제공된 랩 가상 머신 또는 제공되지 않은 경우 로컬 컴퓨터에서 SQL Server Management Studio (SSMS) 세션을 시작합니다.
2.  SSMS가 열리면 기본적으로 **Connect to Server** 대화 상자가 나타납니다. 기본 인스턴스를 선택하고 **Connect**를 선택합니다. **Trust server certificate** 확인란을 선택해야 할 수 있습니다.
3.  **Object Explorer**에서 **Databases** 폴더를 확장합니다.
4.  **AdventureWorks2017** 데이터베이스를 마우스 오른쪽 버튼으로 클릭하고 **Delete**를 선택합니다.
5.  **Delete Object** 대화 상자에서 **Close existing connections** 확인란을 선택합니다.
6.  **OK**를 선택합니다.

---

이것으로 실습을 성공적으로 완료했습니다.

이 연습에서는 쿼리 문제를 식별하고 쿼리 계획을 개선하기 위해 수정하는 방법을 배웠습니다.
