import '../value_objects/session_type.dart';

/// 출석 세션 (조회/교시) — v1 출결 단위 (PRD §3).
class Session {
  const Session({
    required this.id,
    required this.classId,
    required this.teacherId,
    required this.type,
    required this.date,
    required this.mode,
    required this.status,
    required this.startedAt,
    this.period,
    this.endedAt,
    this.closeAt,
    this.autoLateAfterMinutes,
  }) : assert(
         type == SessionType.period ? period != null : period == null,
         'PERIOD 세션에만 교시가 있다',
       );

  final String id;
  final String classId;
  final String teacherId;
  final SessionType type;

  /// PERIOD일 때만 교시(1~N)
  final int? period;
  final DateTime date;
  final SessionMode mode;
  final SessionStatus status;
  final DateTime startedAt;
  final DateTime? endedAt;

  /// P0-1 수집 창 마감(선언적). null = 수동 종료까지 무기한.
  /// 판정 권위는 서버 — 이 값은 카운트다운 표시용.
  final DateTime? closeAt;

  /// 시작 후 N분 이후 체크인 = 지각 자동 판정. null = 자동 지각 없음.
  final int? autoLateAfterMinutes;
}
