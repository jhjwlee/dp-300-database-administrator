## 실습 7 – 조각화 문제 감지 및 수정

**모듈:** Azure SQL에서 운영 리소스 모니터링 및 최적화

---


# 조각화 문제 감지 및 수정

**예상 소요 시간: 20분**

**시나리오:**

수강생은 학습한 내용을 바탕으로 AdventureWorks 내 디지털 전환 프로젝트의 결과물을 파악합니다. Azure Portal 및 기타 도구를 검토하여 네이티브 도구를 활용하여 성능 관련 문제를 식별하고 해결하는 방법을 결정합니다. 마지막으로, 수강생은 데이터베이스 내 조각화를 식별하고 이를 적절하게 해결하는 단계를 배웁니다.

여러분은 성능 관련 문제를 식별하고 발견된 문제를 해결하기 위한 실행 가능한 솔루션을 제공하는 데이터베이스 관리자로 고용되었습니다. AdventureWorks는 10년 이상 자전거 및 자전거 부품을 소비자와 유통업체에 직접 판매해 왔습니다. 최근 회사는 고객 요청을 처리하는 데 사용되는 제품의 성능 저하를 발견했습니다. SQL 도구를 사용하여 성능 문제를 식별하고 이를 해결하기 위한 방법을 제안해야 합니다.

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

**3단계: 인덱스 조각화 조사**

1.  **새 쿼리**를 선택합니다. 다음 T-SQL 코드를 쿼리 창에 복사하여 붙여넣습니다. **실행**을 선택하여 이 쿼리를 실행합니다.

    ```sql
    USE AdventureWorks2017
    GO

    SELECT
        i.name AS Index_Name,
        avg_fragmentation_in_percent,
        db_name(database_id) AS DatabaseName,
        i.object_id,
        i.index_id,
        index_type_desc
    FROM sys.dm_db_index_physical_stats(db_id('AdventureWorks2017'), object_id('person.address'), NULL, NULL, 'DETAILED') ps
    INNER JOIN sys.indexes i ON ps.object_id = i.object_id AND ps.index_id = i.index_id
    WHERE avg_fragmentation_in_percent > 50 -- 조각화가 50% 이상인 인덱스 찾기
    ```

    이 쿼리는 조각화가 **50%**를 초과하는 인덱스를 보고합니다. 쿼리는 결과를 반환하지 않아야 합니다.

2.  인덱스 조각화는 다음을 포함한 여러 요인에 의해 발생할 수 있습니다.

    *   테이블 또는 인덱스에 대한 빈번한 업데이트.
    *   테이블 또는 인덱스에 대한 빈번한 삽입 또는 삭제.
    *   페이지 분할.

    Person.Address 테이블과 해당 인덱스의 조각화 수준을 높이기 위해 많은 수의 레코드를 삽입하고 삭제합니다. 이렇게 하려면 다음 쿼리를 실행합니다.

    **새 쿼리**를 선택합니다. 다음 T-SQL 코드를 쿼리 창에 복사하여 붙여넣습니다. **실행**을 선택하여 이 쿼리를 실행합니다.

    ```sql
    USE AdventureWorks2017
    GO

    -- Address 테이블에 60,000개 레코드 삽입
    INSERT INTO [Person].[Address]
        ([AddressLine1], [AddressLine2], [City], [StateProvinceID], [PostalCode], [SpatialLocation], [rowguid], [ModifiedDate])
    SELECT
        'Split Avenue ' + CAST(v1.number AS VARCHAR(10)),
        'Apt ' + CAST(v2.number AS VARCHAR(10)),
        'PageSplitTown',
        100 + (v1.number % 60),  -- 60개의 다른 StateProvinceID (100-159)
        '88' + RIGHT('000' + CAST(v2.number AS VARCHAR(3)), 3), -- 구조화된 우편 번호
        NULL,
        NEWID(), -- 고유한 rowguid 보장
        GETDATE()
    FROM master.dbo.spt_values v1
    CROSS JOIN master.dbo.spt_values v2
    WHERE v1.type = 'P' AND v1.number BETWEEN 1 AND 300
    AND v2.type = 'P' AND v2.number BETWEEN 1 AND 200;
    GO

    -- Address 테이블에서 25,000개 레코드 삭제
    DELETE FROM [Person].[Address] WHERE AddressID BETWEEN 35001 AND 60000;
    GO

    -- Address 테이블에 40,000개 레코드 삽입
    INSERT INTO [Person].[Address]
        ([AddressLine1], [AddressLine2], [City], [StateProvinceID], [PostalCode], [SpatialLocation], [rowguid], [ModifiedDate])
    SELECT
        'Fragmented Street ' + CAST(v1.number AS VARCHAR(10)),
        'Suite ' + CAST(v2.number AS VARCHAR(10)),
        'FragmentCity',
        100 + (v1.number % 60),  -- 60개의 다른 StateProvinceID (100-159)
        '99' + RIGHT('000' + CAST(v2.number AS VARCHAR(3)), 3), -- 구조화된 우편 번호
        NULL,
        NEWID(), -- 행당 고유한 rowguid 보장
        GETDATE()
    FROM master.dbo.spt_values v1
    CROSS JOIN master.dbo.spt_values v2
    WHERE v1.type = 'P' AND v1.number BETWEEN 1 AND 200
    AND v2.type = 'P' AND v2.number BETWEEN 1 AND 200;
    GO
    ```

    이 쿼리는 많은 수의 레코드를 추가하고 삭제하여 Person.Address 테이블과 해당 인덱스의 조각화 수준을 높입니다.

