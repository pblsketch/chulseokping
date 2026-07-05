import '../services/beacon_scanner.dart';

/// ST-2 "RSSI 임계 이상 안정 감지" 판정 — 순수 로직 (M3 실측으로 기본값 보정 예정, ADR follow-up #3).
///
/// - 같은 major(=키오스크 기기)가 [rssiThreshold] 이상으로 [requiredConsecutive]회
///   연속 관측되면 안정으로 판정하고 **최신** sighting을 반환한다(회전 minor의 신선도 유지).
/// - minor는 5초마다 회전하므로 연속성 판정 키는 major다.
class BeaconSightingStabilizer {
  BeaconSightingStabilizer({
    this.rssiThreshold = -75,
    this.requiredConsecutive = 3,
  });

  final int rssiThreshold;
  final int requiredConsecutive;

  final Map<int, int> _streaksByMajor = {};

  /// 스캔 1회 결과를 반영한다. 안정 감지되면 해당 sighting, 아니면 null.
  BeaconSighting? add(List<BeaconSighting> sightings) {
    final strongByMajor = <int, BeaconSighting>{};
    for (final sighting in sightings) {
      if (sighting.rssi < rssiThreshold) continue;
      final existing = strongByMajor[sighting.major];
      if (existing == null || sighting.rssi > existing.rssi) {
        strongByMajor[sighting.major] = sighting;
      }
    }

    // 이번 스캔에서 임계 미달인 major는 streak 리셋
    _streaksByMajor.removeWhere(
      (major, _) => !strongByMajor.containsKey(major),
    );

    BeaconSighting? stable;
    for (final entry in strongByMajor.entries) {
      final streak = (_streaksByMajor[entry.key] ?? 0) + 1;
      _streaksByMajor[entry.key] = streak;
      if (streak >= requiredConsecutive) {
        stable ??= entry.value;
      }
    }
    return stable;
  }

  void reset() => _streaksByMajor.clear();
}
