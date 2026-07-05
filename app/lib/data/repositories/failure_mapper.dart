import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/failure.dart';

/// data 레이어 공용: Exception → Failure 변환 (ARCHITECTURE §2.2).
Failure mapToFailure(Object error) {
  if (error is FunctionException) {
    final details = error.details;
    final code = details is Map ? details['error'] as String? : null;
    return switch (error.status) {
      400 => ValidationFailure(_korean(code) ?? '요청이 올바르지 않아요'),
      401 => const AuthFailure(),
      403 when code == 'consent_required' => const ConsentRequiredFailure(),
      403 => ValidationFailure(_korean(code) ?? '권한이 없어요'),
      404 => ValidationFailure(_korean(code) ?? '대상을 찾을 수 없어요'),
      410 => const ValidationFailure('세션이 종료됐어요'),
      422 => const ValidationFailure('코드가 만료됐어요 — 다시 스캔해 주세요'),
      _ => ServerFailure('서버 오류가 발생했어요 (${error.status})'),
    };
  }
  if (error is AuthException) {
    return AuthFailure(
      error.statusCode == '400' ? '이메일 또는 비밀번호가 맞지 않아요' : '로그인이 필요해요',
    );
  }
  if (error is PostgrestException) return ServerFailure(error.message);
  if (error is SocketException) return const NetworkFailure();
  return ServerFailure('$error');
}

String? _korean(String? code) => switch (code) {
  'not_a_member' => '이 학급 명단에 없어요',
  'not_class_teacher' => '이 학급의 담당 교사가 아니에요',
  'class_mismatch' => '기기와 세션의 학급이 달라요',
  'student_not_found' => '학생을 찾을 수 없어요',
  'record_not_found' => '출결 기록을 찾을 수 없어요',
  'unknown_beacon' => '등록되지 않은 비컨이에요',
  'unknown_device' => '등록되지 않은 기기예요',
  'coordinates_forbidden' => '위치 정보는 보낼 수 없어요',
  _ => null,
};
