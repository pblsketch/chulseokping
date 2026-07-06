-- 실시간 구독 대상 등록 (2026-07-06 실기 회귀 수정)
-- supabase_flutter의 .stream()은 supabase_realtime publication에 포함된 테이블만
-- 변경 이벤트를 받는다. 미등록 상태에서는 초기 1회 조회만 동작해서
-- 교사 대시보드 출석 현황·학생 홈 활성 세션이 "실시간"이 아니었다.
-- Realtime은 RLS(SELECT 정책)를 그대로 적용하므로 노출 범위는 기존과 동일하다.
alter publication supabase_realtime add table public.attendance_logs;
alter publication supabase_realtime add table public.sessions;
