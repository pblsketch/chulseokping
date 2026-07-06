-- 출석핑 P0-2: 기기 바인딩 (RESEARCH_DEVICE_BINDING §B-1, B-2)
-- 원칙: 차단이 아니라 공격 비용 인상 + 증거 확보. 미바인딩 기기 체크인도 기록은 된다(로그-온리).
-- 식별자: 서버 발급 device_uuid (클라 Keychain/Keystore 보관). SSAID·IMEI·MAC·광고ID는 키 금지.

create table student_devices (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references profiles (id) on delete cascade,
  device_uuid uuid not null unique default gen_random_uuid(), -- 서버 발급 — 클라 보안저장소 보관
  platform text not null check (platform in ('android', 'ios')),
  device_model text, -- 메타데이터 (PII 아님)
  app_set_id text, -- Android만, 사기방지 보조 신호 (바인딩 키 아님)
  status text not null default 'active'
    check (status in ('active', 'pending', 'revoked')),
  registered_at timestamptz not null default now(),
  revoked_at timestamptz,
  revoked_by uuid references profiles (id), -- 교사 승인/회수 흔적
  replaced_by uuid references student_devices (id)
);

-- 핵심 불변식: 학생당 active 1대
create unique index student_devices_one_active
  on student_devices (student_id) where status = 'active';
create index student_devices_student_idx on student_devices (student_id);

-- QR/BLE 경로만 기록 (PIN/MANUAL/LIST는 null)
alter table attendance_logs
  add column student_device_id uuid references student_devices (id);

-- RLS: 등록·승인·회수는 Edge Function(service role) 전용 — 쓰기 정책 0개.
-- 읽기: 학생=본인 기기, 교사=담당 학생 기기(승인 UI용).
alter table student_devices enable row level security;

create policy student_devices_student_select on student_devices
  for select to authenticated using (student_id = auth.uid());
create policy student_devices_teacher_select on student_devices
  for select to authenticated using (teaches_student(student_id));
