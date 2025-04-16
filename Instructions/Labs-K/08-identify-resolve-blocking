## 실습 8 – 차단 문제 식별 및 해결

**모듈:** Azure SQL에서 쿼리 성능 최적화

---

# 차단 문제 식별 및 해결

**예상 소요 시간: 15분**

**시나리오:**

수강생은 학습한 내용을 바탕으로 AdventureWorks 내 디지털 전환 프로젝트의 결과물을 파악합니다. Azure Portal 및 기타 도구를 검토하여 네이티브 도구를 활용하여 성능 관련 문제를 식별하고 해결하는 방법을 결정합니다. 마지막으로, 수강생은 차단 문제를 적절하게 식별하고 해결할 수 있게 됩니다.

여러분은 성능 관련 문제를 식별하고 발견된 문제를 해결하기 위한 실행 가능한 솔루션을 제공하는 데이터베이스 관리자로 고용되었습니다. 성능 문제를 조사하고 이를 해결하기 위한 방법을 제안해야 합니다.

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

**3단계: 차단된 쿼리 보고서 실행 (및 차단 시나리오 생성)**

1.  **새 쿼리**를 선택합니다. 다음 T-SQL 코드를 쿼리 창에 복사하여 붙여넣습니다. **실행**을 선택하여 이 쿼리를 실행합니다.

    ```sql
    USE MASTER
    GO

    -- 서버에 'Blocking' 확장 이벤트 세션 생성
    CREATE EVENT SESSION [Blocking] ON SERVER
    ADD EVENT sqlserver.blocked_process_report( -- 차단된 프로세스 보고서 이벤트 추가
        ACTION(sqlserver.client_app_name, sqlserver.client_hostname, sqlserver.database_id, sqlserver.database_name, sqlserver.nt_username, sqlserver.session_id, sqlserver.sql_text, sqlserver.username) -- 캡처할 추가 정보(Action)
    )
    ADD TARGET package0.ring_buffer -- 결과를 메모리 내 링 버퍼 대상에 저장
    WITH (
        MAX_MEMORY = 4096 KB, -- 최대 메모리
        EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS, -- 이벤트 손실 허용 모드
        MAX_DISPATCH_LATENCY = 30 SECONDS, -- 최대 디스패치 대기 시간
        MAX_EVENT_SIZE = 0 KB, -- 최대 이벤트 크기 (0 = 제한 없음)
        MEMORY_PARTITION_MODE = NONE, -- 메모리 파티션 모드
        TRACK_CAUSALITY = OFF, -- 인과 관계 추적 비활성화
        STARTUP_STATE = ON -- 서버 시작 시 자동 시작
    );
    GO

    -- 이벤트 세션 시작
    ALTER EVENT SESSION [Blocking] ON SERVER
    STATE = START;
    GO
    ```

    위의 T-SQL 코드는 차단 이벤트를 캡처하는 확장 이벤트(Extended Event) 세션을 만듭니다. 데이터에는 다음 요소가 포함됩니다.

    *   클라이언트 응용 프로그램 이름
    *   클라이언트 호스트 이름
    *   데이터베이스 ID
    *   데이터베이스 이름
    *   NT 사용자 이름
    *   세션 ID
    *   T-SQL 텍스트
    *   사용자 이름

2.  **새 쿼리**를 선택합니다. 다음 T-SQL 코드를 쿼리 창에 복사하여 붙여넣습니다. **실행**을 선택하여 이 쿼리를 실행합니다.

    ```sql
    -- 고급 옵션 표시 활성화
    EXEC sys.sp_configure N'show advanced options', 1;
    RECONFIGURE WITH OVERRIDE;
    GO

    -- 'blocked process threshold'를 60초로 설정
    EXEC sp_configure 'blocked process threshold (s)', 60;
    RECONFIGURE WITH OVERRIDE;
    GO
    ```

    > &#128221; 참고: 위 명령은 차단된 프로세스 보고서가 생성되는 임계값(초)을 지정합니다. 결과적으로 이 실습에서는 `blocked_process_report`가 발생할 때까지 오래 기다릴 필요가 없습니다. (기본값은 0으로 비활성화되어 있으며, 설정 시 최소 5초 권장)

