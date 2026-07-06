import '../../core/error/failure.dart';
import '../../core/result/result.dart';
import '../entities/session.dart';
import '../repositories/session_repository.dart';
import '../value_objects/session_type.dart';

/// TE-1: 세션 시작. PERIOD면 교시(1~15) 필수 (PRD §3).
/// P0-1 시간창: windowMinutes = 정시 출석 인정 시간(null = 수동 종료).
/// lateEnabled면 대학 관행(10분 출석/이후 지각)처럼 지각 수집 구간을
/// [windowMinutes, windowMinutes + lateGraceMinutes)로 덧붙인다.
class StartSession {
  const StartSession(this._repository);

  final SessionRepository _repository;

  /// 지각 수집 유예 — 대학 데팍토 표준(시작 10~30분 지각)의 K-12 번안
  static const lateGraceMinutes = 20;

  Future<Result<Session>> call({
    required String classId,
    required SessionType type,
    int? period,
    SessionMode mode = SessionMode.byod,
    int? windowMinutes,
    bool lateEnabled = false,
  }) {
    if (type == SessionType.period &&
        (period == null || period < 1 || period > 15)) {
      return Future.value(const Err(ValidationFailure('교시를 선택해 주세요 (1~15)')));
    }
    if (type == SessionType.homeroom && period != null) {
      return Future.value(const Err(ValidationFailure('조회 세션에는 교시가 없어요')));
    }
    if (windowMinutes != null && (windowMinutes < 1 || windowMinutes > 180)) {
      return Future.value(const Err(ValidationFailure('수집 시간은 1~180분이에요')));
    }

    // 수동 종료(창 없음)에는 자동 지각도 없다 — 지각 판정 기준 시각이 없으므로
    final effectiveLate = lateEnabled && windowMinutes != null;
    return _repository.startSession(
      classId: classId,
      type: type,
      period: period,
      mode: mode,
      closeMinutes: windowMinutes == null
          ? null
          : (effectiveLate ? windowMinutes + lateGraceMinutes : windowMinutes),
      autoLateMinutes: effectiveLate ? windowMinutes : null,
    );
  }
}
