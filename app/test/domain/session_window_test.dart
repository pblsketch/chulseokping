import 'package:chulseokping_app/core/error/failure.dart';
import 'package:chulseokping_app/core/result/result.dart';
import 'package:chulseokping_app/domain/entities/session.dart';
import 'package:chulseokping_app/domain/repositories/session_repository.dart';
import 'package:chulseokping_app/domain/usecases/extend_session.dart';
import 'package:chulseokping_app/domain/usecases/start_session.dart';
import 'package:chulseokping_app/domain/value_objects/session_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSessionRepository extends Mock implements SessionRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(SessionType.homeroom);
    registerFallbackValue(SessionMode.byod);
  });

  late MockSessionRepository repository;

  final session = Session(
    id: 's1',
    classId: 'c1',
    teacherId: 't1',
    type: SessionType.homeroom,
    date: DateTime(2026, 7, 6),
    mode: SessionMode.byod,
    status: SessionStatus.active,
    startedAt: DateTime.utc(2026, 7, 6, 9),
  );

  setUp(() {
    repository = MockSessionRepository();
    when(
      () => repository.startSession(
        classId: any(named: 'classId'),
        type: any(named: 'type'),
        period: any(named: 'period'),
        mode: any(named: 'mode'),
        closeMinutes: any(named: 'closeMinutes'),
        autoLateMinutes: any(named: 'autoLateMinutes'),
      ),
    ).thenAnswer((_) async => Ok(session));
  });

  group('StartSession 시간창 (P0-1)', () {
    test('기본: 창 10분, 지각 off → close=10, autoLate=null', () async {
      await StartSession(
        repository,
      ).call(classId: 'c1', type: SessionType.homeroom, windowMinutes: 10);
      verify(
        () => repository.startSession(
          classId: 'c1',
          type: SessionType.homeroom,
          period: null,
          mode: SessionMode.byod,
          closeMinutes: 10,
          autoLateMinutes: null,
        ),
      ).called(1);
    });

    test('지각 on → close=창+유예(20분), autoLate=창', () async {
      await StartSession(repository).call(
        classId: 'c1',
        type: SessionType.homeroom,
        windowMinutes: 10,
        lateEnabled: true,
      );
      verify(
        () => repository.startSession(
          classId: 'c1',
          type: SessionType.homeroom,
          period: null,
          mode: SessionMode.byod,
          closeMinutes: 10 + StartSession.lateGraceMinutes,
          autoLateMinutes: 10,
        ),
      ).called(1);
    });

    test('수동 종료(창 null) → 지각 토글 무시, 둘 다 null (현행 동작)', () async {
      await StartSession(repository).call(
        classId: 'c1',
        type: SessionType.homeroom,
        lateEnabled: true, // 창이 없으면 판정 기준 시각이 없다
      );
      verify(
        () => repository.startSession(
          classId: 'c1',
          type: SessionType.homeroom,
          period: null,
          mode: SessionMode.byod,
          closeMinutes: null,
          autoLateMinutes: null,
        ),
      ).called(1);
    });

    test('창 범위 검증: 1~180분 밖은 ValidationFailure', () async {
      for (final minutes in [0, -5, 181]) {
        final result = await StartSession(repository).call(
          classId: 'c1',
          type: SessionType.homeroom,
          windowMinutes: minutes,
        );
        expect(
          result.failureOrNull,
          isA<ValidationFailure>(),
          reason: 'minutes=$minutes',
        );
      }
      verifyNever(
        () => repository.startSession(
          classId: any(named: 'classId'),
          type: any(named: 'type'),
          period: any(named: 'period'),
          mode: any(named: 'mode'),
          closeMinutes: any(named: 'closeMinutes'),
          autoLateMinutes: any(named: 'autoLateMinutes'),
        ),
      );
    });
  });

  group('ExtendSession', () {
    test('범위 밖 연장은 ValidationFailure', () async {
      final usecase = ExtendSession(repository);
      for (final minutes in [0, 61]) {
        final result = await usecase('s1', byMinutes: minutes);
        expect(result.failureOrNull, isA<ValidationFailure>());
      }
    });

    test('기본 +5분 위임', () async {
      when(
        () =>
            repository.extendSession(any(), byMinutes: any(named: 'byMinutes')),
      ).thenAnswer((_) async => Ok(session));

      final result = await ExtendSession(repository).call('s1');
      expect(result.isOk, isTrue);
      verify(() => repository.extendSession('s1', byMinutes: 5)).called(1);
    });
  });
}
