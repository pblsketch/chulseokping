-- 출석핑 P0-1: 세션 수집 시간창 (RESEARCH_TIME_WINDOW §5 — 패턴 D)
-- 원칙: "닫힘"의 진실은 타이머 이벤트가 아니라 시각 비교 — 거부/지각 판정은
-- 체크인 Edge Function이 매 요청 서버 now()로 수행한다. cron 스윕은 화면 정리용 보조.

alter table sessions
  add column close_at timestamptz,               -- 수집 창 마감(선언적). null = 수동 종료까지 무기한(현행 동작 보존)
  add column auto_late_after_minutes smallint;   -- 시작 후 N분 이후 체크인 = late 자동 판정. null = 자동 지각 없음(기본 — 학교장 재량 사항)

alter table sessions
  add constraint sessions_close_after_start
    check (close_at is null or close_at > started_at),
  add constraint sessions_auto_late_nonneg
    check (auto_late_after_minutes is null or auto_late_after_minutes >= 0);

create index sessions_active_close_idx on sessions (close_at)
  where status = 'ACTIVE';

-- 자동 지각(late)은 체크인 시점에 사유가 미확정(null)일 수 있다 — 사유 확정은 교사 몫(§5.3).
-- present=사유 없음 강제, late=사유 선택, 그 외(조퇴/결과/결석)=사유 필수는 유지.
alter table attendance_logs drop constraint attendance_reason_check;
alter table attendance_logs add constraint attendance_reason_check check (
  (status = 'present' and reason is null)
  or (status = 'late')
  or (status not in ('present', 'late') and reason is not null)
);

-- 보조 스윕: 만료된 ACTIVE 세션을 1분 주기로 ENDED 정리 (Realtime으로 화면 갱신).
-- 스윕이 늦어도 창 밖 체크인은 Edge Function 시각 판정이 이미 차단한다.
create extension if not exists pg_cron;
select cron.schedule(
  'close-expired-sessions',
  '* * * * *',
  $$
    update sessions set status = 'ENDED', ended_at = close_at
    where status = 'ACTIVE' and close_at < now()
  $$
);
