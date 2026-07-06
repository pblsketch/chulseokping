import 'package:chulseokping_app/core/error/failure.dart';
import 'package:chulseokping_app/core/result/result.dart';
import 'package:chulseokping_app/domain/entities/class_room.dart';
import 'package:chulseokping_app/domain/repositories/roster_repository.dart';
import 'package:chulseokping_app/domain/usecases/archive_class.dart';
import 'package:chulseokping_app/domain/usecases/create_class.dart';
import 'package:chulseokping_app/domain/usecases/remove_student_from_class.dart';
import 'package:chulseokping_app/domain/usecases/rename_class.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRosterRepository extends Mock implements RosterRepository {}

void main() {
  late MockRosterRepository repository;

  const classRoom = ClassRoom(
    id: 'c1',
    teacherId: 't1',
    name: '1학년 3반',
    inviteCode: 'ABCD2345',
  );

  setUp(() {
    repository = MockRosterRepository();
  });

  group('CreateClass', () {
    test('빈 이름·30자 초과는 저장소 호출 없이 ValidationFailure', () async {
      final usecase = CreateClass(repository);
      for (final name in ['', '   ', 'ㄱ' * 31]) {
        final result = await usecase(name);
        expect(
          result.failureOrNull,
          isA<ValidationFailure>(),
          reason: 'name="$name"',
        );
      }
      verifyZeroInteractions(repository);
    });

    test('유효 이름은 trim 후 위임', () async {
      when(
        () => repository.createClass(any()),
      ).thenAnswer((_) async => const Ok(classRoom));

      final result = await CreateClass(repository).call(' 1학년 3반 ');
      expect(result.valueOrNull?.name, '1학년 3반');
      verify(() => repository.createClass('1학년 3반')).called(1);
    });
  });

  group('RenameClass', () {
    test('이름 검증은 CreateClass와 동일 규칙', () async {
      final usecase = RenameClass(repository);
      final result = await usecase(classId: 'c1', name: '');
      expect(result.failureOrNull, isA<ValidationFailure>());
      verifyZeroInteractions(repository);
    });

    test('유효 입력은 위임', () async {
      when(
        () => repository.renameClass(
          classId: any(named: 'classId'),
          name: any(named: 'name'),
        ),
      ).thenAnswer((_) async => const Ok(null));

      final result = await RenameClass(
        repository,
      ).call(classId: 'c1', name: '2학년 1반');
      expect(result.isOk, isTrue);
      verify(
        () => repository.renameClass(classId: 'c1', name: '2학년 1반'),
      ).called(1);
    });
  });

  test('ArchiveClass·RemoveStudentFromClass는 위임', () async {
    when(
      () => repository.archiveClass(any()),
    ).thenAnswer((_) async => const Ok(null));
    when(
      () => repository.removeStudentFromClass(
        classId: any(named: 'classId'),
        studentId: any(named: 'studentId'),
      ),
    ).thenAnswer((_) async => const Ok(null));

    expect((await ArchiveClass(repository).call('c1')).isOk, isTrue);
    expect(
      (await RemoveStudentFromClass(
        repository,
      ).call(classId: 'c1', studentId: 'st1')).isOk,
      isTrue,
    );
    verify(() => repository.archiveClass('c1')).called(1);
    verify(
      () => repository.removeStudentFromClass(classId: 'c1', studentId: 'st1'),
    ).called(1);
  });
}
