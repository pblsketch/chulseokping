import 'package:chulseokping_app/core/error/failure.dart';
import 'package:chulseokping_app/core/result/result.dart';
import 'package:chulseokping_app/domain/entities/user_profile.dart';
import 'package:chulseokping_app/domain/repositories/auth_repository.dart';
import 'package:chulseokping_app/domain/usecases/sign_in_with_link_code.dart';
import 'package:chulseokping_app/domain/value_objects/user_role.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late SignInWithLinkCode usecase;

  const profile = UserProfile(id: 'st1', role: UserRole.student, name: '학생');

  setUp(() {
    repository = MockAuthRepository();
    usecase = SignInWithLinkCode(repository);
  });

  test('표시형(하이픈·소문자·공백)을 서버 계약 형태로 정규화해 위임한다', () async {
    when(
      () => repository.signInWithLinkCode(any()),
    ).thenAnswer((_) async => const Ok(profile));

    final result = await usecase(' abcd-efgh-jklm ');
    expect(result.isOk, isTrue);
    verify(() => repository.signInWithLinkCode('ABCDEFGHJKLM')).called(1);
  });

  test('길이·금지 문자(I/O/0/1) 위반은 저장소 호출 없이 ValidationFailure', () async {
    for (final code in ['SHORT', 'ABCDEFGHJKL0', 'ABCDEFGHJKLI', '']) {
      final result = await usecase(code);
      expect(
        result.failureOrNull,
        isA<ValidationFailure>(),
        reason: 'code=$code',
      );
    }
    verifyZeroInteractions(repository);
  });
}
