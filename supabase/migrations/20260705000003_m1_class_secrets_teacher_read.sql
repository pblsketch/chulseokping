-- M1: 교사가 자기 학급의 TOTP secret을 읽어 회전 QR을 표시한다 (KO-2/BYOD).
-- 학생은 여전히 접근 불가(정책 없음). 쓰기는 계속 service role 전용.
create policy class_secrets_teacher_select on class_secrets
  for select to authenticated using (is_teacher_of_class(class_id));
