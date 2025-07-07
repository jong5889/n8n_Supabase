-- PostgreSQL 초기화 스크립트
-- n8n + Supabase Docker Self-Hosting 환경용
-- 이 스크립트는 Docker 컨테이너 시작 시 자동으로 실행됩니다.

-- 한국어 로케일 설정
SET timezone = 'Asia/Seoul';

-- ========================================
-- 🐳 n8n 데이터베이스 설정
-- ========================================

-- n8n 사용자 생성
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'n8n_user') THEN
        CREATE ROLE n8n_user WITH LOGIN PASSWORD '21c6eca03260c759bcdd563bc1e95d15';
    END IF;
END
$$;

-- n8n 데이터베이스 생성
CREATE DATABASE n8n WITH OWNER = n8n_user ENCODING = 'UTF8' TEMPLATE template0;

-- n8n 사용자에게 권한 부여
GRANT ALL PRIVILEGES ON DATABASE n8n TO n8n_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO n8n_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO n8n_user;

-- ========================================
-- 🗄️ Supabase 데이터베이스 설정
-- ========================================

-- 메인 postgres 데이터베이스로 연결
\c postgres;

-- ========================================
-- 🔐 Supabase 사용자 및 역할 생성 (먼저 실행)
-- ========================================

-- Supabase 관리자 사용자 생성
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'supabase_admin') THEN
        CREATE ROLE supabase_admin WITH LOGIN PASSWORD '21c6eca03260c759bcdd563bc1e95d15' SUPERUSER;
    END IF;
END
$$;

-- anon 역할 생성 (익명 사용자)
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'anon') THEN
        CREATE ROLE anon NOLOGIN;
    END IF;
END
$$;

-- authenticated 역할 생성 (인증된 사용자)
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'authenticated') THEN
        CREATE ROLE authenticated NOLOGIN;
    END IF;
END
$$;

-- service_role 역할 생성 (서비스 역할)
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'service_role') THEN
        CREATE ROLE service_role NOLOGIN;
    END IF;
END
$$;

-- supabase_auth_admin 역할 생성 (인증 관리자)
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'supabase_auth_admin') THEN
        CREATE ROLE supabase_auth_admin NOLOGIN;
    END IF;
END
$$;

-- supabase_storage_admin 역할 생성 (스토리지 관리자)
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'supabase_storage_admin') THEN
        CREATE ROLE supabase_storage_admin NOLOGIN;
    END IF;
END
$$;

-- supabase_realtime_admin 역할 생성 (실시간 관리자)
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'supabase_realtime_admin') THEN
        CREATE ROLE supabase_realtime_admin NOLOGIN;
    END IF;
END
$$;

-- ========================================
-- 📊 Supabase 스키마 생성 (확장 기능 설치 전에 먼저 생성)
-- ========================================

-- extensions 스키마 생성 (확장 기능) - 가장 먼저 생성
CREATE SCHEMA IF NOT EXISTS extensions;
ALTER SCHEMA extensions OWNER TO supabase_admin;

-- auth 스키마 생성 (사용자 인증)
CREATE SCHEMA IF NOT EXISTS auth;
ALTER SCHEMA auth OWNER TO supabase_admin;

-- storage 스키마 생성 (파일 스토리지)
CREATE SCHEMA IF NOT EXISTS storage;
ALTER SCHEMA storage OWNER TO supabase_admin;

-- realtime 스키마 생성 (실시간 기능)
CREATE SCHEMA IF NOT EXISTS _realtime;
ALTER SCHEMA _realtime OWNER TO supabase_admin;

-- graphql 스키마 생성 (GraphQL API)
CREATE SCHEMA IF NOT EXISTS graphql;
ALTER SCHEMA graphql OWNER TO supabase_admin;

-- graphql_public 스키마 생성 (공개 GraphQL API)
CREATE SCHEMA IF NOT EXISTS graphql_public;
ALTER SCHEMA graphql_public OWNER TO supabase_admin;

-- ========================================
-- 🔧 Supabase 확장 기능 설치
-- ========================================

-- UUID 확장 (ID 생성용)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;

-- pg_stat_statements 확장 (쿼리 성능 모니터링)
CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA extensions;

-- pgcrypto 확장 (암호화 함수)
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

-- pgjwt 확장 (JWT 토큰 처리) - Supabase 전용 이미지에 포함됨
-- CREATE EXTENSION IF NOT EXISTS pgjwt WITH SCHEMA extensions;

-- vector 확장 (벡터 데이터베이스 기능) - 필요시 활성화
-- CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA extensions;

-- ========================================
-- 🔑 권한 설정
-- ========================================

