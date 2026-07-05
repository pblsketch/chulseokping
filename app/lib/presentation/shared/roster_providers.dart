import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/class_room.dart';
import '../../domain/entities/session.dart';

/// 내 학급 목록 (교사=담당, 학생=소속).
final myClassesProvider = FutureProvider<List<ClassRoom>>((ref) async {
  final result = await ref.watch(rosterRepositoryProvider).myClasses();
  return result.fold((classes) => classes, (failure) => throw failure.message);
});

/// 학급의 활성 세션 (없으면 null).
final activeSessionProvider = FutureProvider.family<Session?, String>((
  ref,
  classId,
) async {
  final result = await ref.watch(getActiveSessionProvider).call(classId);
  return result.fold((session) => session, (failure) => throw failure.message);
});
