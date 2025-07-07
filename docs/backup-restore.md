# 💾 백업 및 복원 가이드

## 📋 백업 개요

### 백업 대상
- **PostgreSQL 데이터베이스**: 모든 테이블과 데이터
- **n8n 워크플로우**: 생성한 워크플로우 및 설정
- **환경 설정**: Docker Compose 설정 및 환경 변수
- **볼륨 데이터**: 영구 저장된 데이터

### 백업 주기 권장사항
- **일일 백업**: 운영 환경
- **주간 백업**: 개발 환경
- **프로젝트 변경 전**: 수동 백업

## 🔄 PostgreSQL 백업

### 1. 전체 데이터베이스 백업

```bash
# 1. 전체 데이터베이스 백업
docker exec -it n8n_supabase_postgres pg_dump -U postgres postgres > backup_$(date +%Y%m%d_%H%M%S).sql

# 2. 압축 백업
docker exec -it n8n_supabase_postgres pg_dump -U postgres postgres | gzip > backup_$(date +%Y%m%d_%H%M%S).sql.gz

# 3. 커스텀 형식 백업 (권장)
docker exec -it n8n_supabase_postgres pg_dump -U postgres -Fc postgres > backup_$(date +%Y%m%d_%H%M%S).dump
```

### 2. 특정 테이블 백업

```bash
# 특정 테이블만 백업
docker exec -it n8n_supabase_postgres pg_dump -U postgres -t test_table postgres > test_table_backup.sql

# 여러 테이블 백업
docker exec -it n8n_supabase_postgres pg_dump -U postgres -t test_table -t auth_users postgres > multiple_tables_backup.sql
```

### 3. 스키마만 백업

```bash
# 스키마 구조만 백업 (데이터 제외)
docker exec -it n8n_supabase_postgres pg_dump -U postgres -s postgres > schema_backup.sql

# 데이터만 백업 (스키마 제외)
docker exec -it n8n_supabase_postgres pg_dump -U postgres -a postgres > data_backup.sql
```

## 🔄 n8n 백업

### 1. 워크플로우 백업

```bash
# n8n 데이터 볼륨 백업
docker run --rm -v n8n_supabase_n8n_data:/data -v $(pwd):/backup alpine tar czf /backup/n8n_data_backup_$(date +%Y%m%d_%H%M%S).tar.gz -C /data .

# 워크플로우 내보내기 (n8n 웹 인터페이스)
# 1. n8n 웹 인터페이스 접속
# 2. Settings → Import/Export → Export workflows
# 3. JSON 파일로 저장
```

### 2. n8n 설정 백업

```bash
# n8n 설정 파일 백업
docker exec -it n8n_workflow_engine sh -c "tar czf - /home/node/.n8n" > n8n_config_backup_$(date +%Y%m%d_%H%M%S).tar.gz
```

## 🔄 전체 시스템 백업

### 1. 자동화된 백업 스크립트

```bash
# backup.sh 파일 생성
cat > backup.sh << 'EOF'
#!/bin/bash

# 백업 디렉토리 설정
BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

echo "=== 백업 시작: $DATE ==="

# 1. PostgreSQL 백업
echo "PostgreSQL 백업 중..."
docker exec -it n8n_supabase_postgres pg_dump -U postgres -Fc postgres > $BACKUP_DIR/postgres_$DATE.dump

# 2. n8n 데이터 백업
echo "n8n 데이터 백업 중..."
docker run --rm -v n8n_supabase_n8n_data:/data -v $(pwd)/$BACKUP_DIR:/backup alpine tar czf /backup/n8n_data_$DATE.tar.gz -C /data .

# 3. 설정 파일 백업
echo "설정 파일 백업 중..."
tar czf $BACKUP_DIR/config_$DATE.tar.gz .env docker-compose.yml init-scripts/ supabase/

# 4. 볼륨 백업
echo "볼륨 백업 중..."
docker run --rm -v n8n_supabase_postgres_data:/data -v $(pwd)/$BACKUP_DIR:/backup alpine tar czf /backup/postgres_volume_$DATE.tar.gz -C /data .

echo "=== 백업 완료: $DATE ==="
echo "백업 파일 위치: $BACKUP_DIR"
ls -la $BACKUP_DIR/*$DATE*
EOF

# 실행 권한 부여
chmod +x backup.sh

# 백업 실행
./backup.sh
```

