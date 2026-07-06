# 출석핑 (Chulseokping)

> **비컨이 "핑" 신호를 쏘면 자동 출석.** 교사 태블릿·폰이 곧 출석기 — 별도 하드웨어 없이, 나이스(NEIS) 정리까지 한 번에.

K-12 교실을 위한 오픈소스 출결 시스템입니다. 교사가 세션을 시작하면 교사 기기가 BLE 비컨(iBeacon)이 되고, 학생 폰이 이를 감지해 자동 출석됩니다. 폰이 없거나 수거하는 학교는 회전 QR·키오스크 PIN으로 대응합니다.

## 핵심 기능 (구현 완료)

- **BLE 근접 자동 출석**: 교사 기기가 세션 중 iBeacon 광고(고정 UUID + 회전 minor·TOTP), 학생 앱이 감지 → 자동 체크인 (Android 자동 / iPhone 원탭)
- **회전 QR 출석**: 5초 주기 TOTP QR — 스크린샷 공유로는 대리출석 불가
- **키오스크 모드**(공용 태블릿): 특대 QR + 학번·PIN 체크인 + 화면 고정
- **교사 대시보드**: 세션 시작/종료, 실시간 출석 현황(Supabase Realtime), 수동 수정(상태 5종 × 사유 4종 — 2026 출결 지침 2축 모델)
- **나이스 내보내기**: 월별 일람표 + 예외만 추려 TSV/xlsx (교외체험학습 미기재 규칙 반영)
- **명단 관리**: 보호자 동의 확인(서버 강제 — 동의 없으면 모든 수집 거부), 키오스크 PIN 발급

## 프라이버시 원칙 (설계 기본값)

- **좌표(GPS lat/lng) 무수집** — 코드 전체에 좌표 식별자가 없음을 회귀 테스트가 강제 ([`no_coordinates_test.dart`](app/test/regression/no_coordinates_test.dart))
- BLE는 근접 여부(boolean)와 회전 minor만 사용, RSSI 원시값·좌표 전송 없음
- 출석 기록 쓰기는 전부 서버(Edge Function) 검증 경유 — 클라이언트 직접 INSERT 금지(RLS로 차단)
- 보호자 동의가 서버에 기록되기 전에는 어떤 방식으로도 출결 수집 불가
- 부정 의심은 차단이 아닌 로그(suspicious_flags) — 학생 불이익 오탐 방지

## 기술 스택

| 레이어 | 기술 |
|---|---|
| 앱 | Flutter (Android/iOS), Riverpod 3, 클린 아키텍처 (domain은 순수 Dart) |
| 백엔드 | Supabase — Auth·Postgres·RLS·Realtime·Edge Functions(Deno) |
| BLE 감지 | `dchs_flutter_beacon` (iPhone iBeacon은 CoreLocation ranging) |
| BLE 광고 | `beacon_broadcast` (로컬 벤더링, iBeacon layout + 회전 minor) |

## 시작하기 (로컬 개발)

사전 요구: Flutter SDK, Docker Desktop, Supabase CLI, Android 실기기 2대(교사·학생) 권장.

```bash
# 1. 백엔드 (프로젝트 루트)
supabase start          # 로컬 스택 기동
supabase db reset       # 스키마 + 더미 시드 적용

# 2. 앱
cd app
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=http://<PC-IP>:54321 \
  --dart-define=SUPABASE_ANON_KEY=<supabase status의 ANON_KEY>
```

실기기 테스트 절차·더미 계정은 [`docs/DEVICE_TESTING.md`](docs/DEVICE_TESTING.md) 참고. 검증:

```bash
cd app && flutter analyze && flutter test   # 전체 테스트
cd supabase && deno test --allow-all tests/ # 백엔드 통합 테스트 (로컬 스택 필요)
```

## ⚠ 실데이터 운영 전 법적 고지 (배포 기관 필독)

이 저장소는 소스 코드 공개일 뿐, 어떤 법적 적합성도 보증하지 않습니다. **이 소프트웨어를 실제 학생 데이터로 운영하는 기관(학교 등)이 개인정보처리자로서 다음을 검토·이행할 책임이 있습니다**:

1. **위치정보법**: BLE 근접 판정·Wi-Fi AP 정보가 위치정보에 해당하는지, 위치정보사업/위치기반서비스사업 등록·신고 대상인지 검토 (미해결 쟁점 — [`docs/LAUNCH_GATE_LEGAL_RESEARCH.md`](docs/LAUNCH_GATE_LEGAL_RESEARCH.md) §1·§7)
2. **개인정보 보호법 제22조의2**: 만 14세 미만 학생은 법정대리인 동의를 시행령 제17조의2가 열거한 방법으로 확보·확인해야 함 — 앱의 "동의 확인" 체크는 내부 기록일 뿐 법정 동의 절차를 대체하지 않음 (위반 시 형사처벌 — 같은 문서 §2)
3. 운영 기관 명의의 개인정보 처리방침 마련, 2026-03 시행 초·중등교육법(수업 중 스마트기기 사용 제한)과의 정합(학칙 "교육 목적" 예외 반영)

배포자용 체크리스트: [`docs/LAUNCH_GATE_LEGAL_RESEARCH.md`](docs/LAUNCH_GATE_LEGAL_RESEARCH.md) §4·§8.

## 문서

| 문서 | 내용 |
|---|---|
| [`docs/PRD.md`](docs/PRD.md) | 제품 요구사항 (Consensus v1.1) |
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | 클린 아키텍처 경계·계약 |
| [`docs/ATTENDANCE_POLICY.md`](docs/ATTENDANCE_POLICY.md) | 2026 출결 지침 — 상태/사유·나이스 매핑 근거 |
| [`docs/DEVICE_TESTING.md`](docs/DEVICE_TESTING.md) | 실기기 테스트 가이드 |
| [`docs/IMPROVEMENT_BACKLOG.md`](docs/IMPROVEMENT_BACKLOG.md) | 조사 기반 개선 백로그 (P0~P2) |
| [`docs/COMPETITOR_ANALYSIS.md`](docs/COMPETITOR_ANALYSIS.md) | 국내 출결 앱 기술 분석 |
| [`docs/LAUNCH_GATE_LEGAL_RESEARCH.md`](docs/LAUNCH_GATE_LEGAL_RESEARCH.md) | 위치정보법·개보법 자체 점검 |

## 로드맵

[`docs/IMPROVEMENT_BACKLOG.md`](docs/IMPROVEMENT_BACKLOG.md) 참고. 다음 후보: 세션 수집 시간창(자동 마감+지각 구분), 기기 바인딩, 세션 마감 헤드카운트 확인.

## 라이선스

[Apache License 2.0](LICENSE) — 특허 조항 포함. 소프트웨어는 어떠한 보증 없이 "있는 그대로" 제공됩니다.

---
*네이밍 노트: "핑"은 BLE 비컨 신호(ping) + 친근한 어감.*
