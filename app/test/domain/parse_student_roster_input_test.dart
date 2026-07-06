import 'package:chulseokping_app/domain/usecases/parse_student_roster_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = ParseStudentRosterInput();

  test('공백/탭/쉼표 구분과 빈 줄을 허용한다', () {
    final parsed = parser.call('''
10101 김철수

10102\t이영희
10103,박민수
''');
    expect(parsed.hasErrors, isFalse);
    expect(parsed.entries, hasLength(3));
    expect(parsed.entries[0].name, '김철수');
    expect(parsed.entries[0].studentNumber, '10101');
    expect(parsed.entries[1].name, '이영희');
    expect(parsed.entries[2].name, '박민수');
  });

  test('복합 이름은 나머지 토큰을 이어 붙인다', () {
    final parsed = parser.call('10101 남궁 민수');
    expect(parsed.entries.single.name, '남궁 민수');
  });

  test('guardianConsented가 전 행에 반영된다', () {
    final parsed = parser.call('10101 김철수', guardianConsented: true);
    expect(parsed.entries.single.guardianConsented, isTrue);
  });

  test('행 단위 오류: 토큰 부족·비숫자 학번·중복 학번', () {
    final parsed = parser.call('''
10101 김철수
이름만
abc 이영희
10101 중복학번
''');
    expect(parsed.entries, hasLength(1));
    expect(parsed.errors, hasLength(3));
    expect(parsed.errors[0], contains('2행'));
    expect(parsed.errors[1], contains('3행'));
    expect(parsed.errors[2], contains('4행'));
  });

  test('빈 입력은 항목·오류 모두 없음', () {
    final parsed = parser.call('  \n \n');
    expect(parsed.entries, isEmpty);
    expect(parsed.hasErrors, isFalse);
  });
}
