import 'package:chulseokping_app/core/error/failure.dart';
import 'package:chulseokping_app/core/result/result.dart';
import 'package:chulseokping_app/domain/repositories/auth_repository.dart';
import 'package:chulseokping_app/domain/usecases/confirm_password_reset.dart';
import 'package:chulseokping_app/domain/usecases/sign_up_teacher.dart';
import 'package:chulseokping_app/domain/usecases/verify_teacher_email.dart';
import 'package:chulseokping_app/domain/value_objects/sign_up_outcome.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;

  setUp(() {
    repository = MockAuthRepository();
  });

  group('SignUpTeacher', () {
    test('이메일 형식·비밀번호 8자 미만은 저장소 호출 없이 ValidationFailure', () async {
      final usecase = SignUpTeacher(repository);
      final badEmail = await usecase(
        email: 'not-an-email',
        password: 'password1',
      );
      expect(badEmail.failureOrNull, isA<ValidationFailure>());

      final shortPw = await usecase(email: 't@school.kr', password: 'short');
      expect(shortPw.failureOrNull, isA<ValidationFailure>());
      verifyZeroInteractions(repository);
    });

    test('유효 입력은 trim 후 위임', () async {
      when(
        () => repository.signUpTeacher(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Ok(SignUpOutcome.verificationEmailSent));

      final usecase = SignUpTeacher(repository);
      final result = await usecase(
        email: ' t@school.kr ',
        password: 'password1',
      );
      expect(result.valueOrNull, SignUpOutcome.verificationEmailSent);
      verify(
        () => repository.signUpTeacher(
          email: 't@school.kr',
          password: 'password1',
        ),
      ).called(1);
    });
  });

  group('VerifyTeacherEmail', () {
    test('6자리 숫자가 아니면 ValidationFailure', () async {
      final usecase = VerifyTeacherEmail(repository);
      for (final token in ['12345', '1234567', 'abcdef', '']) {
        final result = await usecase(email: 't@school.kr', token: token);
        expect(
          result.failureOrNull,
          isA<ValidationFailure>(),
          reason: 'token=$token',
        );
      }
      verifyZeroInteractions(repository);
    });
  });

  group('ConfirmPasswordReset', () {
    test('OTP·새 비밀번호 선검증', () async {
      final usecase = ConfirmPasswordReset(repository);
      final badToken = await usecase(
        email: 't@school.kr',
        token: 'abc',
        newPassword: 'password1',
      );
      expect(badToken.failureOrNull, isA<ValidationFailure>());

      final shortPw = await usecase(
        email: 't@school.kr',
        token: '123456',
        newPassword: 'short',
      );
      expect(shortPw.failureOrNull, isA<ValidationFailure>());
      verifyZeroInteractions(repository);
    });
  });
}
