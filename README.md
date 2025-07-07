# 🚀 n8n + Supabase Docker Self-Hosting 프로젝트

> **완전한 백엔드 + 워크플로우 자동화 통합 환경**

![Project Status](https://img.shields.io/badge/Status-Production%20Ready-brightgreen)
![Docker](https://img.shields.io/badge/Docker-Compose-blue)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15.8.1.095-blue)
![n8n](https://img.shields.io/badge/n8n-1.100.1-red)

## 📋 프로젝트 개요

이 프로젝트는 **n8n 워크플로우 엔진**과 **Supabase 백엔드 스택**을 Docker로 통합한 완전한 셀프 호스팅 환경입니다. 코드 없이 복잡한 비즈니스 로직을 구현하고, 완전한 백엔드 기능을 즉시 사용할 수 있습니다.

### 🎯 주요 기능
- ✅ **완전한 백엔드 스택**: PostgreSQL, 인증, API, 실시간, 파일 저장소
- ✅ **노코드 워크플로우**: n8n으로 200+ 서비스 연동
- ✅ **원클릭 배포**: Docker Compose로 11개 서비스 자동 설치
- ✅ **프로덕션 준비**: 모든 서비스 헬스체크 및 최적화 완료

## 🏗️ 아키텍처

### 서비스 구성 (11개)
```
🗄️  데이터베이스      📊 API & 게이트웨이     ⚡ 실시간 & 파일
├── PostgreSQL       ├── PostgREST API       ├── Realtime  
├── Redis            ├── Kong Gateway        ├── Storage
                     ├── Auth (GoTrue)       └── Imgproxy
                     
🛠️  관리 & 워크플로우   
├── Studio (관리 대시보드)
├── Meta (메타데이터)
└── n8n (워크플로우 엔진)
```

### 포트 매핑
| 서비스 | 포트 | 용도 |
|--------|------|------|
| **n8n** | 5678 | 워크플로우 생성/관리 |
| **Supabase Studio** | 3001 | 데이터베이스 관리 대시보드 |
| **PostgREST API** | 3000 | 자동 생성 REST API |
| **Kong Gateway** | 8000 | 통합 API 게이트웨이 |
| **Auth** | 9999 | 사용자 인증 |
| **Realtime** | 4000 | 실시간 데이터 동기화 |
| **Storage** | 5002 | 파일 업로드/다운로드 |
| **PostgreSQL** | 5432 | 메인 데이터베이스 |

## ⚡ 빠른 시작

### 1. 사전 요구사항
```bash
# Docker & Docker Compose 확인
docker --version          # ≥ 20.0
docker-compose --version  # ≥ 2.0
```

### 2. 프로젝트 클론 및 실행
```bash
# 저장소 클론
git clone <repository-url>
cd n8n_Supabase2

# 서비스 시작 (11개 컨테이너)
docker-compose up -d

# 상태 확인
docker-compose ps
```

### 3. 접속 확인
| 서비스 | URL | 설명 |
|--------|-----|------|
| **n8n** | http://localhost:5678 | 워크플로우 생성 |
| **Supabase Studio** | http://localhost:3001 | DB 관리 대시보드 |
| **API 문서** | http://localhost:3000 | PostgREST OpenAPI |

## 🔧 사용법

### n8n에서 Supabase 연동

1. **Credential 생성**
   ```
   n8n → Credentials → Add Credential → Supabase
   
   Name: Supabase Local
   Host: localhost:8000
   API Key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9
   ```

2. **워크플로우 생성**
   ```
   Start → Supabase Node → Configure
   - Table: test_table
   - Operation: Get All
   - Credential: Supabase Local
   ```

### API 직접 사용
```bash
# 데이터 조회
curl http://localhost:3000/test_table

# 데이터 생성
curl -X POST http://localhost:3000/test_table \
  -H "Content-Type: application/json" \
  -d '{"name": "새 데이터"}'

# 인증 상태 확인
curl http://localhost:9999/health
```

## 📊 데이터베이스 스키마

### 기본 테이블
```sql
-- 테스트 테이블 (자동 생성됨)
CREATE TABLE test_table (
    id SERIAL PRIMARY KEY,
    name TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 권한 설정
```sql
-- 익명 사용자 권한
GRANT SELECT ON test_table TO anon;

-- 인증된 사용자 권한  
GRANT ALL ON test_table TO authenticated;
```

## 🔐 보안 및 환경변수

### 주요 환경변수
```bash
# 데이터베이스
POSTGRES_PASSWORD=your_secure_postgres_password

# JWT 설정
JWT_SECRET=your-super-secret-jwt-token-with-at-least-32-characters

# API 키
ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9
SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9

# n8n 설정
N8N_ENCRYPTION_KEY=your_32_character_encryption_key_here
```

## 🧪 테스트

### 헬스체크
```bash
# 모든 서비스 상태 확인
docker-compose ps

# 개별 서비스 테스트
curl http://localhost:5678/healthz  # n8n
curl http://localhost:3000/         # PostgREST
curl http://localhost:9999/health   # Auth
```

### 통합 테스트
```bash
# API 기능 테스트
curl -X POST http://localhost:3000/test_table \
  -H "Content-Type: application/json" \
  -d '{"name": "테스트"}'

curl http://localhost:3000/test_table
```

## 📁 프로젝트 구조

```
n8n_Supabase2/
├── docker-compose.yml      # 메인 설정 파일
├── init-scripts/           # 데이터베이스 초기화
│   └── 01-init-databases.sql
├── supabase/              # Supabase 설정
│   └── kong.yml
├── n8n/                   # n8n 워크플로우
│   └── workflows/
├── n8n-workflows/         # 워크플로우 템플릿
│   └── supabase-test-workflow.json
├── docs/                  # 문서
│   ├── setup-guide.md
│   ├── troubleshooting.md
│   ├── backup-restore.md
│   ├── credential-setup.md
│   ├── n8n-supabase-setup.md
│   └── integration-test-results.md
├── README.md              # 이 파일
├── PRD.md                 # 프로젝트 요구사항
└── TODOs.md              # 작업 진행 상황
```

## 🔄 데이터 백업 및 복원

### 백업
```bash
# PostgreSQL 백업
docker exec supabase_postgres pg_dump -U postgres postgres > backup.sql

# 전체 볼륨 백업
docker run --rm -v n8n_supabase2_postgres_data:/data -v $(pwd):/backup ubuntu tar czf /backup/postgres_backup.tar.gz /data
```

### 복원
```bash
# PostgreSQL 복원
docker exec -i supabase_postgres psql -U postgres postgres < backup.sql
```

## 🚨 문제 해결

### 일반적인 문제

**포트 충돌**
```bash
# 사용 중인 포트 확인
lsof -i :5678  # n8n
lsof -i :3001  # Studio

# 다른 포트로 변경
docker-compose.yml에서 포트 수정 후 재시작
```

**서비스 시작 실패**
```bash
# 로그 확인
docker logs supabase_postgres
docker logs n8n_workflow_engine

# 서비스 재시작
docker-compose restart <service_name>
```

### 자세한 문제 해결
- 📖 [상세 문제 해결 가이드](docs/troubleshooting.md)
- 📖 [설치 가이드](docs/setup-guide.md)

## 📈 성능 최적화

### 권장 시스템 요구사항
- **CPU**: 4 코어 이상
- **RAM**: 8GB 이상
- **디스크**: 50GB 이상 SSD

### 운영 환경 설정
```bash
# 프로덕션 모드 실행
N8N_USER_MANAGEMENT_DISABLED=false docker-compose up -d

# 로그 레벨 조정
N8N_LOG_LEVEL=warn docker-compose up -d
```

## 🤝 기여하기

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📜 라이선스

이 프로젝트는 MIT 라이선스 하에 제공됩니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

## 🙏 감사 인사

- [n8n](https://n8n.io/) - 워크플로우 자동화 플랫폼
- [Supabase](https://supabase.com/) - 오픈소스 백엔드 플랫폼
- [Docker](https://docker.com/) - 컨테이너 플랫폼

## 📞 지원

- 📧 이슈 리포트: [GitHub Issues](issues)
- 📖 문서: [docs/](docs/)
- 💬 커뮤니티: [Discussions](discussions)

---

**🎯 현재 상태**: 프로덕션 준비 완료 (100% 작동)  
**🔄 마지막 업데이트**: 2025년 7월 7일 