-- 출석핑 로컬 seed — 전부 더미/합성 데이터 (실 학생 PII 절대 금지, AGENTS.md §10)
-- 고정 UUID: 통합 테스트(supabase/tests)가 참조한다.

-- 더미 auth 사용자 (로컬 전용, password123)
-- 주의: GoTrue는 토큰 컬럼이 NULL이면 로그인 스캔에 실패한다 → 빈 문자열로 채우고 identities도 생성.
do $$
declare
  u record;
begin
  for u in
    select * from (values
      ('11111111-1111-1111-1111-111111111111'::uuid, 'dummy-teacher@example.com'),
      ('22222222-2222-2222-2222-222222222222'::uuid, 'dummy-student1@example.com'),
      ('33333333-3333-3333-3333-333333333333'::uuid, 'dummy-student2@example.com'),
      ('44444444-4444-4444-4444-444444444444'::uuid, 'dummy-student3@example.com'),
      ('55555555-5555-5555-5555-555555555555'::uuid, 'dummy-student4@example.com'),
      ('66666666-6666-6666-6666-666666666666'::uuid, 'dummy-student5@example.com')
    ) as t(id, email)
  loop
    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
      raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
      confirmation_token, recovery_token, email_change, email_change_token_new,
      email_change_token_current, phone_change, phone_change_token, reauthentication_token
    ) values (
      '00000000-0000-0000-0000-000000000000', u.id, 'authenticated', 'authenticated',
      u.email, crypt('password123', gen_salt('bf')), now(),
      '{"provider":"email","providers":["email"]}', '{}', now(), now(),
      '', '', '', '', '', '', '', ''
    );
    insert into auth.identities (
      id, provider_id, user_id, identity_data, provider,
      last_sign_in_at, created_at, updated_at
    ) values (
      gen_random_uuid(), u.id::text, u.id,
      jsonb_build_object('sub', u.id::text, 'email', u.email, 'email_verified', true),
      'email', now(), now(), now()
    );
  end loop;
end $$;

insert into schools (id, name)
values ('99999999-9999-9999-9999-999999999999', '더미초등학교');

insert into profiles (id, role, name, student_number, school_id)
values
  ('11111111-1111-1111-1111-111111111111', 'teacher', '더미교사', null,
   '99999999-9999-9999-9999-999999999999'),
  ('22222222-2222-2222-2222-222222222222', 'student', '더미학생일', '10101',
   '99999999-9999-9999-9999-999999999999'),
  ('33333333-3333-3333-3333-333333333333', 'student', '더미학생이', '10102',
   '99999999-9999-9999-9999-999999999999'),
  ('44444444-4444-4444-4444-444444444444', 'student', '더미학생삼', '10103',
   '99999999-9999-9999-9999-999999999999'),
  ('55555555-5555-5555-5555-555555555555', 'student', '더미학생사', '10104',
   '99999999-9999-9999-9999-999999999999'),
  ('66666666-6666-6666-6666-666666666666', 'student', '더미학생오', '10105',
   '99999999-9999-9999-9999-999999999999');

insert into classes (id, school_id, teacher_id, name, invite_code)
values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '99999999-9999-9999-9999-999999999999',
        '11111111-1111-1111-1111-111111111111', '더미 1학년 1반', 'DUMMY1');

-- TOTP secret (RFC 6238 테스트 키 hex — 더미 전용)
insert into class_secrets (class_id, qr_secret)
values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        '3132333435363738393031323334353637383930');

-- 명단: 학생1(동의O)·학생2(동의X)·학생4(동의O)·학생5(동의O)는 멤버, 학생3은 비멤버(동의O)
insert into student_classes (student_id, class_id)
values
  ('22222222-2222-2222-2222-222222222222', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  ('33333333-3333-3333-3333-333333333333', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  ('55555555-5555-5555-5555-555555555555', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  ('66666666-6666-6666-6666-666666666666', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');

-- 동의: 학생2는 의도적으로 미동의(동의 가드 테스트용)
insert into consents (student_id, policy_version, guardian_confirmed_by)
values
  ('22222222-2222-2222-2222-222222222222', 'v1', '11111111-1111-1111-1111-111111111111'),
  ('44444444-4444-4444-4444-444444444444', 'v1', '11111111-1111-1111-1111-111111111111'),
  ('55555555-5555-5555-5555-555555555555', 'v1', '11111111-1111-1111-1111-111111111111'),
  ('66666666-6666-6666-6666-666666666666', 'v1', '11111111-1111-1111-1111-111111111111');

insert into kiosk_devices (id, class_id, teacher_id, device_token, beacon_major, beacon_secret)
values ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        '11111111-1111-1111-1111-111111111111', 'dummy-kiosk-token-001', 101,
        '3132333435363738393031323334353637383930');

-- 활성 세션 (조회) — 통합 테스트 대상
insert into sessions (id, class_id, teacher_id, type, mode, status)
values ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        '11111111-1111-1111-1111-111111111111', 'HOMEROOM', 'KIOSK', 'ACTIVE');
