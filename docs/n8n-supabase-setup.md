# n8n - Supabase 연동 설정 가이드

## 📋 Supabase Credential 설정

### 1. 필요한 정보
현재 Docker 환경에서 사용 중인 Supabase 연결 정보:

```bash
Supabase URL: http://localhost:8000
Supabase Anon Key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9
Supabase Service Role Key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9
```

### 2. n8n에서 Credential 등록 단계

1. **n8n 웹 인터페이스 접속**
   - URL: http://localhost:5678
   - 처음 접속 시 계정 생성 필요

2. **Credentials 메뉴 접속**
   - 상단 메뉴에서 "Credentials" 클릭
   - 또는 `/credentials` 경로로 직접 이동

3. **새 Credential 생성**
   - "Add Credential" 버튼 클릭
   - "Supabase" 검색 후 선택

4. **Supabase Credential 설정**
   ```
   Name: Supabase Local
   Host: localhost:8000
   API Key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9
   ```

### 3. 테스트 워크플로우 생성

1. **새 워크플로우 생성**
   - "New Workflow" 클릭
   - 이름: "Supabase 연동 테스트"

2. **노드 추가**
   - Start 노드 (기본 포함)
   - Supabase 노드 추가
   - 생성한 credential 선택

3. **기본 작업 테스트**
   - Table: test_table
   - Operation: Get All
   - 실행하여 연결 확인

## 📊 연결 확인 방법

### API 엔드포인트 테스트
```bash
# PostgREST API 확인
curl http://localhost:3000/test_table

# Auth API 확인  
curl http://localhost:9999/health

# Kong Gateway 확인
curl http://localhost:8000/
```

### 데이터베이스 직접 확인
```bash
# PostgreSQL 접속
docker exec -it supabase_postgres psql -U postgres -d postgres

# 테이블 확인
\dt

# 데이터 확인
SELECT * FROM test_table;
```

## 🔧 문제 해결

### 연결 실패 시 확인사항
1. **서비스 상태 확인**
   ```bash
   docker-compose ps
   ```

2. **네트워크 연결 확인**
   ```bash
   curl http://localhost:8000/
   curl http://localhost:3000/
   ```

3. **로그 확인**
   ```bash
   docker logs supabase_kong
   docker logs supabase_rest
   ```

### 권한 오류 시
- Service Role Key 사용 확인
- API 키 형식 올바른지 검증
- 테이블 존재 여부 확인

## 📝 다음 단계
1. ✅ Credential 설정 완료
2. ⏳ CRUD 워크플로우 생성
3. ⏳ 실시간 동기화 테스트
4. ⏳ 에러 핸들링 구현 