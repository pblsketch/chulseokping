-- 출석핑 P0-3: 세션 마감 헤드카운트 (IMPROVEMENT_BACKLOG P0-3, RESEARCH_DEVICE_BINDING §B-2)
-- "폰 2대 지참"의 유일한 실효 대책 = 교사 육안 확인 — 대학의 '불시 점검'을 원탭 UX로 내재화.
-- 확인 기록은 세션에, 불일치는 suspicious_flags(CHECKIN_HEADCOUNT_GAP, 로그-온리)에 남긴다.

alter table sessions
  add column headcount_confirmed_at timestamptz; -- null = 미확인
