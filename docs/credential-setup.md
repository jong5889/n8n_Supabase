# 🔑 n8n Credential 설정 가이드

## 📋 개요

이 가이드는 n8n에서 Supabase(PostgreSQL) 연결을 위한 credential 설정 방법을 설명합니다.

## 🌐 1단계: n8n 웹 인터페이스 접속

### 브라우저 접속
```
URL: http://localhost:5678
```

### 초기 설정 (최초 접속시)
1. **Owner 계정 생성**
   - First name: `Admin`
   - Last name: `User`
   - Email: `admin@n8n.com`
   - Password: `admin123` (변경 권장)

2. **인스턴스 설정**
   - Instance name: `n8n-supabase`
   - Company: `개인 프로젝트`
   - Workflow template: Skip

## 🔗 2단계: PostgreSQL Credential 추가

### Credential 생성
1. **Settings** 메뉴 클릭
2. **Credentials** 선택
3. **Add Credential** 버튼 클릭
4. **PostgreSQL** 검색 후 선택

### 연결 정보 입력
```
Credential Name: PostgreSQL-Supabase
Host: postgres
Port: 5432
Database: postgres
Username: postgres
Password: 21c6eca03260c759bcdd563bc1e95d15
SSL: false
Connection Timeout: 20000
```

### 연결 테스트
1. **Test Connection** 버튼 클릭
2. ✅ "Connection successful" 메시지 확인
3. **Save** 버튼 클릭

## 🧪 3단계: 첫 번째 워크플로우 생성

### 워크플로우 생성
1. **New Workflow** 클릭
2. **Start** 노드 옆에 **+** 버튼 클릭
3. **PostgreSQL** 노드 검색 후 추가

### PostgreSQL 노드 설정
1. **Credential** 드롭다운에서 `PostgreSQL-Supabase` 선택
2. **Operation**: `Execute Query` 선택
3. **Query** 필드에 테스트 쿼리 입력:
   ```sql
   SELECT 
       id,
       name,
       email,
       created_at
   FROM test_table 
   ORDER BY id;
   ```

### 워크플로우 실행
1. **Execute Workflow** 버튼 클릭
2. PostgreSQL 노드에서 **Execute Node** 클릭
3. 결과 데이터 확인

## 📊 4단계: 사용 가능한 테스트 쿼리

### READ 작업 (데이터 조회)
```sql
-- 모든 데이터 조회
SELECT * FROM test_table ORDER BY id;

-- 특정 사용자 조회
SELECT * FROM test_table WHERE email = 'test1@example.com';

-- 최근 데이터 조회
SELECT * FROM test_table WHERE created_at > NOW() - INTERVAL '1 day';
```

### CREATE 작업 (데이터 생성)
```sql
-- 새 사용자 추가
INSERT INTO test_table (name, email) 
VALUES ('n8n 테스트 사용자', 'n8n-test@example.com')
RETURNING id, name, email;

-- 중복 방지 삽입
INSERT INTO test_table (name, email) 
VALUES ('안전한 사용자', 'safe@example.com')
ON CONFLICT (email) DO NOTHING
RETURNING *;
```

### UPDATE 작업 (데이터 수정)
```sql
-- 사용자 이름 수정
UPDATE test_table 
SET name = 'n8n으로 수정됨' 
WHERE email = 'test1@example.com'
RETURNING *;

-- 타임스탬프 업데이트
UPDATE test_table 
SET created_at = CURRENT_TIMESTAMP 
WHERE id = 1
RETURNING id, name, created_at;
```

### DELETE 작업 (데이터 삭제)
```sql
-- 특정 이메일 삭제
DELETE FROM test_table 
WHERE email = 'delete@example.com'
RETURNING *;

-- 조건부 삭제
DELETE FROM test_table 
WHERE created_at < NOW() - INTERVAL '30 days'
RETURNING count(*);
```

## 🔧 5단계: 고급 Credential 설정

### Supabase API Credential (선택사항)
만약 Supabase REST API를 직접 사용하려면:

1. **HTTP Request** 노드 추가
2. **Authentication** 섹션에서:
   - Type: `Header Auth`
   - Name: `Authorization`
   - Value: `Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIn0.KII40NgaPV7F7AzYeE7_yj4GRZwN2RW4WHMiH5-m5rU`

3. **Headers** 추가:
   - `apikey`: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIn0.KII40NgaPV7F7AzYeE7_yj4GRZwN2RW4WHMiH5-m5rU`
   - `Content-Type`: `application/json`

### 환경별 Credential 관리
```
개발환경: PostgreSQL-Supabase-Dev
스테이징환경: PostgreSQL-Supabase-Staging  
운영환경: PostgreSQL-Supabase-Prod
```

## 🧪 6단계: 워크플로우 템플릿 사용

### 준비된 템플릿 Import
1. **n8n 웹 인터페이스**에서 **Import** 메뉴 선택
2. 프로젝트의 `n8n-workflows/crud-workflow-template.json` 파일 업로드
3. Credential 설정 후 바로 실행 가능

### 템플릿에 포함된 기능
- ✅ CRUD 모든 작업 (Create, Read, Update, Delete)
- ✅ 에러 핸들링 및 재시도 로직
- ✅ 데이터 검증 및 변환
- ✅ 실시간 알림 트리거

## 🔍 7단계: 문제 해결

### 연결 실패 시
1. **컨테이너 상태 확인**:
   ```bash
   docker compose ps postgres n8n
   ```

2. **네트워크 연결 테스트**:
   ```bash
   docker exec -it n8n_workflow_engine nc -zv postgres 5432
   ```

3. **로그 확인**:
   ```bash
   docker compose logs n8n postgres
   ```

### 자주 발생하는 문제
- **Host 설정**: n8n 컨테이너 내부에서는 `postgres`, 외부에서는 `localhost`
- **포트 차단**: 방화벽이나 Docker 네트워크 설정 확인
- **비밀번호 오류**: 환경 변수와 실제 DB 비밀번호 일치 확인

## 🚀 8단계: 다음 단계

Credential 설정이 완료되면:

1. **복잡한 워크플로우 생성**: 여러 노드를 조합한 자동화
2. **스케줄링 설정**: 정기적인 데이터 처리
3. **웹훅 연동**: 실시간 이벤트 처리
4. **API 연동**: 외부 서비스와 데이터 동기화

---

**💡 팁**: credential 설정 후 반드시 Test Connection으로 연결을 확인하세요! 