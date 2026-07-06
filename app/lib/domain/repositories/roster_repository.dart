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

  // ── M6 학급 관리 ──

  /// 학급 생성 — create_class Edge Function 경유(class_secrets 동시 발급).
  /// 클라 직접 INSERT는 RLS가 차단한다(secret 없는 학급 방지).
  Future<Result<ClassRoom>> createClass(String name);

  Future<Result<void>> renameClass({
    required String classId,
    required String name,
  });

  /// 학급 보관 — 삭제 대신 목록에서 숨김(세션·출결 이력은 나이스 근거라 보존).
  Future<Result<void>> archiveClass(String classId);

  /// 전학/졸업 — 명단(student_classes)만 해제, 계정·출결 이력 보존.
  Future<Result<void>> removeStudentFromClass({
    required String classId,
    required String studentId,
  });
}
