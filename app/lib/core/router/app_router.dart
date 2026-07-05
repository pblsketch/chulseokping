import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/kiosk/kiosk_shell.dart';
import '../../presentation/shared/role_select_page.dart';
import '../../presentation/student/student_shell.dart';
import '../../presentation/teacher/teacher_shell.dart';

/// 역할 기반 라우팅 (ARCHITECTURE §5).
/// - student / teacher = 인증 사용자 역할
/// - kiosk = 사용자 역할이 아니라 "기기 모드" (device_token 등록 시 진입)
/// M0 스캐폴드: 인증 연동 전이므로 역할 선택 화면에서 수동 진입.
enum AppRole { none, student, teacher, kiosk }

class AppRoleNotifier extends Notifier<AppRole> {
  @override
  AppRole build() => AppRole.none;

  void set(AppRole role) => state = role;
}

final appRoleProvider = NotifierProvider<AppRoleNotifier, AppRole>(
  AppRoleNotifier.new,
);

final appRouterProvider = Provider<GoRouter>((ref) {
  final role = ref.watch(appRoleProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // M1에서 Supabase Auth 세션 기반 redirect로 교체한다.
      if (role == AppRole.none && state.matchedLocation != '/') return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const RoleSelectPage()),
      GoRoute(
        path: '/student',
        builder: (context, state) => const StudentShell(),
      ),
      GoRoute(path: '/kiosk', builder: (context, state) => const KioskShell()),
      GoRoute(
        path: '/teacher',
        builder: (context, state) => const TeacherShell(),
      ),
    ],
  );
});
