import 'package:chulseokping_app/core/error/failure.dart';
import 'package:chulseokping_app/core/result/result.dart';
import 'package:chulseokping_app/domain/repositories/roster_repository.dart';
import 'package:chulseokping_app/domain/usecases/set_student_pin.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRosterRepository extends Mock implements RosterRepository {}

void main() {
  late MockRosterRepository repository;
  late SetStudentPin usecase;

  setUp(() {
    repository = MockRosterRepository();
    usecase = SetStudentPin(repository);
  });

  test('숫자 4~8자리 외에는 저장소 호출 없이 ValidationFailure', () async {
    for (final pin in ['12', '123456789', '12ab', '']) {
      final result = await usecase(studentId: 'st1', pin: pin);
      expect(
        result.failureOrNull,
        isA<ValidationFailure>(),
        reason: 'pin=$pin',
      );
    }
    verifyZeroInteractions(repository);
  });

  test('유효 PIN은 위임', () async {
    when(
      () => repository.setStudentPin(
        studentId: any(named: 'studentId'),
        pin: any(named: 'pin'),
      ),
    ).thenAnswer((_) async => const Ok(null));

    final result = await usecase(studentId: 'st1', pin: '123456');
    expect(result.isOk, isTrue);
    verify(
      () => repository.setStudentPin(studentId: 'st1', pin: '123456'),
    ).called(1);
  });
}
