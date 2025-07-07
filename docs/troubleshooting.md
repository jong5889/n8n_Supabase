# 🚨 문제 해결 가이드 (Troubleshooting Guide)

> n8n + Supabase Docker Self-Hosting 환경의 일반적인 문제들과 해결 방법

## 📋 목차
1. [일반적인 문제](#일반적인-문제)
2. [Docker 관련 문제](#docker-관련-문제)  
3. [n8n 관련 문제](#n8n-관련-문제)
4. [Supabase 관련 문제](#supabase-관련-문제)
5. [네트워크 및 포트 문제](#네트워크-및-포트-문제)
6. [성능 및 리소스 문제](#성능-및-리소스-문제)
7. [데이터베이스 관련 문제](#데이터베이스-관련-문제)

---

## 🔧 일반적인 문제

### ❌ 문제: 서비스가 시작되지 않음
```bash
# 증상
docker-compose up -d
# 일부 컨테이너가 실행되지 않음
```

#### ✅ 해결 방법
```bash
# 1. 모든 컨테이너 상태 확인
docker-compose ps

# 2. 실패한 서비스의 로그 확인
docker-compose logs [service_name]

# 3. 컨테이너 재시작
docker-compose restart [service_name]

# 4. 전체 재시작 (필요시)
docker-compose down
docker-compose up -d
```

### ❌ 문제: 환경 변수 설정 오류
```bash
# 증상
invalid environment variable syntax
```

#### ✅ 해결 방법
```bash
# 1. 환경 변수 파일 복사
cp env.example .env

# 2. 필수 값 설정
# POSTGRES_PASSWORD=your_secure_password
# JWT_SECRET=your-32-character-secret-key
# N8N_ENCRYPTION_KEY=your_32_character_encryption_key

# 3. 환경 변수 검증
docker-compose config
```

---

## 🐳 Docker 관련 문제

### ❌ 문제: Docker가 설치되지 않았거나 구버전
```bash
# 증상
docker: command not found
# 또는 버전 호환성 문제
```

#### ✅ 해결 방법
```bash
# macOS (Homebrew)
brew install docker docker-compose

# 또는 Docker Desktop 설치
# https://www.docker.com/products/docker-desktop

# 버전 확인
docker --version          # ≥ 20.0
docker-compose --version  # ≥ 2.0
```

### ❌ 문제: 디스크 공간 부족
```bash
# 증상
no space left on device
```

#### ✅ 해결 방법
```bash
# 1. 미사용 Docker 리소스 정리
docker system prune -a

# 2. 미사용 볼륨 정리
docker volume prune

# 3. 미사용 이미지 정리
docker image prune -a

# 4. 전체 정리 (주의: 모든 데이터 삭제)
docker system prune -a --volumes
```

### ❌ 문제: 권한 문제 (Linux/macOS)
```bash
# 증상
permission denied while trying to connect to Docker daemon
```

#### ✅ 해결 방법
```bash
# Linux: 사용자를 docker 그룹에 추가
sudo usermod -aG docker $USER
newgrp docker

# macOS: Docker Desktop 재시작
# 시스템 환경설정 > Docker Desktop 재실행
```

---

## 🔄 n8n 관련 문제

### ❌ 문제: n8n 웹 인터페이스 접근 불가
```bash
# 증상
http://localhost:5678 접속 실패
This site can't be reached
```

#### ✅ 해결 방법
```bash
# 1. n8n 컨테이너 상태 확인
docker logs n8n_workflow_engine

# 2. 포트 확인
lsof -i :5678

# 3. n8n 서비스 재시작
docker-compose restart n8n

# 4. 헬스체크 확인
curl http://localhost:5678/healthz
# 응답: {"status":"ok"}
```

### ❌ 문제: n8n 데이터베이스 연결 실패
```bash
# 증상
Database connection failed
ENOTFOUND postgres
```

#### ✅ 해결 방법
```bash
# 1. PostgreSQL 컨테이너 확인
docker logs supabase_postgres

# 2. 네트워크 연결 확인
docker exec n8n_workflow_engine ping supabase

# 3. SQLite 모드로 전환 (권장)
# docker-compose.yml에서 확인:
# DB_TYPE: sqlite
# DB_SQLITE_DATABASE: /home/node/.n8n/database.sqlite

# 4. n8n 데이터 볼륨 초기화 (필요시)
docker-compose down
docker volume rm n8n_supabase2_n8n_data
docker-compose up -d
```

### ❌ 문제: n8n 워크플로우 실행 실패
```bash
# 증상
Workflow execution failed
NodeApiError: Unauthorized
```

#### ✅ 해결 방법
```bash
# 1. Supabase credential 재설정
# n8n > Credentials > Supabase Local 편집
# Host: localhost:8000
# API Key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9

# 2. API 연결 테스트
curl http://localhost:8000/rest/v1/test_table

# 3. 권한 확인
curl http://localhost:3000/test_table
```

---

## 🗄️ Supabase 관련 문제

### ❌ 문제: Supabase Studio 접근 불가
```bash
# 증상
http://localhost:3001 접속 실패
Studio is not accessible
```

#### ✅ 해결 방법
```bash
# 1. Studio 컨테이너 상태 확인
docker logs supabase_studio

# 2. Studio 서비스 재시작
docker-compose restart studio

# 3. Studio 의존성 확인 (Meta, Kong)
docker-compose ps | grep -E "(meta|kong|studio)"

# 4. 대안: 브라우저 캐시 삭제 후 재시도
```

### ❌ 문제: PostgREST API 응답 없음
```bash
# 증상
curl http://localhost:3000/test_table
Connection refused
```

#### ✅ 해결 방법
```bash
# 1. PostgREST 컨테이너 확인
docker logs supabase_rest

# 2. PostgreSQL 연결 확인
docker exec supabase_postgres psql -U postgres -c "SELECT 1;"

# 3. 테이블 존재 확인
docker exec supabase_postgres psql -U postgres -c "\dt"

# 4. PostgREST 재시작
docker-compose restart rest
```

### ❌ 문제: 인증 서비스 오류
```bash
# 증상
Auth service not responding
GoTrue authentication failed
```

#### ✅ 해결 방법
```bash
# 1. Auth 서비스 상태 확인
curl http://localhost:9999/health

# 2. Auth 로그 확인
docker logs supabase_auth

# 3. JWT 설정 확인
# .env 파일에서 JWT_SECRET 값이 32자 이상인지 확인

# 4. Auth 서비스 재시작
docker-compose restart auth
```

---

## 🌐 네트워크 및 포트 문제

### ❌ 문제: 포트 충돌
```bash
# 증상
Port 5678 is already in use
bind: address already in use
```

#### ✅ 해결 방법
```bash
# 1. 포트 사용 프로세스 확인
lsof -i :5678
lsof -i :3000
lsof -i :3001

# 2. 프로세스 종료
kill -9 [PID]

# 3. 다른 포트로 변경 (docker-compose.yml)
ports:
  - "5679:5678"  # n8n
  - "3002:3000"  # Studio

# 4. 서비스 재시작
docker-compose down
docker-compose up -d
```

### ❌ 문제: 서비스 간 통신 실패
```bash
# 증상
Service mesh communication failed
Container cannot reach other services
```

#### ✅ 해결 방법
```bash
# 1. 네트워크 상태 확인
docker network ls
docker network inspect supabase_network

# 2. 컨테이너 간 연결 테스트
docker exec n8n_workflow_engine ping supabase_postgres
docker exec supabase_rest ping supabase

# 3. 네트워크 재생성
docker-compose down
docker network prune
docker-compose up -d
```

---

## 🚀 성능 및 리소스 문제

### ❌ 문제: 메모리 부족
```bash
# 증상
Container killed due to OOM
Out of memory error
```

#### ✅ 해결 방법
```bash
# 1. 시스템 리소스 확인
docker stats

# 2. 메모리 사용량 확인
free -h  # Linux
vm_stat  # macOS

# 3. Docker 메모리 제한 증가
# Docker Desktop > Settings > Resources > Memory (8GB 권장)

# 4. 서비스별 메모리 제한 설정 (docker-compose.yml)
deploy:
  resources:
    limits:
      memory: 512M
```

### ❌ 문제: 응답 속도 저하
```bash
# 증상
API responses are slow (>5 seconds)
Database queries timeout
```

#### ✅ 해결 방법
```bash
# 1. PostgreSQL 성능 튜닝
# docker-compose.yml에 추가:
environment:
  POSTGRES_SHARED_BUFFERS: 256MB
  POSTGRES_EFFECTIVE_CACHE_SIZE: 1GB

# 2. Redis 캐시 확인
docker exec supabase_redis redis-cli ping

# 3. 인덱스 생성
docker exec supabase_postgres psql -U postgres -c "
CREATE INDEX idx_test_table_name ON test_table(name);
CREATE INDEX idx_test_table_created_at ON test_table(created_at);
"

# 4. 연결 풀 최적화
environment:
  POSTGRES_MAX_CONNECTIONS: 100
```

---

## 💾 데이터베이스 관련 문제

### ❌ 문제: 데이터베이스 연결 실패
```bash
# 증상
FATAL: password authentication failed
Connection refused to PostgreSQL
```

#### ✅ 해결 방법
```bash
# 1. PostgreSQL 상태 확인
docker exec supabase_postgres pg_isready -U postgres

# 2. 패스워드 확인
# .env 파일의 POSTGRES_PASSWORD 값 확인

# 3. 데이터베이스 접속 테스트
docker exec -it supabase_postgres psql -U postgres -d postgres

# 4. 연결 문자열 확인
# postgres://postgres:password@supabase:5432/postgres
```

### ❌ 문제: 테이블이 존재하지 않음
```bash
# 증상
Table 'test_table' doesn't exist
relation "test_table" does not exist
```

#### ✅ 해결 방법
```bash
# 1. 테이블 목록 확인
docker exec supabase_postgres psql -U postgres -c "\dt"

# 2. 테이블 생성
docker exec supabase_postgres psql -U postgres -c "
CREATE TABLE test_table (
    id SERIAL PRIMARY KEY,
    name TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
"

# 3. 권한 설정
docker exec supabase_postgres psql -U postgres -c "
GRANT SELECT ON test_table TO anon;
GRANT ALL ON test_table TO authenticated;
"

# 4. 초기화 스크립트 확인
ls -la init-scripts/
```

### ❌ 문제: 데이터 손실
```bash
# 증상
All data disappeared after restart
Volume mounting failed
```

#### ✅ 해결 방법
```bash
# 1. 볼륨 상태 확인
docker volume ls
docker volume inspect n8n_supabase2_postgres_data

# 2. 백업에서 복원
# 백업이 있는 경우:
docker exec -i supabase_postgres psql -U postgres postgres < backup.sql

# 3. 볼륨 재생성 (주의: 데이터 손실)
docker-compose down
docker volume rm n8n_supabase2_postgres_data
docker-compose up -d

# 4. 정기 백업 설정
crontab -e
# 0 2 * * * docker exec supabase_postgres pg_dump -U postgres postgres > /backup/backup_$(date +\%Y\%m\%d).sql
```

---

## 🛠️ 고급 문제 해결

### SSL/TLS 인증서 문제
```bash
# 프로덕션 환경에서 HTTPS 설정 시
# nginx 또는 traefik 리버스 프록시 사용 권장
```

### 클러스터 환경 문제
```bash
# 다중 노드 배포 시 공유 스토리지 필요
# NFS, GlusterFS, 또는 클라우드 스토리지 사용
```

### 마이그레이션 문제
```bash
# 기존 데이터 마이그레이션 시
# 1. 현재 데이터 백업
# 2. 스키마 변경 스크립트 실행
# 3. 데이터 검증
# 4. 롤백 계획 준비
```

---

## 📞 추가 도움 받기

### 🔍 진단 명령어 모음
```bash
# 전체 시스템 상태 확인
docker-compose ps
docker-compose logs --tail=50

# 개별 서비스 상태
curl http://localhost:5678/healthz  # n8n
curl http://localhost:3000/         # PostgREST
curl http://localhost:9999/health   # Auth

# 리소스 사용량
docker stats --no-stream
```

### 📋 이슈 리포트 템플릿
```markdown
## 환경 정보
- OS: [macOS/Linux/Windows]
- Docker Version: [version]
- 문제 발생 시간: [timestamp]

## 증상
[문제 상황 상세 설명]

## 시도한 해결 방법
[시도한 방법들]

## 로그
```bash
[관련 로그 내용]
```

### 🌐 커뮤니티 지원
- **n8n Community**: https://community.n8n.io/
- **Supabase Discord**: https://discord.supabase.com/
- **Docker Documentation**: https://docs.docker.com/

---

## ✅ 체크리스트

### 기본 확인 사항
- [ ] Docker 및 Docker Compose 최신 버전 설치
- [ ] 환경 변수 파일(.env) 올바른 설정
- [ ] 포트 충돌 없음 (5678, 3000, 3001, 8000, 9999 등)
- [ ] 충분한 디스크 공간 (최소 10GB)
- [ ] 충분한 메모리 (최소 4GB)

### 서비스별 확인
- [ ] PostgreSQL: 정상 실행 및 연결 가능
- [ ] n8n: 웹 인터페이스 접속 가능
- [ ] PostgREST: API 응답 정상
- [ ] Auth: 헬스체크 통과
- [ ] Studio: 관리 대시보드 접속 가능

---

**🎯 대부분의 문제는 위 가이드로 해결 가능합니다!**  
**📅 최종 업데이트**: 2025년 7월 7일 