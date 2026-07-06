import '../../core/error/failure.dart';
import '../../core/result/result.dart';
import '../../domain/entities/session.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/value_objects/session_type.dart';
import '../datasources/supabase_remote_data_source.dart';
import 'failure_mapper.dart';

class SessionRepositoryImpl implements SessionRepository {
  const SessionRepositoryImpl(this._remote);

  final SupabaseRemoteDataSource _remote;

  @override
  Future<Result<Session>> startSession({
    required String classId,
    required SessionType type,
    int? period,
    required SessionMode mode,
    int? closeMinutes,
    int? autoLateMinutes,
  }) async {
    try {
      final teacherId = _remote.currentUserId;
      if (teacherId == null) return const Err(AuthFailure());
      final dto = await _remote.startSession(
        classId: classId,
        teacherId: teacherId,
        type: type.wireName,
        period: period,
        mode: mode.wireName,
        closeMinutes: closeMinutes,
        autoLateMinutes: autoLateMinutes,
      );
      return Ok(dto.toEntity());
    } catch (e) {
      return Err(mapToFailure(e));
    }
  }

  @override
  Future<Result<Session>> extendSession(
    String sessionId, {
    required int byMinutes,
  }) async {
    try {
      final dto = await _remote.extendSession(sessionId, byMinutes: byMinutes);
      return Ok(dto.toEntity());
    } catch (e) {
      return Err(mapToFailure(e));
    }
  }

  @override
  Future<Result<Session>> endSession(String sessionId) async {
    try {
      final dto = await _remote.endSession(sessionId);
      return Ok(dto.toEntity());
    } catch (e) {
      return Err(mapToFailure(e));
    }
  }

  @override
  Future<Result<Session?>> activeSessionFor(String classId) async {
    try {
      final dto = await _remote.activeSessionFor(classId);
      return Ok(dto?.toEntity());
    } catch (e) {
      return Err(mapToFailure(e));
    }
  }

  @override
  Stream<Session?> watchActiveSession(String classId) {
    return _remote.watchActiveSession(classId).map((dto) => dto?.toEntity());
  }

  @override
  Future<Result<List<Session>>> monthlySessions({
    required String classId,
    required int year,
    required int month,
  }) async {
    try {
      final dtos = await _remote.sessionsBetween(
        classId: classId,
        startInclusive: DateTime(year, month, 1),
        endInclusive: DateTime(year, month + 1, 0),
      );
      return Ok(dtos.map((dto) => dto.toEntity()).toList());
    } catch (e) {
      return Err(mapToFailure(e));
    }
  }

  @override
  Future<Result<String>> classSecret(String classId) async {
    try {
      final secret = await _remote.classSecret(classId);
      if (secret == null) {
        return const Err(ValidationFailure('학급 QR 설정을 찾을 수 없어요'));
      }
      return Ok(secret);
    } catch (e) {
      return Err(mapToFailure(e));
    }
  }
}