### 2. 크론 잡 설정 (자동 백업)

```bash
# crontab 편집
crontab -e

# 매일 새벽 2시에 백업 실행
0 2 * * * cd /path/to/n8n_Supabase && ./backup.sh >> /var/log/n8n_backup.log 2>&1

# 매주 일요일 새벽 3시에 백업 실행
0 3 * * 0 cd /path/to/n8n_Supabase && ./backup.sh >> /var/log/n8n_backup.log 2>&1
```

## 🔄 복원 절차

### 1. PostgreSQL 복원

```bash
# 1. 컨테이너 중지
docker compose down

# 2. 데이터베이스 볼륨 삭제 (주의: 모든 데이터 손실)
docker volume rm n8n_supabase_postgres_data

# 3. PostgreSQL 컨테이너만 시작
docker compose up -d postgres

# 4. 데이터베이스 복원
# SQL 파일 복원
docker exec -i n8n_supabase_postgres psql -U postgres postgres < backup_20240106_120000.sql

# 커스텀 형식 복원
docker exec -i n8n_supabase_postgres pg_restore -U postgres -d postgres backup_20240106_120000.dump

# 5. 모든 서비스 시작
docker compose up -d
```

### 2. n8n 복원

```bash
# 1. n8n 컨테이너 중지
docker compose stop n8n

# 2. n8n 데이터 볼륨 삭제
docker volume rm n8n_supabase_n8n_data

# 3. 백업 데이터 복원
docker run --rm -v n8n_supabase_n8n_data:/data -v $(pwd)/backups:/backup alpine tar xzf /backup/n8n_data_20240106_120000.tar.gz -C /data

# 4. n8n 서비스 재시작
docker compose up -d n8n
```

### 3. 전체 시스템 복원

```bash
# 전체 복원 스크립트
cat > restore.sh << 'EOF'
#!/bin/bash

if [ -z "$1" ]; then
    echo "사용법: ./restore.sh BACKUP_DATE"
    echo "예시: ./restore.sh 20240106_120000"
    exit 1
fi

BACKUP_DATE=$1
BACKUP_DIR="./backups"

echo "=== 복원 시작: $BACKUP_DATE ==="

# 1. 모든 컨테이너 중지
echo "컨테이너 중지 중..."
docker compose down

# 2. 볼륨 삭제 (주의!)
echo "기존 볼륨 삭제 중..."
docker volume rm n8n_supabase_postgres_data n8n_supabase_n8n_data

# 3. 설정 파일 복원
echo "설정 파일 복원 중..."
tar xzf $BACKUP_DIR/config_$BACKUP_DATE.tar.gz

# 4. PostgreSQL 시작 및 복원
echo "PostgreSQL 복원 중..."
docker compose up -d postgres
sleep 30
docker exec -i n8n_supabase_postgres pg_restore -U postgres -d postgres $BACKUP_DIR/postgres_$BACKUP_DATE.dump

# 5. n8n 데이터 복원
echo "n8n 데이터 복원 중..."
docker run --rm -v n8n_supabase_n8n_data:/data -v $(pwd)/$BACKUP_DIR:/backup alpine tar xzf /backup/n8n_data_$BACKUP_DATE.tar.gz -C /data

# 6. 모든 서비스 시작
echo "모든 서비스 시작 중..."
docker compose up -d

echo "=== 복원 완료: $BACKUP_DATE ==="
EOF

# 실행 권한 부여
chmod +x restore.sh

# 복원 실행 예시
# ./restore.sh 20240106_120000
```

## 🔄 부분 복원

### 1. 특정 테이블 복원

```bash
# 1. 특정 테이블 백업에서 복원
docker exec -i n8n_supabase_postgres psql -U postgres postgres < test_table_backup.sql

# 2. 테이블 삭제 후 복원
docker exec -it n8n_supabase_postgres psql -U postgres postgres -c "DROP TABLE IF EXISTS test_table;"
docker exec -i n8n_supabase_postgres psql -U postgres postgres < test_table_backup.sql
```

