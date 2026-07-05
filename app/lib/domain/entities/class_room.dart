/// 학급. TOTP secret은 서버 전용(class_secrets)이라 entity에 없다.
class ClassRoom {
  const ClassRoom({
    required this.id,
    required this.teacherId,
    required this.name,
    required this.inviteCode,
    this.schoolId,
  });

  final String id;
  final String teacherId;
  final String name;
  final String inviteCode;
  final String? schoolId;
}
