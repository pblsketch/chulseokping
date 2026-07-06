import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dart:io';

import '../../data/datasources/beacon_advertise_data_source.dart';
import '../../data/datasources/beacon_scan_data_source.dart';
import '../../data/datasources/supabase_remote_data_source.dart';
import '../../data/datasources/teacher_beacon_prefs_store.dart';
import '../../data/repositories/attendance_repository_impl.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/consent_repository_impl.dart';
import '../../data/repositories/export_repository_impl.dart';
import '../../data/repositories/kiosk_repository_impl.dart';
import '../../data/repositories/roster_repository_impl.dart';
import '../../data/repositories/session_repository_impl.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/consent_repository.dart';
import '../../domain/repositories/export_repository.dart';
import '../../domain/repositories/kiosk_repository.dart';
import '../../domain/repositories/roster_repository.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/services/beacon_advertiser.dart';
import '../../domain/services/beacon_scanner.dart';
import '../../domain/services/teacher_beacon_store.dart';
import '../../domain/usecases/archive_class.dart';
import '../../domain/usecases/build_neis_exception_export.dart';
import '../../domain/usecases/check_in_by_ble.dart';
import '../../domain/usecases/check_in_by_pin.dart';
import '../../domain/usecases/complete_teacher_profile.dart';
import '../../domain/usecases/create_class.dart';
import '../../domain/usecases/confirm_guardian_consent.dart';
import '../../domain/usecases/confirm_password_reset.dart';
import '../../domain/usecases/check_in_by_qr.dart';
import '../../domain/usecases/create_students.dart';
import '../../domain/usecases/end_session.dart';
import '../../domain/usecases/issue_link_code.dart';
import '../../domain/usecases/parse_student_roster_input.dart';
import '../../domain/usecases/remove_student_from_class.dart';
import '../../domain/usecases/rename_class.dart';
import '../../domain/usecases/request_password_reset.dart';
import '../../domain/usecases/sign_in_with_link_code.dart';
import '../../domain/usecases/sign_up_teacher.dart';
import '../../domain/usecases/verify_teacher_email.dart';
import '../../domain/usecases/ensure_teacher_beacon.dart';
import '../../domain/usecases/get_active_session.dart';
import '../../domain/usecases/issue_kiosk_device.dart';
import '../../domain/usecases/set_student_pin.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/start_session.dart';
import '../../domain/usecases/sync_kiosk.dart';
import '../../domain/usecases/update_attendance_status.dart';
import '../../domain/usecases/watch_active_session.dart';
import '../../domain/usecases/watch_live_attendance.dart';
import '../../domain/usecases/watch_my_attendance.dart';

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

final kioskRepositoryProvider = Provider<KioskRepository>(
  (ref) => KioskRepositoryImpl(ref.watch(remoteDataSourceProvider)),
);

final beaconAdvertiserProvider = Provider<BeaconAdvertiser>(
  (ref) => BeaconAdvertiseDataSource(),
);

final beaconScannerProvider = Provider<BeaconScanner>(
  (ref) => BeaconScanDataSource(),
);

final teacherBeaconStoreProvider = Provider<TeacherBeaconStore>(
  (ref) => TeacherBeaconPrefsStore(),
);

final consentRepositoryProvider = Provider<ConsentRepository>(
  (ref) => ConsentRepositoryImpl(ref.watch(remoteDataSourceProvider)),
);

final exportRepositoryProvider = Provider<ExportRepository>(
  (ref) => ExportRepositoryImpl(),
);

/// 플랫폼 분기 (ST-2 Android 자동 / ST-3 iPhone 원탭) — 테스트에서 override.
final isAndroidProvider = Provider<bool>((ref) => Platform.isAndroid);

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

final watchActiveSessionProvider = Provider<WatchActiveSession>(
  (ref) => WatchActiveSession(ref.watch(sessionRepositoryProvider)),
);

final watchLiveAttendanceProvider = Provider<WatchLiveAttendance>(
  (ref) => WatchLiveAttendance(ref.watch(attendanceRepositoryProvider)),
);

