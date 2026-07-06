import 'package:chulseokping_app/core/error/failure.dart';
import 'package:chulseokping_app/core/result/result.dart';
import 'package:chulseokping_app/domain/entities/new_student_entry.dart';
import 'package:chulseokping_app/domain/repositories/roster_repository.dart';
import 'package:chulseokping_app/domain/usecases/create_students.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRosterRepository extends Mock implements RosterRepository {}

void main() {
  late MockRosterRepository repository;
  late CreateStudents usecase;

  const entry = NewStudentEntry(name: '김철수', studentNumber: '10101');

  setUp(() {
    repository = MockRosterRepository();
    usecase = CreateStudents(repository);
  });

  test('빈 목록·상한 초과는 저장소 호출 없이 ValidationFailure', () async {
    final empty = await usecase(classId: 'c1', entries: const []);
    expect(empty.failureOrNull, isA<ValidationFailure>());

    final tooMany = await usecase(
      classId: 'c1',
      entries: List.filled(CreateStudents.maxPerCall + 1, entry),
    );
    expect(tooMany.failureOrNull, isA<ValidationFailure>());
    verifyZeroInteractions(repository);
  });

  test('유효 입력은 위임', () async {
    when(
      () => repository.createStudents(
        classId: any(named: 'classId'),
        entries: any(named: 'entries'),
      ),
    ).thenAnswer((_) async => const Ok([]));

    final result = await usecase(classId: 'c1', entries: const [entry]);
    expect(result.isOk, isTrue);
    verify(
      () => repository.createStudents(classId: 'c1', entries: const [entry]),
    ).called(1);
  });
}
