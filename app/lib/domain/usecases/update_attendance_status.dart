import '../../core/error/failure.dart';
import '../../core/result/result.dart';
import '../entities/attendance_record.dart';
import '../repositories/attendance_repository.dart';
import '../value_objects/absence_reason.dart';
import '../value_objects/attendance_status.dart';

/// TE-3: 교사 수동 수정. 2축 모델을 클라이언트에서도 선검증한다(정본은 서버).
class UpdateAttendanceStatus {
  const UpdateAttendanceStatus(this._repository);

  final AttendanceRepository _repository;

  Future<Result<AttendanceRecord>> call({
    String? recordId,
    String? sessionId,
    String? studentId,
    required AttendanceStatus status,
    AbsenceReason? reason,
    RecognizedCode? reasonCode,
    String? reasonDetail,
  }) {
    final validation = _validate(
      recordId: recordId,
      sessionId: sessionId,
      studentId: studentId,
      status: status,
      reason: reason,
      reasonCode: reasonCode,
    );
    if (validation != null) return Future.value(Err(validation));

    if (recordId != null) {
      return _repository.updateStatus(
        recordId: recordId,
        status: status,
        reason: reason,
        reasonCode: reasonCode,
        reasonDetail: reasonDetail,
      );
    }
    return _repository.markManual(
      sessionId: sessionId!,
      studentId: studentId!,
      status: status,
      reason: reason,
      reasonCode: reasonCode,
      reasonDetail: reasonDetail,
    );
  }

  Failure? _validate({
    required String? recordId,
    required String? sessionId,
    required String? studentId,
    required AttendanceStatus status,
    required AbsenceReason? reason,
    required RecognizedCode? reasonCode,
  }) {
    if (recordId == null && (sessionId == null || studentId == null)) {
      return const ValidationFailure('수정할 기록 또는 학생·세션을 지정해 주세요');
    }
    if (status == AttendanceStatus.present && reason != null) {
      return const ValidationFailure('출석에는 사유를 붙이지 않아요');
    }
    if (status != AttendanceStatus.present && reason == null) {
      return const ValidationFailure('사유를 선택해 주세요 (출석인정/질병/미인정/기타)');
    }
    if (reasonCode != null && reason != AbsenceReason.recognized) {
      return const ValidationFailure('세부 사유는 출석인정에만 붙어요');
    }
    return null;
  }
}