final watchMyAttendanceProvider = Provider<WatchMyAttendance>(
  (ref) => WatchMyAttendance(ref.watch(attendanceRepositoryProvider)),
);

final updateAttendanceStatusProvider = Provider<UpdateAttendanceStatus>(
  (ref) => UpdateAttendanceStatus(ref.watch(attendanceRepositoryProvider)),
);

final checkInByQrProvider = Provider<CheckInByQr>(
  (ref) => CheckInByQr(ref.watch(attendanceRepositoryProvider)),
);

final checkInByBleProvider = Provider<CheckInByBle>(
  (ref) => CheckInByBle(ref.watch(attendanceRepositoryProvider)),
);

final issueKioskDeviceProvider = Provider<IssueKioskDevice>(
  (ref) => IssueKioskDevice(ref.watch(kioskRepositoryProvider)),
);

final ensureTeacherBeaconProvider = Provider<EnsureTeacherBeacon>(
  (ref) => EnsureTeacherBeacon(
    ref.watch(kioskRepositoryProvider),
    ref.watch(teacherBeaconStoreProvider),
  ),
);

final syncKioskProvider = Provider<SyncKiosk>(
  (ref) => SyncKiosk(ref.watch(kioskRepositoryProvider)),
);

final checkInByPinProvider = Provider<CheckInByPin>(
  (ref) => CheckInByPin(ref.watch(kioskRepositoryProvider)),
);

final setStudentPinProvider = Provider<SetStudentPin>(
  (ref) => SetStudentPin(ref.watch(rosterRepositoryProvider)),
);

final confirmGuardianConsentProvider = Provider<ConfirmGuardianConsent>(
  (ref) => ConfirmGuardianConsent(ref.watch(consentRepositoryProvider)),
);

final buildNeisExceptionExportProvider = Provider<BuildNeisExceptionExport>(
  (ref) => const BuildNeisExceptionExport(),
);

// ── M5 계정·온보딩 ──
final signUpTeacherProvider = Provider<SignUpTeacher>(
  (ref) => SignUpTeacher(ref.watch(authRepositoryProvider)),
);

final verifyTeacherEmailProvider = Provider<VerifyTeacherEmail>(
  (ref) => VerifyTeacherEmail(ref.watch(authRepositoryProvider)),
);

final completeTeacherProfileProvider = Provider<CompleteTeacherProfile>(
  (ref) => CompleteTeacherProfile(ref.watch(authRepositoryProvider)),
);

final requestPasswordResetProvider = Provider<RequestPasswordReset>(
  (ref) => RequestPasswordReset(ref.watch(authRepositoryProvider)),
);

final confirmPasswordResetProvider = Provider<ConfirmPasswordReset>(
  (ref) => ConfirmPasswordReset(ref.watch(authRepositoryProvider)),
);

final signInWithLinkCodeProvider = Provider<SignInWithLinkCode>(
  (ref) => SignInWithLinkCode(ref.watch(authRepositoryProvider)),
);

final createStudentsProvider = Provider<CreateStudents>(
  (ref) => CreateStudents(ref.watch(rosterRepositoryProvider)),
);

final issueLinkCodeProvider = Provider<IssueLinkCode>(
  (ref) => IssueLinkCode(ref.watch(rosterRepositoryProvider)),
);

final parseStudentRosterInputProvider = Provider<ParseStudentRosterInput>(
  (ref) => const ParseStudentRosterInput(),
);

// ── M6 학급 관리 ──
final createClassProvider = Provider<CreateClass>(
  (ref) => CreateClass(ref.watch(rosterRepositoryProvider)),
);

final renameClassProvider = Provider<RenameClass>(
  (ref) => RenameClass(ref.watch(rosterRepositoryProvider)),
);

final archiveClassProvider = Provider<ArchiveClass>(
  (ref) => ArchiveClass(ref.watch(rosterRepositoryProvider)),
);

final removeStudentFromClassProvider = Provider<RemoveStudentFromClass>(
  (ref) => RemoveStudentFromClass(ref.watch(rosterRepositoryProvider)),
);
