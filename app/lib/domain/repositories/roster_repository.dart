import '../../core/result/result.dart';
import '../entities/class_room.dart';
import '../entities/created_student.dart';
import '../entities/issued_link_code.dart';
import '../entities/new_student_entry.dart';
import '../entities/student.dart';

abstract interface class RosterRepository {
  Future<Result<List<ClassRoom>>> myClasses();

  Future<Result<List<Student>>> studentsOf(String classId);

  /// TE-6: 키오스크 PIN 발급/재설정 — set_student_pin Edge Function 경유(해시만 저장).
  Future<Result<void>> setStudentPin({
    required String studentId,
    required String pin,
  });

  /// M5: 학생 계정 일괄 생성 — create_students Edge Function(service role) 경유.
  /// 부분 성공 허용: 행별 결과를 그대로 반환한다.
  Future<Result<List<CreatedStudent>>> createStudents({
    required String classId,
    required List<NewStudentEntry> entries,
  });

  /// M5: 학생 연결 코드 재발급(기존 코드 무효화) — 학생용 "비밀번호 재설정".
  Future<Result<IssuedLinkCode>> issueLinkCode(String studentId);
}
