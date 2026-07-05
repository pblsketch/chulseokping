import 'package:chulseokping_app/domain/value_objects/absence_reason.dart';
import 'package:chulseokping_app/domain/value_objects/attendance_status.dart';
import 'package:chulseokping_app/domain/value_objects/check_in_mode.dart';
import 'package:chulseokping_app/domain/value_objects/session_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('2축 모델 enum 계약 (ATTENDANCE_POLICY §10.1)', () {
    test('출결 상태는 정확히 5종', () {
      expect(AttendanceStatus.values, hasLength(5));
      expect(
        AttendanceStatus.values.map((s) => s.label),
        containsAll(['출석', '지각', '조퇴', '결과', '결석']),
      );
    });

    test('사유는 정확히 4종', () {
      expect(AbsenceReason.values, hasLength(4));
      expect(
        AbsenceReason.values.map((r) => r.label),
        containsAll(['출석인정', '질병', '미인정', '기타']),
      );
    });

    test('NEIS 집계 대상 사유는 질병·미인정·기타뿐 — 출석인정 미집계', () {
      expect(AbsenceReason.recognized.countsForNeis, isFalse);
      expect(AbsenceReason.sick.countsForNeis, isTrue);
      expect(AbsenceReason.unrecognized.countsForNeis, isTrue);
      expect(AbsenceReason.other.countsForNeis, isTrue);
    });

    test('체크인 방식은 5종, 서버 wire 값과 왕복 일치', () {
      expect(CheckInMode.values, hasLength(5));
      for (final mode in CheckInMode.values) {
        expect(CheckInMode.fromWire(mode.wireName), mode);
      }
    });

    test('상태 wire 값 왕복 일치 (서버 attendance_status enum)', () {
      for (final status in AttendanceStatus.values) {
        expect(AttendanceStatus.fromWire(status.wireName), status);
      }
      expect(AttendanceStatus.earlyLeave.wireName, 'early_leave');
      expect(AttendanceStatus.classAbsent.wireName, 'class_absent');
    });

    test('세션 유형은 조회/교시 2종', () {
      expect(SessionType.values, hasLength(2));
      expect(SessionType.fromWire('HOMEROOM'), SessionType.homeroom);
      expect(SessionType.fromWire('PERIOD'), SessionType.period);
    });

    test('출석인정 세부 코드에 교외체험학습 포함 (§5 분리 관리 대상)', () {
      expect(RecognizedCode.values.map((c) => c.label), contains('교외체험학습'));
    });
  });
}