3.  첫 번째 쿼리를 다시 실행합니다. 이제 네 개의 심하게 조각화된 인덱스를 볼 수 있을 것입니다.

4.  **새 쿼리**를 선택하고 다음 T-SQL 코드를 쿼리 창에 복사하여 붙여넣습니다. **실행**을 선택하여 이 쿼리를 실행합니다.

    ```sql
    SET STATISTICS IO, TIME ON
    GO

    USE AdventureWorks2017
    GO

    SELECT DISTINCT (StateProvinceID),
           count(StateProvinceID) AS CustomerCount
    FROM person.Address
    GROUP BY StateProvinceID
    ORDER BY count(StateProvinceID) DESC;
    GO
    ```

    SQL Server Management Studio의 결과 창에서 **메시지** 탭을 선택합니다. **Address** 테이블에서 쿼리가 수행한 논리적 읽기 수를 기록해 두십시오.

---

**4단계: 조각화된 인덱스 다시 작성**

1.  **새 쿼리**를 선택하고 다음 T-SQL 코드를 쿼리 창에 복사하여 붙여넣습니다. **실행**을 선택하여 이 쿼리를 실행합니다.

    ```sql
    USE AdventureWorks2017
    GO

    ALTER INDEX [IX_Address_StateProvinceID] ON [Person].[Address] REBUILD PARTITION = ALL
    WITH (PAD_INDEX = OFF,
        STATISTICS_NORECOMPUTE = OFF,
        SORT_IN_TEMPDB = OFF,
        IGNORE_DUP_KEY = OFF,
        ONLINE = OFF, -- Enterprise 버전이 아닌 경우 OFF로 설정해야 할 수 있습니다.
        ALLOW_ROW_LOCKS = ON,
        ALLOW_PAGE_LOCKS = ON)
    GO
    ```

2.  **새 쿼리**를 선택하고 다음 쿼리를 실행하여 **IX_Address_StateProvinceID** 인덱스의 조각화가 더 이상 50%를 초과하지 않는지 확인합니다.

    ```sql
    USE AdventureWorks2017
    GO

    SELECT DISTINCT
        i.name AS Index_Name,
        avg_fragmentation_in_percent,
        db_name(database_id) AS DatabaseName,
        i.object_id,
        i.index_id,
        index_type_desc
    FROM sys.dm_db_index_physical_stats(db_id('AdventureWorks2017'), object_id('person.address'), NULL, NULL, 'DETAILED') ps
    INNER JOIN sys.indexes i ON (ps.object_id = i.object_id AND ps.index_id = i.index_id)
    WHERE i.name = 'IX_Address_StateProvinceID'
    GO
    ```

    결과를 비교하면 **IX_Address_StateProvinceID**의 조각화가 88%에서 0%로 떨어진 것을 볼 수 있습니다.

3.  이전 섹션의 select 문을 다시 실행합니다. Management Studio의 **결과** 창의 **메시지** 탭에서 논리적 읽기 수를 기록해 두십시오. *Address 테이블의 인덱스를 다시 작성하기 전의 논리적 읽기 수와 비교하여 변경 사항이 있었습니까*?

    ```sql
    SET STATISTICS IO, TIME ON
    GO

    USE AdventureWorks2017
    GO

    SELECT DISTINCT (StateProvinceID),
           count(StateProvinceID) AS CustomerCount
    FROM person.Address
    GROUP BY StateProvinceID
    ORDER BY count(StateProvinceID) DESC;
    GO
    ```

인덱스가 다시 작성되었으므로 이제 가능한 한 효율적으로 작동하며 논리적 읽기 수가 줄어들 것입니다. 이제 인덱스 유지 관리가 쿼리 성능에 영향을 미칠 수 있음을 확인했습니다.

---

**5단계: 정리**

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

이 연습에서는 인덱스를 다시 작성하고 논리적 읽기를 분석하여 쿼리 성능을 향상시키는 방법을 배웠습니다.
