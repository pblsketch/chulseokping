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
}