### 2. 특정 워크플로우 복원

```bash
# n8n 웹 인터페이스에서:
# 1. Settings → Import/Export → Import workflows
# 2. 백업된 JSON 파일 선택
# 3. Import 클릭
```

## 🔄 원격 백업

### 1. 클라우드 스토리지 백업

```bash
# AWS S3 백업
aws s3 cp backup_$(date +%Y%m%d_%H%M%S).sql.gz s3://your-bucket/n8n-backups/

# Google Cloud Storage 백업
gsutil cp backup_$(date +%Y%m%d_%H%M%S).sql.gz gs://your-bucket/n8n-backups/

# Azure Blob Storage 백업
az storage blob upload --file backup_$(date +%Y%m%d_%H%M%S).sql.gz --container-name n8n-backups --name backup_$(date +%Y%m%d_%H%M%S).sql.gz
```

### 2. 원격 서버 백업

```bash
# SCP를 통한 원격 백업
scp backup_$(date +%Y%m%d_%H%M%S).sql.gz user@remote-server:/backup/n8n/

# rsync를 통한 동기화
rsync -avz --delete ./backups/ user@remote-server:/backup/n8n/
```

## 🔄 백업 검증

### 1. 백업 파일 무결성 검사

```bash
# 파일 크기 확인
ls -lh backups/

# 압축 파일 검증
gzip -t backup_20240106_120000.sql.gz

# tar 파일 검증
tar -tzf n8n_data_20240106_120000.tar.gz
```

### 2. 백업 데이터 검증

```bash
# 별도 환경에서 복원 테스트
# 1. 테스트 환경 생성
mkdir backup_test
cd backup_test

# 2. 백업에서 복원
cp ../backups/postgres_20240106_120000.dump .
# 복원 스크립트 실행

# 3. 데이터 검증
docker exec -it test_postgres psql -U postgres -c "SELECT count(*) FROM test_table;"
```

## 🔄 재해 복구 계획

### 1. 복구 우선순위

1. **데이터베이스 복원** (최우선)
2. **n8n 워크플로우 복원**
3. **설정 파일 복원**
4. **서비스 재시작**

### 2. 복구 시간 목표 (RTO)

- **데이터베이스**: 30분 이내
- **n8n 워크플로우**: 15분 이내
- **전체 시스템**: 1시간 이내

### 3. 복구 지점 목표 (RPO)

- **운영 환경**: 최대 1시간 데이터 손실
- **개발 환경**: 최대 24시간 데이터 손실

## 🔄 백업 관리

### 1. 백업 파일 정리

```bash
# 30일 이상 된 백업 파일 삭제
find ./backups -name "*.sql.gz" -mtime +30 -delete
find ./backups -name "*.tar.gz" -mtime +30 -delete

# 백업 파일 개수 제한 (최근 10개만 유지)
ls -t ./backups/*.sql.gz | tail -n +11 | xargs rm -f
```

### 2. 백업 모니터링

```bash
# 백업 로그 확인
tail -f /var/log/n8n_backup.log

# 백업 성공/실패 알림
if [ $? -eq 0 ]; then
    echo "백업 성공" | mail -s "n8n 백업 성공" admin@example.com
else
    echo "백업 실패" | mail -s "n8n 백업 실패" admin@example.com
fi
```

## 📊 백업 모범 사례

### 1. 3-2-1 백업 규칙

- **3개 복사본**: 원본 + 2개 백업
- **2개 다른 매체**: 로컬 + 원격
- **1개 오프사이트**: 클라우드 또는 원격 위치

### 2. 백업 테스트

- **월간 복원 테스트**: 백업 파일 무결성 확인
- **분기별 전체 복원**: 재해 복구 시나리오 테스트
- **연간 DR 훈련**: 전체 재해 복구 절차 점검

### 3. 문서화

- **백업 절차 문서**: 최신 상태 유지
- **복원 절차 문서**: 단계별 가이드
- **담당자 연락처**: 비상 연락망

---

**💡 중요**: 백업은 정기적으로 테스트하고, 복원 절차를 숙지해야 합니다! 