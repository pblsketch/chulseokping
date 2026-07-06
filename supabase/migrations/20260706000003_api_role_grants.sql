-- Supabase CLI 2.1xx의 "secure by default" 변경으로 public 스키마에서 API 롤
-- (anon/authenticated/service_role)의 SELECT/INSERT/UPDATE/DELETE 기본 부여가 사라졌다
-- (기본 권한이 Dxtm만 남아 service_role조차 permission denied).
-- 이 프로젝트의 접근 제어 정본은 RLS(20260705000002_rls.sql) — 표준 Supabase 기준선
-- (테이블 GRANT + RLS 강제)으로 명시 복원한다.
-- 정책 0개 테이블(class_secrets, student_link_codes)은 GRANT가 있어도 RLS가 전면 deny한다.

grant usage on schema public to anon, authenticated, service_role;

grant all privileges on all tables in schema public
  to anon, authenticated, service_role;
grant all privileges on all sequences in schema public
  to anon, authenticated, service_role;
grant execute on all functions in schema public
  to anon, authenticated, service_role;

-- 이후 마이그레이션(M6+)이 만드는 객체에도 동일 기준선 적용
alter default privileges in schema public
  grant all on tables to anon, authenticated, service_role;
alter default privileges in schema public
  grant all on sequences to anon, authenticated, service_role;
alter default privileges in schema public
  grant execute on functions to anon, authenticated, service_role;
