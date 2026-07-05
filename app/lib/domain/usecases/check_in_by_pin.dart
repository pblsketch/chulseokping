import '../../core/error/failure.dart';
import '../../core/result/result.dart';
import '../entities/attendance_record.dart';
import '../repositories/kiosk_repository.dart';

/// KO-4: 키오스크 PIN 체크인. 형식 선검증 후 서버(check_in_pin)가 정본 검증.
class CheckInByPin {
  const CheckInByPin(this._repository);

  final KioskRepository _repository;

  Future<Result<AttendanceRecord>> call({
    required String deviceToken,
    required String sessionId,
    required String studentNumber,
    required String pin,
  }) {
    if (studentNumber.trim().isEmpty) {
      return Future.value(const Err(ValidationFailure('학번을 입력해 주세요')));
    }
    if (pin.length < 4) {
      return Future.value(const Err(ValidationFailure('PIN은 4자리 이상이에요')));
    }
    return _repository.checkInByPin(
      deviceToken: deviceToken,
      sessionId: sessionId,
      studentNumber: studentNumber.trim(),
      pin: pin,
    );
  }
}
