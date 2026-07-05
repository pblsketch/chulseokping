import '../value_objects/user_role.dart';

/// 로그인 사용자 프로필 (profiles 행).
class UserProfile {
  const UserProfile({
    required this.id,
    required this.role,
    required this.name,
    this.studentNumber,
  });

  final String id;
  final UserRole role;
  final String name;
  final String? studentNumber;
}
