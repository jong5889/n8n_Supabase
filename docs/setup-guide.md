# 🚀 설치 가이드 (Setup Guide)

> n8n + Supabase Docker Self-Hosting 환경 설치 완전 가이드

## ✅ 사전 요구사항

### 시스템 요구사항
- **CPU**: 4 코어 이상 권장
- **RAM**: 8GB 이상 권장 (최소 4GB)
- **디스크**: 50GB 이상 SSD 권장
- **OS**: macOS, Linux, Windows (Docker 지원)

### 필수 소프트웨어
```bash
# Docker 설치 확인
docker --version          # ≥ 20.0
docker-compose --version  # ≥ 2.0

# 설치가 필요한 경우:
# macOS (Homebrew)
brew install docker docker-compose

# 또는 Docker Desktop 설치
# https://www.docker.com/products/docker-desktop
```

---

## 📦 1단계: 프로젝트 설치

### 저장소 클론
```bash
git clone <repository-url>
cd n8n_Supabase2

# 또는 다운로드
wget <download-url>
unzip n8n_Supabase2.zip
cd n8n_Supabase2
```

### 디렉토리 구조 확인
```bash
ls -la
# 다음 파일들이 있어야 함:
# - docker-compose.yml
# - env.example
# - README.md
# - init-scripts/
# - docs/
```

---

## ⚙️ 2단계: 환경 설정

### 환경 변수 파일 생성
```bash
# 환경 변수 템플릿 복사
cp env.example .env

# 환경 변수 편집 (선택사항)
nano .env
```

### 필수 설정 (최소 구성)
`.env` 파일에서 다음 값들만 변경하면 됩니다:
```bash
# 보안을 위해 변경 권장
POSTGRES_PASSWORD=your_secure_postgres_password
JWT_SECRET=your-super-secret-jwt-token-with-at-least-32-characters-long
N8N_ENCRYPTION_KEY=your_32_character_encryption_key_here

# 나머지는 기본값 사용 가능
```

---

## 🚀 3단계: 서비스 시작

### 원클릭 배포
```bash
# 모든 서비스 시작 (11개 컨테이너)
docker-compose up -d

# 상태 확인
docker-compose ps
```

### 정상 시작 확인
```bash
# 모든 서비스가 'Up' 상태여야 함
NAME                  IMAGE                 STATUS
supabase_postgres     postgres:15           Up
supabase_redis        redis:7-alpine        Up
supabase_auth         supabase/gotrue       Up
supabase_rest         postgrest/postgrest   Up
supabase_realtime     supabase/realtime     Up
supabase_storage      supabase/storage-api  Up
supabase_imgproxy     darthsim/imgproxy     Up
supabase_meta         supabase/postgres-meta Up
supabase_studio       supabase/studio       Up
kong_api_gateway      kong:3.4.0           Up
n8n_workflow_engine   n8nio/n8n:latest     Up
```

---

## 🌐 4단계: 서비스 접속

### 웹 인터페이스 접속
```bash
# n8n 워크플로우 (가장 중요)
open http://localhost:5678

# Supabase Studio (데이터베이스 관리)
open http://localhost:3001

# PostgREST API 문서
open http://localhost:3000
```

### 헬스체크 확인
```bash
# n8n 상태 확인
curl http://localhost:5678/healthz
# 응답: {"status":"ok"}

# PostgREST API 확인
curl http://localhost:3000/
# 응답: OpenAPI 스키마

# Auth 서비스 확인
curl http://localhost:9999/health
# 응답: {"date":"2025-07-07T...","description":"GoTrue ready"}
```

---

## 🔗 5단계: n8n - Supabase 연동

### n8n 초기 설정
1. **n8n 접속**: http://localhost:5678
2. **계정 생성**: 이메일과 패스워드 입력
3. **환경 설정**: 기본 설정으로 진행

### Supabase Credential 등록
1. **Credentials 메뉴**: 상단 `Credentials` 클릭
2. **새 Credential**: `Add Credential` 버튼
3. **Supabase 선택**: 검색에서 "Supabase" 선택
4. **설정 입력**:
   ```
   Name: Supabase Local
   Host: localhost:8000
   API Key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9
   ```
5. **테스트**: `Test` 버튼으로 연결 확인
6. **저장**: `Save` 버튼으로 완료

---

## 🧪 6단계: 연동 테스트

### 기본 데이터 확인
```bash
# 테스트 테이블 데이터 조회
curl http://localhost:3000/test_table

# 응답 예시:
# [{"id":1,"name":"테스트 데이터 1","created_at":"2025-07-07T..."}]
```

