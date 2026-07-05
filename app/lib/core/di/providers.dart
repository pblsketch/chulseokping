import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/supabase_remote_data_source.dart';
import '../../data/repositories/attendance_repository_impl.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/roster_repository_impl.dart';
import '../../data/repositories/session_repository_impl.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/roster_repository.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/usecases/check_in_by_qr.dart';
import '../../domain/usecases/end_session.dart';
import '../../domain/usecases/get_active_session.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/start_session.dart';
import '../../domain/usecases/update_attendance_status.dart';
import '../../domain/usecases/watch_live_attendance.dart';

/// DI 와이어링 (ARCHITECTURE §2 core/di).
/// 테스트에서는 repository provider를 overrideWithValue로 대체한다.
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

final remoteDataSourceProvider = Provider<SupabaseRemoteDataSource>(
  (ref) => SupabaseRemoteDataSource(ref.watch(supabaseClientProvider)),
);

// ── Repositories ──
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(remoteDataSourceProvider)),
);

final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => SessionRepositoryImpl(ref.watch(remoteDataSourceProvider)),
);

final attendanceRepositoryProvider = Provider<AttendanceRepository>(
  (ref) => AttendanceRepositoryImpl(ref.watch(remoteDataSourceProvider)),
);

final rosterRepositoryProvider = Provider<RosterRepository>(
  (ref) => RosterRepositoryImpl(ref.watch(remoteDataSourceProvider)),
);

// ── Usecases ──
final signInProvider = Provider<SignIn>(
  (ref) => SignIn(ref.watch(authRepositoryProvider)),
);

final startSessionProvider = Provider<StartSession>(
  (ref) => StartSession(ref.watch(sessionRepositoryProvider)),
);

final endSessionProvider = Provider<EndSession>(
  (ref) => EndSession(ref.watch(sessionRepositoryProvider)),
);

final getActiveSessionProvider = Provider<GetActiveSession>(
  (ref) => GetActiveSession(ref.watch(sessionRepositoryProvider)),
);

final watchLiveAttendanceProvider = Provider<WatchLiveAttendance>(
  (ref) => WatchLiveAttendance(ref.watch(attendanceRepositoryProvider)),
);

final updateAttendanceStatusProvider = Provider<UpdateAttendanceStatus>(
  (ref) => UpdateAttendanceStatus(ref.watch(attendanceRepositoryProvider)),
);

final checkInByQrProvider = Provider<CheckInByQr>(
  (ref) => CheckInByQr(ref.watch(attendanceRepositoryProvider)),
);
