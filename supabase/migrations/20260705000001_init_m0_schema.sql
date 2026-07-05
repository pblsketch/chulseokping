-- 출석핑 M0 스키마 (PRD §5 + ATTENDANCE_POLICY §10.1)
-- 계약: 좌표(lat/lng) 컬럼 금지. 출석 쓰기는 Edge Function(service role) 전용(RLS는 다음 마이그레이션).
-- 상태 5종 × 사유 4종 2축 모델. 출결 단위 = 세션(조회/교시).

create type user_role as enum ('teacher', 'student');
create type check_in_method as enum ('QR', 'PIN', 'BLE', 'MANUAL', 'LIST');
create type attendance_status as enum ('present', 'late', 'early_leave', 'class_absent', 'absent');
create type absence_reason as enum ('recognized', 'sick', 'unrecognized', 'other');
-- 출석인정 세부 코드 (ATTENDANCE_POLICY §10.1): 경조사/법정감염병/천재지변/교외체험학습/학폭피해/기타인정
create type recognized_code as enum (
  'family_event', 'infectious_disease', 'natural_disaster',
  'field_trip', 'school_violence', 'other_recognized'
);
create type session_type as enum ('HOMEROOM', 'PERIOD');
create type session_mode as enum ('KIOSK', 'BYOD');
create type session_status as enum ('ACTIVE', 'ENDED');

create table schools (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);

create table profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  role user_role not null,
  name text not null,
  student_number text,
  pin_hash text, -- 학생 PIN 해시(키오스크 체크인용). 평문 저장 금지.
  school_id uuid references schools (id),
  created_at timestamptz not null default now()
);

create table classes (
  id uuid primary key default gen_random_uuid(),
  school_id uuid references schools (id),
  teacher_id uuid not null references profiles (id),
  name text not null,
  invite_code text not null unique,
  created_at timestamptz not null default now()
);

-- TOTP secret은 클라이언트가 읽을 수 없어야 함 → 별도 테이블, 클라 정책 없음(= service role 전용)
create table class_secrets (
  class_id uuid primary key references classes (id) on delete cascade,
  qr_secret text not null -- hex 인코딩 HMAC key
);

create table student_classes (
  student_id uuid not null references profiles (id) on delete cascade,
  class_id uuid not null references classes (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (student_id, class_id)
);

create table sessions (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references classes (id),
  teacher_id uuid not null references profiles (id),
  type session_type not null,
  period smallint, -- PERIOD일 때만 교시(1~15)
  date date not null default ((now() at time zone 'Asia/Seoul')::date),
  mode session_mode not null default 'BYOD',
  status session_status not null default 'ACTIVE',
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  constraint sessions_period_check check (
    (type = 'PERIOD' and period between 1 and 15)
    or (type = 'HOMEROOM' and period is null)
  )
);

create index sessions_class_date_idx on sessions (class_id, date);
create index sessions_status_idx on sessions (status) where status = 'ACTIVE';

create table kiosk_devices (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references classes (id) on delete cascade,
  teacher_id uuid not null references profiles (id),
  device_token text not null unique,
  beacon_major integer not null,
  beacon_secret text not null, -- 회전 minor 파생용 base secret(hex). minor 자체는 저장하지 않는다(시간 파생).
  revoked boolean not null default false,
  last_seen_at timestamptz,
  created_at timestamptz not null default now()
);

create table consents (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references profiles (id) on delete cascade,
  policy_version text not null,
  guardian_confirmed_by uuid references profiles (id), -- 보호자 동의를 확인한 교사
  consented_at timestamptz not null default now(),
  unique (student_id, policy_version)
);

create table attendance_logs (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references profiles (id),
  class_id uuid not null references classes (id),
  session_id uuid not null references sessions (id),
  method check_in_method not null,
  status attendance_status not null default 'present',
  reason absence_reason,
  reason_code recognized_code,
  reason_detail text,
  document_submitted boolean not null default false, -- 질병결석 증빙(D+5) 제출 여부
  neis_excluded boolean not null default false, -- 교외체험학습: 출석인정 + 학생부 미기재 → 내보내기 제외
  kiosk_device_id uuid references kiosk_devices (id),
  check_in_time timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  updated_by uuid references profiles (id),
  unique (student_id, session_id), -- 멱등: 학생 × 세션 1행. 상태 변화는 행 갱신(새 행 금지).
  constraint attendance_reason_check check (
    (status = 'present' and reason is null)
    or (status <> 'present' and reason is not null)
  ),
  constraint attendance_reason_code_check check (
    reason_code is null or reason = 'recognized'
  )
);

create index attendance_logs_session_idx on attendance_logs (session_id);
create index attendance_logs_class_idx on attendance_logs (class_id);

-- 부정 의심 로그 (차단 없음, 로그-온리). evidence는 최소 정보만 — 좌표·raw RSSI 금지.
create table suspicious_flags (
  id uuid primary key default gen_random_uuid(),
  attendance_log_id uuid references attendance_logs (id) on delete cascade,
  session_id uuid references sessions (id),
  student_id uuid references profiles (id),
  flag_type text not null,
  evidence jsonb,
  reviewed boolean not null default false,
  created_at timestamptz not null default now()
);

create index suspicious_flags_unreviewed_idx on suspicious_flags (created_at) where reviewed = false;

create function set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger attendance_logs_set_updated_at
before update on attendance_logs
for each row execute function set_updated_at();