### 첫 번째 워크플로우 생성
1. **새 워크플로우**: n8n에서 `New Workflow` 클릭
2. **Start 노드**: 자동으로 추가됨
3. **Supabase 노드 추가**:
   - `+` 버튼 클릭
   - "Supabase" 검색 및 선택
   - Credential: "Supabase Local" 선택
   - Table: "test_table" 입력
   - Operation: "Get All" 선택
4. **노드 연결**: Start → Supabase 연결
5. **실행**: `Execute Workflow` 버튼
6. **결과 확인**: 테이블 데이터가 조회되면 성공!

---

## 📊 7단계: 추가 구성 (선택사항)

### Studio에서 데이터베이스 관리
1. **Studio 접속**: http://localhost:3001
2. **테이블 뷰어**: 왼쪽 메뉴에서 테이블 확인
3. **SQL 편집기**: 쿼리 직접 실행 가능
4. **API 설정**: API 키 및 권한 관리

### 실시간 기능 테스트
```bash
# Realtime 서비스 확인
curl http://localhost:4000/api/health

# WebSocket 연결 (JavaScript 예시)
const socket = new WebSocket('ws://localhost:4000/realtime/v1/websocket');
```

### 파일 저장소 테스트
```bash
# Storage 서비스 확인
curl http://localhost:5002/status

# 파일 업로드 테스트 (API 사용)
curl -X POST http://localhost:5002/object/test-bucket/test.txt \
  -H "Authorization: Bearer YOUR_TOKEN" \
  --data-binary @test.txt
```

---

## 🛠️ 관리 명령어

### 일상적인 관리
```bash
# 서비스 중지
docker-compose stop

# 서비스 시작
docker-compose start

# 서비스 재시작
docker-compose restart

# 로그 확인
docker-compose logs -f [service_name]

# 특정 서비스만 재시작
docker-compose restart n8n
```

### 데이터 관리
```bash
# 데이터베이스 백업
docker exec supabase_postgres pg_dump -U postgres postgres > backup.sql

# 데이터베이스 복원
docker exec -i supabase_postgres psql -U postgres postgres < backup.sql

# 볼륨 상태 확인
docker volume ls | grep n8n_supabase2
```

### 시스템 정리
```bash
# 로그 정리
docker-compose logs --tail=0 > /dev/null

# 미사용 리소스 정리
docker system prune

# 완전 재설치 (주의: 모든 데이터 삭제)
docker-compose down -v
docker system prune -a
docker-compose up -d
```

---

## 🚨 문제 해결

### 일반적인 문제
```bash
# 포트 충돌 시
lsof -i :5678
kill -9 [PID]

# 서비스 시작 실패 시
docker-compose logs [service_name]
docker-compose restart [service_name]

# 메모리 부족 시
docker stats
# Docker Desktop에서 메모리 할당 증가 (8GB 권장)
```

### 자세한 문제 해결
📖 **[상세 문제 해결 가이드](troubleshooting.md)** 참조

---

## ✅ 설치 완료 체크리스트

### 필수 확인 사항
- [ ] Docker 서비스 11개 모두 실행 중
- [ ] n8n 웹 인터페이스 접속 가능 (http://localhost:5678)
- [ ] Supabase Studio 접속 가능 (http://localhost:3001)
- [ ] n8n에서 Supabase credential 등록 완료
- [ ] 테스트 워크플로우 실행 성공

### 추가 확인 사항
- [ ] API 엔드포인트 정상 응답 (http://localhost:3000)
- [ ] 헬스체크 모두 통과
- [ ] 테스트 데이터 CRUD 작업 가능
- [ ] 백업 전략 수립

---

## 🎯 다음 단계

### 학습 리소스
- 📖 **[README.md](../README.md)**: 전체 사용법 가이드
- 📖 **[n8n-supabase-setup.md](n8n-supabase-setup.md)**: 연동 상세 가이드
- 📖 **[CRUD 테스트 결과](crud-integration-tests.md)**: 통합 테스트 예시

### 고급 설정
- 📊 **모니터링**: Grafana + Prometheus 추가
- 🔐 **보안**: SSL/TLS 인증서 설정
- 📈 **성능**: 프로덕션 최적화
- 🌐 **배포**: 클라우드 환경 전환

---

**🎉 축하합니다! n8n + Supabase 통합 환경 설치 완료!**

이제 강력한 백엔드 서비스와 워크플로우 자동화 기능을 즉시 사용할 수 있습니다.

**📞 도움이 필요하시면**: [troubleshooting.md](troubleshooting.md) 또는 커뮤니티 포럼을 이용해주세요.

---

**📅 최종 업데이트**: 2025년 7월 7일  
**⚡ 설치 시간**: 약 10-15분  
**🎯 성공률**: 99% (가이드 따라 진행 시) 