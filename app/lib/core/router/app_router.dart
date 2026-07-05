import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/value_objects/user_role.dart';
import '../../presentation/kiosk/kiosk_shell.dart';
import '../../presentation/kiosk/pin_pad_page.dart';
import '../../presentation/shared/auth_controller.dart';
import '../../presentation/shared/login_page.dart';
import '../../presentation/student/scan_page.dart';
import '../../presentation/student/student_shell.dart';
import '../../presentation/teacher/ledger_page.dart';
import '../../presentation/teacher/roster_page.dart';
import '../../presentation/teacher/session_page.dart';
import '../../presentation/teacher/teacher_shell.dart';

/// 역할 기반 라우팅 (ARCHITECTURE §5).
/// - student / teacher = 인증 사용자 역할 (Supabase Auth + profiles.role)
/// - kiosk = 사용자 역할이 아니라 "기기 모드" (M2에서 device_token 등록 진입)
final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);

  String homeOf(UserRole role) =>
      role == UserRole.teacher ? '/teacher' : '/student';

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final location = state.matchedLocation;
      // 키오스크는 사용자 역할이 아니라 "기기 모드" — 로그인 없이 진입 (ARCHITECTURE §5)
      if (location.startsWith('/kiosk')) return null;
      if (auth.isLoading) return null;
      final profile = auth.value;
      final atLogin = location == '/login';
      if (profile == null) return atLogin ? null : '/login';
      if (atLogin) return homeOf(profile.role);
      // 역할 경계: 학생이 교사 경로 접근(또는 반대) 시 자기 홈으로
      if (profile.role == UserRole.student && location.startsWith('/teacher')) {
        return '/student';
      }
      if (profile.role == UserRole.teacher && location.startsWith('/student')) {
        return '/teacher';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/teacher',
        builder: (context, state) => const TeacherShell(),
        routes: [
          GoRoute(
            path: 'session/:sessionId',
            builder: (context, state) => SessionPage(
              sessionId: state.pathParameters['sessionId']!,
              classId: state.uri.queryParameters['classId'] ?? '',
            ),
          ),
          GoRoute(
            path: 'roster/:classId',
            builder: (context, state) => RosterPage(
              classId: state.pathParameters['classId']!,
              className: state.uri.queryParameters['name'] ?? '학급',
            ),
          ),
          GoRoute(
            path: 'ledger/:classId',
            builder: (context, state) => LedgerPage(
              classId: state.pathParameters['classId']!,
              className: state.uri.queryParameters['name'] ?? '학급',
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/student',
        builder: (context, state) => const StudentShell(),
        routes: [
          GoRoute(
            path: 'scan',
            builder: (context, state) => ScanPage(
              sessionId: state.uri.queryParameters['sessionId'] ?? '',
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/kiosk',
        builder: (context, state) => const KioskShell(),
        routes: [
          GoRoute(
            path: 'pin',
            builder: (context, state) => PinPadPage(
              sessionId: state.uri.queryParameters['sessionId'] ?? '',
              deviceToken: state.uri.queryParameters['deviceToken'] ?? '',
            ),
          ),
        ],
      ),
    ],
  );
});