-- anon 역할 권한 설정
GRANT USAGE ON SCHEMA public TO anon;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon;

-- authenticated 역할 권한 설정
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- service_role 역할 권한 설정 (모든 권한)
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO service_role;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO service_role;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO service_role;
GRANT ALL PRIVILEGES ON SCHEMA public TO service_role;

-- auth 스키마 권한 설정
GRANT ALL PRIVILEGES ON SCHEMA auth TO supabase_auth_admin;
GRANT USAGE ON SCHEMA auth TO anon, authenticated, service_role;

-- storage 스키마 권한 설정
GRANT ALL PRIVILEGES ON SCHEMA storage TO supabase_storage_admin;
GRANT USAGE ON SCHEMA storage TO anon, authenticated, service_role;

-- realtime 스키마 권한 설정
GRANT ALL PRIVILEGES ON SCHEMA _realtime TO supabase_realtime_admin;
GRANT USAGE ON SCHEMA _realtime TO service_role;

-- extensions 스키마 권한 설정
GRANT ALL PRIVILEGES ON SCHEMA extensions TO supabase_admin;
GRANT USAGE ON SCHEMA extensions TO anon, authenticated, service_role;

-- graphql 스키마 권한 설정
GRANT ALL PRIVILEGES ON SCHEMA graphql TO supabase_admin;
GRANT USAGE ON SCHEMA graphql TO anon, authenticated, service_role;

-- graphql_public 스키마 권한 설정
GRANT ALL PRIVILEGES ON SCHEMA graphql_public TO supabase_admin;
GRANT USAGE ON SCHEMA graphql_public TO anon, authenticated, service_role;

-- ========================================
-- 📝 기본 테이블 생성 (예시)
-- ========================================

-- 사용자 프로필 테이블 (예시)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    username TEXT UNIQUE,
    full_name TEXT,
    avatar_url TEXT,
    website TEXT,
    
    PRIMARY KEY (id),
    CONSTRAINT username_length CHECK (char_length(username) >= 3)
);

-- 프로필 테이블 권한 설정
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 프로필 테이블 정책 생성
CREATE POLICY "Public profiles are viewable by everyone." ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users can insert their own profile." ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile." ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- ========================================
-- 🔄 실시간 기능 설정
-- ========================================

-- 프로필 테이블에 실시간 기능 활성화
ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;

-- ========================================
-- 🔧 유틸리티 함수 생성
-- ========================================

-- 사용자 ID 반환 함수
CREATE OR REPLACE FUNCTION auth.uid() RETURNS UUID AS $$
    SELECT COALESCE(
        current_setting('request.jwt.claim.sub', true),
        (current_setting('request.jwt.claims', true)::jsonb ->> 'sub')
    )::UUID;
$$ LANGUAGE SQL STABLE;

-- 사용자 역할 반환 함수
CREATE OR REPLACE FUNCTION auth.role() RETURNS TEXT AS $$
    SELECT COALESCE(
        current_setting('request.jwt.claim.role', true),
        (current_setting('request.jwt.claims', true)::jsonb ->> 'role')
    )::TEXT;
$$ LANGUAGE SQL STABLE;

-- 사용자 이메일 반환 함수
CREATE OR REPLACE FUNCTION auth.email() RETURNS TEXT AS $$
    SELECT COALESCE(
        current_setting('request.jwt.claim.email', true),
        (current_setting('request.jwt.claims', true)::jsonb ->> 'email')
    )::TEXT;
$$ LANGUAGE SQL STABLE;

-- ========================================
-- 📊 성능 최적화 설정
-- ========================================

-- 연결 풀링 설정
ALTER SYSTEM SET max_connections = 100;
ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements';

-- 메모리 설정
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET effective_cache_size = '1GB';
ALTER SYSTEM SET maintenance_work_mem = '64MB';
ALTER SYSTEM SET checkpoint_completion_target = 0.9;
ALTER SYSTEM SET wal_buffers = '16MB';
ALTER SYSTEM SET default_statistics_target = 100;

-- 로그 설정
ALTER SYSTEM SET logging_collector = on;
ALTER SYSTEM SET log_directory = 'pg_log';
ALTER SYSTEM SET log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log';
ALTER SYSTEM SET log_truncate_on_rotation = on;
ALTER SYSTEM SET log_rotation_age = '1d';
ALTER SYSTEM SET log_rotation_size = '10MB';

-- ========================================
-- ✅ 초기화 완료 메시지
-- ========================================

SELECT 'PostgreSQL 초기화 완료! n8n과 Supabase 데이터베이스가 준비되었습니다.' AS message; 