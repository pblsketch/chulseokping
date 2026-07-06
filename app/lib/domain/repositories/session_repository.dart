import '../../core/result/result.dart';
import '../entities/session.dart';
import '../value_objects/session_type.dart';

abstract interface class SessionRepository {
  /// P0-1: closeMinutes/autoLateMinutes는 서버 started_at 기준으로 창을 만든다
  /// (클라 시계 불신 — close_at = 서버 started_at + closeMinutes).
  Future<Result<Session>> startSession({
    required String classId,
    required SessionType type,
    int? period,
    required SessionMode mode,
    int? closeMinutes,
    int? autoLateMinutes,
  });

  Future<Result<Session>> endSession(String sessionId);

  /// P0-1: 수집 창 연장 — close_at을 현재 값에서 byMinutes만큼 뒤로.
  Future<Result<Session>> extendSession(
    String sessionId, {
    required int byMinutes,
  });

  /// 학생앱: 소속 학급의 활성 세션 감지
  Future<Result<Session?>> activeSessionFor(String classId);

  /// 학생앱: 활성 세션 실시간 감지 (Realtime). 교사가 세션을 종료·재시작해도
  /// 화면을 새로고침하지 않아도 최신 세션으로 갱신된다.
  Stream<Session?> watchActiveSession(String classId);

  /// 교사 전용: 회전 QR 표시용 TOTP secret (RLS가 교사=자기 학급으로 제한).
  /// 검증은 항상 서버가 한다 — 이 값은 표시용 코드 생성에만 쓴다.
  Future<Result<String>> classSecret(String classId);

  /// TE-4: 월별 일람표용 — 해당 월의 세션 목록(교시 라벨·날짜 매핑 원천).
  Future<Result<List<Session>>> monthlySessions({
    required String classId,
    required int year,
    required int month,
  });
}
