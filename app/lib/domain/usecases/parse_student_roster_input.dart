import '../entities/new_student_entry.dart';

/// 명단 텍스트 파싱 결과 — 유효 행과 행별 오류를 분리 보고.
class ParsedRoster {
  const ParsedRoster({required this.entries, required this.errors});

  final List<NewStudentEntry> entries;

  /// "N행: 사유" 형식의 사용자 표시용 오류
  final List<String> errors;

  bool get hasErrors => errors.isNotEmpty;
}

/// M5: "학번 이름" 줄 단위 명단 입력 파서 (순수 로직 — 엑셀/명렬표 붙여넣기 대응).
/// 구분자: 공백·탭·쉼표. 첫 토큰 = 학번(숫자 1~10자리), 나머지 = 이름.
class ParseStudentRosterInput {
  const ParseStudentRosterInput();

  ParsedRoster call(String text, {bool guardianConsented = false}) {
    final entries = <NewStudentEntry>[];
    final errors = <String>[];
    final seenNumbers = <String>{};

    final lines = text.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final tokens = line
          .split(RegExp(r'[\s,\t]+'))
          .where((t) => t.isNotEmpty)
          .toList();
      if (tokens.length < 2) {
        errors.add('${i + 1}행: 학번과 이름을 함께 입력해 주세요 — "$line"');
        continue;
      }

      final studentNumber = tokens.first;
      final name = tokens.sublist(1).join(' ');
      if (!RegExp(r'^\d{1,10}$').hasMatch(studentNumber)) {
        errors.add('${i + 1}행: 학번은 숫자 1~10자리예요 — "$studentNumber"');
        continue;
      }
      if (name.length > 50) {
        errors.add('${i + 1}행: 이름이 너무 길어요 (50자 이하)');
        continue;
      }
      if (!seenNumbers.add(studentNumber)) {
        errors.add('${i + 1}행: 학번 $studentNumber이(가) 중복됐어요');
        continue;
      }

      entries.add(
        NewStudentEntry(
          name: name,
          studentNumber: studentNumber,
          guardianConsented: guardianConsented,
        ),
      );
    }

    return ParsedRoster(entries: entries, errors: errors);
  }
}
