# 출석핑 — Claude Code 핸드오프 (2026-07-06 갱신)

> 이 저장소(`E:\github\chulseokping`)에서 **Claude Code를 열고** 아래 "붙여넣기 프롬프트"를 그대로 입력하면 이어서 개발할 수 있다. M0~M4 구현 + 실기기 검증 + 오픈소스 공개 준비까지 끝났고, 다음은 **M5(계정·온보딩) → M6(학급·명단 관리) → 백로그 P0 → M7(학교 관리)** 순서다.

---

## 📋 붙여넣기 프롬프트 (이 블록을 새 세션에 그대로 입력)

```
너는 "출석핑" K-12 출결 앱을 이어서 개발한다. 작업 디렉토리는 E:\github\chulseokping, 브랜치는 feat/m0-foundation 이다.

[먼저 읽어라 — 순서대로]
1. CLAUDE.md, AGENTS.md              (개발 규칙·황금 규칙 — SSOT)
2. docs/HANDOFF.md                   (현재 상태·함정 목록 — 이 프롬프트의 원본)
3. docs/IMPROVEMENT_BACKLOG.md       (M5~M7 기능 공백 분석 + P0~P2 백로그)
4. docs/ARCHITECTURE.md              (클린 아키텍처 경계)

[현재 상태 — 요약]
- M0(백엔드)~M4(나이스 내보내기·동의·PIN) 구현 완료. 실기기(교사 태블릿 비컨 ↔ 학생 폰)에서 BLE 자동 출석·회전 QR·실시간 반영 모두 검증 통과.
- flutter analyze 0건, 테스트 72개 통과. 최근 커밋 d525edc (LICENSE+README).
- 프로젝트 방향: 상용 서비스가 아니라 GitHub 오픈소스 공개 (법적 쟁점은 배포자 고지 프레임 — docs/LAUNCH_GATE_LEGAL_RESEARCH.md §8).
- 미커밋 파일 있음: docs/HANDOFF.md(갱신본), docs/IMPROVEMENT_BACKLOG.md(M5~M7 섹션).

[해야 할 일 — 이 순서로]
0) git status로 미커밋 문서 확인 → 커밋 (docs: 핸드오프 갱신 + M5~M7 기능 공백 분석)
1) M5 착수 전 최대 설계 결정을 나와 확정: 학생 계정 모델.
   권장안 = 교사 일괄 생성(학번 기반 내부 계정, Edge Function service role 생성, 학생 이메일 불요).
   대안(자가 가입/초대코드)과의 트레이드오프를 backlog M5 섹션 기준으로 나에게 제시하고 결정받아라.
2) 결정 후 M5 설계·구현: 교사 회원가입(이메일 인증), 학생 계정 일괄 생성, 비밀번호 재설정(교사=이메일/학생=담임 리셋), 14세 미만 동의 흐름 통합.
3) M6: 학급 CRUD(⚠ class_secrets 동시 발급 필수 — HANDOFF 함정 목록 참조), 학생 일괄 등록, 전학/졸업 처리.
4) 이후 백로그 P0(세션 시간창 → 기기 바인딩 → 헤드카운트) → M7(학교 단위 관리).

[절대 규칙 — 어기면 안 됨]
- 출석 쓰기 = Edge Function 경유만. 클라이언트 직접 INSERT 금지.
- 좌표(lat/lng) 저장·전송 금지. domain은 순수 Dart.
- AndroidManifest: BLUETOOTH_SCAN에 neverForLocation 금지, ACCESS_FINE_LOCATION에 maxSdkVersion 금지 (회귀 테스트가 지킴 — OS가 iBeacon을 걸러버리는 실기 회귀였음).
- 새 테이블에 Realtime 구독을 붙이면 supabase_realtime publication 등록 마이그레이션 필수.
- 개발은 더미 데이터만. 커밋/푸시는 내가 요청할 때만.
- 변경 후 flutter analyze + 관련 flutter test 통과로 완료 판단. 실패는 출력과 함께 보고.

지금 0)부터 시작해라.
```

