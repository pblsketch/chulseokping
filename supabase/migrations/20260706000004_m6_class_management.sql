-- 출석핑 M6: 학급 관리 (생성 경로 강제 + 보관)
-- ⚠ 함정 차단: 학급 QR secret(class_secrets)은 service role만 만들 수 있으므로,
-- 클라이언트가 classes를 직접 INSERT하면 secret 없는 학급(QR 조용히 실패)이 생긴다.
-- → 클라 INSERT 정책을 제거해 create_class Edge Function(동시 발급)만이 유일한 생성 경로가 되게 한다.

-- 학급 보관: 학년도 종료/폐급. 삭제 대신 보관 — 세션·출결 이력은 나이스 근거라 보존(FK도 삭제를 막는다).
alter table classes add column archived_at timestamptz;

-- 기존 FOR ALL 정책을 INSERT 없는 정책 3개로 분리
drop policy classes_teacher_all on classes;

create policy classes_teacher_select on classes
  for select to authenticated using (teacher_id = auth.uid());
create policy classes_teacher_update on classes
  for update to authenticated
  using (teacher_id = auth.uid())
  with check (teacher_id = auth.uid());
-- DELETE는 빈 학급만 실질 가능(sessions/attendance_logs FK가 이력 있는 학급 삭제를 차단)
create policy classes_teacher_delete on classes
  for delete to authenticated using (teacher_id = auth.uid());
