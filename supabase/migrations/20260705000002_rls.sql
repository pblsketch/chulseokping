-- 출석핑 M0 RLS (PRD BE-4)
-- 원칙: 학생=본인 read / 교사=자기 class 범위 / attendance 쓰기=service role 전용(클라 정책 없음=deny).
-- class_secrets: 클라 정책 0개 — service role만 접근.

-- 헬퍼: security definer로 RLS 재귀 없이 소유/멤버십 판정
create function is_teacher_of_class(p_class_id uuid)
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from classes c
    where c.id = p_class_id and c.teacher_id = auth.uid()
  );
$$;

create function is_student_in_class(p_class_id uuid)
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from student_classes sc
    where sc.class_id = p_class_id and sc.student_id = auth.uid()
  );
$$;

-- 교사가 이 학생을 담당하는가(자기 class에 등록된 학생인가)
create function teaches_student(p_student_id uuid)
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1
    from student_classes sc
    join classes c on c.id = sc.class_id
    where sc.student_id = p_student_id and c.teacher_id = auth.uid()
  );
$$;

alter table schools enable row level security;
alter table profiles enable row level security;
alter table classes enable row level security;
alter table class_secrets enable row level security; -- 정책 없음 = 클라 전면 deny
alter table student_classes enable row level security;
alter table sessions enable row level security;
alter table kiosk_devices enable row level security;
alter table consents enable row level security;
alter table attendance_logs enable row level security;
alter table suspicious_flags enable row level security;

-- schools: 로그인 사용자 read (식별 정보 아님)
create policy schools_select on schools
  for select to authenticated using (true);

-- profiles: 본인 행 + 교사는 담당 학생
create policy profiles_select_own on profiles
  for select to authenticated using (id = auth.uid());
create policy profiles_select_teacher on profiles
  for select to authenticated using (teaches_student(id));
create policy profiles_insert_own on profiles
  for insert to authenticated with check (id = auth.uid());
create policy profiles_update_own on profiles
  for update to authenticated using (id = auth.uid());

-- classes: 교사=자기 class CRUD, 학생=소속 class read
create policy classes_teacher_all on classes
  for all to authenticated
  using (teacher_id = auth.uid())
  with check (teacher_id = auth.uid());
create policy classes_student_select on classes
  for select to authenticated using (is_student_in_class(id));

-- student_classes: 교사=자기 class 명단 관리, 학생=본인 행 read
create policy student_classes_teacher_all on student_classes
  for all to authenticated
  using (is_teacher_of_class(class_id))
  with check (is_teacher_of_class(class_id));
create policy student_classes_student_select on student_classes
  for select to authenticated using (student_id = auth.uid());

-- sessions: 교사=자기 class 세션 CRUD, 학생=소속 class 세션 read(활성 세션 감지용)
create policy sessions_teacher_all on sessions
  for all to authenticated
  using (is_teacher_of_class(class_id))
  with check (is_teacher_of_class(class_id) and teacher_id = auth.uid());
create policy sessions_student_select on sessions
  for select to authenticated using (is_student_in_class(class_id));

-- kiosk_devices: 교사만(자기 class). 학생 접근 없음. device_token/beacon_secret은 교사 소유 자산.
create policy kiosk_devices_teacher_all on kiosk_devices
  for all to authenticated
  using (is_teacher_of_class(class_id))
  with check (is_teacher_of_class(class_id) and teacher_id = auth.uid());

-- consents: 교사=담당 학생 동의 확인·기록, 학생=본인 read
create policy consents_teacher_select on consents
  for select to authenticated using (teaches_student(student_id));
create policy consents_teacher_insert on consents
  for insert to authenticated
  with check (teaches_student(student_id) and guardian_confirmed_by = auth.uid());
create policy consents_student_select on consents
  for select to authenticated using (student_id = auth.uid());

-- attendance_logs: SELECT만 허용(학생=본인, 교사=자기 class).
-- INSERT/UPDATE/DELETE 정책 없음 → 클라 전면 deny. 쓰기는 Edge Function(service role) 전용 (BE-0).
create policy attendance_logs_student_select on attendance_logs
  for select to authenticated using (student_id = auth.uid());
create policy attendance_logs_teacher_select on attendance_logs
  for select to authenticated using (is_teacher_of_class(class_id));

-- suspicious_flags: 교사=자기 class read + reviewed 갱신. 생성은 Edge Function 전용.
create policy suspicious_flags_teacher_select on suspicious_flags
  for select to authenticated
  using (session_id is not null and is_teacher_of_class(
    (select s.class_id from sessions s where s.id = suspicious_flags.session_id)
  ));
create policy suspicious_flags_teacher_update on suspicious_flags
  for update to authenticated
  using (session_id is not null and is_teacher_of_class(
    (select s.class_id from sessions s where s.id = suspicious_flags.session_id)
  ));