---

## 현재 상태 (사람용 상세)

- **구현**: M0~M4 + 실기기 회귀 수정 2라운드. BLE 자동 출석이 실기기에서 실제 성공(2026-07-06).
- **커밋 이력**: `d525edc`(LICENSE+README) ← `af0f52e`(조사 문서 6건) ← `90e06dd`(실기기 회귀+BYOD 교사 비컨)
- **오픈소스 준비 완료**: Apache-2.0, README 배포자 법적 고지, 시크릿 스캔 통과. 남은 것: main 병합·푸시·저장소 Public 전환(사용자 명시 요청 시).

## ⚠ 함정 목록 (실기기에서 피 흘려 배운 것)

| 함정 | 내용 |
|---|---|
| class_secrets | 학급 QR secret이 **시드에서만** 생성됨 — M6 학급 생성 기능에서 동시 발급 안 하면 신규 학급 QR이 조용히 실패 |
| neverForLocation | BLUETOOTH_SCAN에 이 플래그가 있으면 Android OS가 iBeacon을 스캔 결과에서 필터링 — 감지 영원히 불가 (회귀 테스트: android_manifest_test.dart) |
| realtime publication | supabase_realtime에 미등록 테이블은 .stream()이 초기 1회 조회로 퇴화 (회귀 테스트: realtime_publication_test.dart) |
| 비컨 포맷 | 송신은 반드시 iBeacon layout + manufacturerId 0x004C (수신 dchs_flutter_beacon은 iBeacon만 파싱) |
| fakeAsync | Riverpod 컨트롤러 타이머 테스트에서 fakeAsync 동작 안 함 — @visibleForTesting static Duration 패턴 사용 |
| Edge Function 503 | 재부팅 후 supabase start가 edge_runtime을 못 띄우는 경우 있음 — stop→start로 해결 |

## 환경 부팅 (재부팅 후)

1. Docker Desktop 실행 → `npx supabase start` → `docker ps`로 edge_runtime 포함 전체 기동 확인
2. `cd app && flutter run -d <기기ID> --dart-define=SUPABASE_URL=http://<PC-IP>:54321 --dart-define=SUPABASE_ANON_KEY=<supabase status의 ANON_KEY>`
   (PC IP: `ipconfig` Wi-Fi IPv4 · 기기: `flutter devices` · 키는 커밋 금지)
3. adb 직접 호출: `C:/dev/android-sdk/platform-tools/adb.exe` (PATH에 없음)
4. 실기기 시나리오·더미 계정: [`DEVICE_TESTING.md`](DEVICE_TESTING.md)

## 도구 메모

- **법령 자체 점검**: korean-law MCP가 프로젝트 local 스코프에 등록됨(새 세션에서 도구 로드됨). 키는 `claude mcp list`로 확인 — **저장소에 키를 적지 말 것**
- **goals.py(fablize)**: 상태 `./.fablize/`, `status`로 확인. Windows 콘솔은 `PYTHONIOENCODING=utf-8` 필요

## 문서 지도

```
CLAUDE.md / AGENTS.md              개발 규칙(SSOT)
docs/IMPROVEMENT_BACKLOG.md        M5~M7 공백 분석 + P0~P2 백로그 ← 다음 작업의 원천
docs/PRD.md / ARCHITECTURE.md      제품 요구사항 / 클린 아키텍처
docs/ATTENDANCE_POLICY.md          2026 출결 지침 (상태/사유·나이스 매핑)
docs/DEVICE_TESTING.md             실기기 테스트 가이드
docs/LAUNCH_GATE_LEGAL_RESEARCH.md 법률 자체 점검 (§8 오픈소스 게이트 재정의)
docs/COMPETITOR_ANALYSIS.md        경쟁 앱 기술 분석
docs/RESEARCH_*.md                 기기바인딩 / 시간창 / 리로스쿨 조사
```
