import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/class_room.dart';
import '../../domain/entities/session.dart';

/// 내 학급 목록 (교사=담당, 학생=소속).
final myClassesProvider = FutureProvider<List<ClassRoom>>((ref) async {
  final result = await ref.watch(rosterRepositoryProvider).myClasses();
  return result.fold((classes) => classes, (failure) => throw failure.message);
});

/// 학급의 활성 세션 (없으면 null) — Realtime 구독이라 교사가 세션을 종료·재시작해도
/// 자동으로 갱신된다(수동 새로고침 불필요, 예전엔 1회성 조회라 값이 굳어 있었다).
final activeSessionProvider = StreamProvider.family<Session?, String>(
  (ref, classId) => ref.watch(watchActiveSessionProvider).call(classId),
);