3.  **새 쿼리**를 선택합니다. 다음 T-SQL 코드를 쿼리 창에 복사하여 붙여넣습니다. **실행**을 선택하여 이 쿼리를 실행합니다. **이 쿼리 창은 열어 둡니다.**

    ```sql
    USE AdventureWorks2017
    GO

    -- 트랜잭션 시작 (명시적 커밋 또는 롤백 전까지 잠금 유지)
    BEGIN TRANSACTION
        -- Person 테이블 업데이트 (실제 변경은 없지만 잠금 발생)
        UPDATE Person.Person
        SET LastName = LastName;
    GO
    ```

4.  **새 쿼리** 버튼을 선택하여 **다른 쿼리 창**을 엽니다. 다음 T-SQL 코드를 새 쿼리 창에 복사하여 붙여넣습니다. **실행**을 선택하여 이 쿼리를 실행합니다.

    ```sql
    USE AdventureWorks2017
    GO

    -- Person 테이블에서 데이터 조회 시도
    SELECT TOP (1000) [LastName]
      ,[FirstName]
      ,[Title]
    FROM Person.Person
    WHERE FirstName = 'David'
    GO
    ```

    > &#128221; 이 쿼리는 결과를 반환하지 않고 무기한 실행되는 것처럼 보입니다. 이는 이전 단계의 `UPDATE` 문이 보유한 잠금 때문에 차단(Block)되었기 때문입니다.

5.  **개체 탐색기**에서 **관리** -> **확장 이벤트** -> **세션**을 확장합니다.

    방금 만든 *Blocking*이라는 확장 이벤트가 목록에 있는 것을 확인합니다.

6.  *Blocking* 확장 이벤트를 확장하고 **package0.ring_buffer**를 마우스 오른쪽 버튼으로 클릭합니다. **대상 데이터 보기...**를 선택합니다.

7.  표시된 하이퍼링크(blocked_process_report XML 데이터)를 선택합니다.

8.  XML은 어떤 프로세스가 차단되고 있는지, 그리고 어떤 프로세스가 차단을 유발하는지 보여줍니다. 이 프로세스에서 실행된 쿼리와 시스템 정보를 볼 수 있습니다. 세션 ID(SPID)를 기록해 두십시오.

9.  또는 다음 쿼리를 실행하여 다른 세션을 차단하는 세션을 식별할 수 있습니다. 여기에는 *session_id*별로 차단된 세션 ID 목록이 포함됩니다. **새 쿼리** 창을 열고 다음 T-SQL 코드를 붙여넣은 다음 **실행**을 선택합니다.

    ```sql
    WITH cteBL (session_id, blocking_these) AS
    (SELECT s.session_id, blocking_these = x.blocking_these FROM sys.dm_exec_sessions s
    CROSS APPLY    (SELECT isnull(convert(varchar(6), er.session_id),'') + ', '
                    FROM sys.dm_exec_requests as er
                    WHERE er.blocking_session_id = isnull(s.session_id ,0)
                    AND er.blocking_session_id <> 0
                    FOR XML PATH('') ) AS x (blocking_these)
    )
    SELECT s.session_id, blocked_by = r.blocking_session_id, bl.blocking_these
    , batch_text = t.text, input_buffer = ib.event_info, s.login_name, s.host_name, s.program_name, s.last_request_start_time, s.status, r.wait_type, r.wait_time, r.last_wait_type
    FROM sys.dm_exec_sessions s
    LEFT OUTER JOIN sys.dm_exec_requests r on r.session_id = s.session_id
    INNER JOIN cteBL as bl on s.session_id = bl.session_id
    OUTER APPLY sys.dm_exec_sql_text (r.sql_handle) t
    OUTER APPLY sys.dm_exec_input_buffer(s.session_id, NULL) AS ib
    WHERE blocking_these is not null or r.blocking_session_id > 0
    ORDER BY len(bl.blocking_these) desc, r.blocking_session_id desc, r.session_id;
    ```

    > &#128221; 위 쿼리는 XML과 동일한 SPID를 반환합니다. (차단하는 세션 ID `blocked_by` 와 차단되는 세션 ID 목록 `blocking_these`)

