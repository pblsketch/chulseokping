-- 출석핑 M5: 학생 연결 코드 (하이브리드 계정 모델)
-- 교사가 학생 계정을 일괄 생성(create_students, service role)하고,
-- 학생은 연결 코드 1회 입력으로 자기 기기를 계정에 연결한다(redeem_link_code).
-- 코드 평문은 발급 응답에서만 노출 — DB에는 sha256 해시만 저장한다.

create table student_link_codes (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references profiles (id) on delete cascade,
  code_hash text not null unique, -- sha256 hex. 평문 코드 저장 금지.
  issued_by uuid not null references profiles (id), -- 발급 교사
  expires_at timestamptz not null,
  used_at timestamptz, -- 사용 또는 재발급으로 무효화된 시각
  created_at timestamptz not null default now()
);

create index student_link_codes_student_idx on student_link_codes (student_id);

-- 연결 코드는 로그인 자격 증명 — class_secrets와 동일 원칙:
-- RLS 활성 + 클라 정책 0개 = 전면 deny, service role(Edge Function)만 접근.
alter table student_link_codes enable row level security;
