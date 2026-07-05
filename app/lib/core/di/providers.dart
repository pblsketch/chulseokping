import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dart:io';

import '../../data/datasources/beacon_advertise_data_source.dart';
import '../../data/datasources/beacon_scan_data_source.dart';
import '../../data/datasources/supabase_remote_data_source.dart';
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
import '../../domain/usecases/build_neis_exception_export.dart';
import '../../domain/usecases/check_in_by_ble.dart';
import '../../domain/usecases/check_in_by_pin.dart';
import '../../domain/usecases/confirm_guardian_consent.dart';
import '../../domain/usecases/check_in_by_qr.dart';
import '../../domain/usecases/end_session.dart';
import '../../domain/usecases/get_active_session.dart';
import '../../domain/usecases/issue_kiosk_device.dart';
import '../../domain/usecases/set_student_pin.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/start_session.dart';
import '../../domain/usecases/sync_kiosk.dart';
import '../../domain/usecases/update_attendance_status.dart';
import '../../domain/usecases/watch_active_session.dart';
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

final kioskRepositoryProvider = Provider<KioskRepository>(
  (ref) => KioskRepositoryImpl(ref.watch(remoteDataSourceProvider)),
);

final beaconAdvertiserProvider = Provider<BeaconAdvertiser>(
  (ref) => BeaconAdvertiseDataSource(),
);

final beaconScannerProvider = Provider<BeaconScanner>(
  (ref) => BeaconScanDataSource(),
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