10. **개체 탐색기**에서 *Blocking* 확장 이벤트를 마우스 오른쪽 버튼으로 클릭한 다음 **세션 중지**를 선택합니다.

11. **차단을 유발한 쿼리 세션**(3단계에서 `BEGIN TRANSACTION`을 실행한 창)으로 돌아가서 쿼리 아래 줄에 `ROLLBACK TRANSACTION`을 입력합니다. `ROLLBACK TRANSACTION` 부분만 **선택(하이라이트)**하고 **실행**을 선택합니다.

12. **차단되었던 쿼리 세션**(4단계에서 `SELECT` 문을 실행한 창)으로 돌아갑니다. 쿼리가 이제 완료되었음을 확인할 수 있습니다.

---

**4단계: Read Committed Snapshot 격리 수준 활성화 (차단 완화)**

1.  SQL Server Management Studio에서 **새 쿼리**를 선택합니다. 다음 T-SQL 코드를 쿼리 창에 복사하여 붙여넣습니다. **실행** 버튼을 선택하여 이 쿼리를 실행합니다.

    ```sql
    USE master
    GO

    -- AdventureWorks2017 데이터베이스에 READ_COMMITTED_SNAPSHOT 옵션 활성화
    ALTER DATABASE AdventureWorks2017 SET READ_COMMITTED_SNAPSHOT ON WITH ROLLBACK IMMEDIATE;
    GO
    ```

2.  새 쿼리 편집기에서 **차단을 유발했던 쿼리**를 다시 실행합니다. *ROLLBACK TRANSACTION 명령은 실행하지 마십시오.*

    ```sql
    USE AdventureWorks2017
    GO

    BEGIN TRANSACTION
        UPDATE Person.Person
        SET LastName = LastName;
    GO
    ```

3.  새 쿼리 편집기에서 **차단되었던 쿼리**를 다시 실행합니다.

    ```sql
    USE AdventureWorks2017
    GO

    SELECT TOP (1000) [LastName]
      ,[FirstName]
      ,[Title]
    FROM Person.Person
    WHERE firstname = 'David'
    GO
    ```

    이전 작업에서는 `UPDATE` 문에 의해 차단되었던 동일한 쿼리가 이번에는 왜 완료될까요?

    **Read Committed Snapshot 격리 수준(RCSI)**은 트랜잭션 격리의 낙관적 형태입니다. 활성화되면 읽기 작업(SELECT)은 차단되지 않고 **마지막으로 커밋된 버전의 데이터**를 읽습니다(행 버전 관리 사용). 따라서 UPDATE 트랜잭션이 아직 진행 중이더라도 SELECT 쿼리는 이전 커밋된 데이터를 즉시 반환합니다.

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

**확장 이벤트 세션 삭제 (선택 사항)**

1.  SSMS **개체 탐색기**에서 **관리** -> **확장 이벤트** -> **세션**으로 이동합니다.
2.  **Blocking** 세션을 마우스 오른쪽 버튼으로 클릭하고 **삭제**를 선택합니다.
3.  **확인**을 클릭합니다.

**blocked process threshold 설정 복원 (선택 사항)**

1.  SSMS에서 새 쿼리 창을 열고 다음을 실행하여 설정을 기본값(0)으로 되돌립니다.

    ```sql
    EXEC sp_configure 'blocked process threshold (s)', 0;
    RECONFIGURE WITH OVERRIDE;
    GO
    EXEC sys.sp_configure N'show advanced options', 0;
    RECONFIGURE WITH OVERRIDE;
    GO
    ```

---

이것으로 실습을 성공적으로 완료했습니다.

이 연습에서는 차단되는 세션을 식별하고 이러한 시나리오를 완화하는 방법을 배웠습니다.
