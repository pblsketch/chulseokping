# 출석핑 — Claude Code 핸드오프 (2026-07-06 갱신 3차: M6 완료)

> 이 저장소(`E:\github\chulseokping`)에서 **Claude Code를 열고** 아래 "붙여넣기 프롬프트"를 그대로 입력하면 이어서 개발할 수 있다. M0~M6(학급·명단 관리) 구현까지 끝났고, 다음은 **백로그 P0(세션 시간창 → 기기 바인딩 → 헤드카운트) → M7(학교 관리)** 순서다.

---

## 📋 붙여넣기 프롬프트 (이 블록을 새 세션에 그대로 입력)

```
너는 "출석핑" K-12 출결 앱을 이어서 개발한다. 작업 디렉토리는 E:\github\chulseokping, 기본 브랜치는 main이다 (작업은 main에서 딴 새 기능 브랜치에서 — 기본 브랜치 직접 작업 금지).

[먼저 읽어라 — 순서대로]
1. CLAUDE.md, AGENTS.md              (개발 규칙·황금 규칙 — SSOT)
2. docs/HANDOFF.md                   (현재 상태·함정 목록 — 이 프롬프트의 원본)
3. docs/IMPROVEMENT_BACKLOG.md       (M5~M7 기능 공백 분석 + P0~P2 백로그)
4. docs/ARCHITECTURE.md              (클린 아키텍처 경계)

[현재 상태 — 요약]
- M0(백엔드)~M6(학급·명단 관리) 구현 완료. 실기기에서 BLE 자동 출석·회전 QR·실시간 반영 검증 통과(M4까지).
- M5 학생 계정 모델: **하이브리드** — 교사 일괄 생성(내부 이메일, service role) + 학생 연결 코드(student_link_codes, 해시 저장·48h·1회용).
- M6: 학급 생성 = create_class Edge Function 전용(classes 클라 INSERT는 RLS 차단 — QR secret 동시 발급 강제), 학급 보관(archived_at), 명단 제외(전학/졸업 — 출결·계정 보존).
- P0-1 세션 시간창: close_at/auto_late 서버 판정(410/late) + pg_cron 스윕 + 시작 시트 칩·지각 토글(기본 off)·카운트다운·+5분 연장. late는 사유 미확정(null) 허용 — 교사 사후 확정.
- P0-2 기기 바인딩: 서버 발급 device_uuid(flutter_secure_storage) + 학생당 active 1대 + 재바인딩 교사 원탭 승인 + 로그-온리 플래그 4종(차단 없음). 체크인(QR/BLE)에 device_uuid 동봉.
- P0-3 헤드카운트: 종료 시 원탭 확인(서버 집계) + CHECKIN_HEADCOUNT_GAP + 세션 화면 의심 신호 배지·확인 처리. **백로그 P0 3종 전부 완료.**
- flutter analyze 0건, 앱 테스트 104개 + 백엔드 통합 50개 통과.
- 프로젝트 방향: 상용 서비스가 아니라 GitHub 오픈소스 공개 (법적 쟁점은 배포자 고지 프레임 — docs/LAUNCH_GATE_LEGAL_RESEARCH.md §8).

[해야 할 일 — 이 순서로]
1) 실기기 확인(선택): 교사 회원가입 → 학급 만들기 → 학생 추가 → 연결 코드 연결 → 시간창 세션(카운트다운·지각·마감) → BLE 출석까지 한 사이클.
2) M7(학교 단위 관리): school_admin 역할·학교 생성·교사 소속 승인·데이터 수명주기(연도 진급 정책 포함). 또는 P1(키오스크 프리셋·QR 1회성 소비·문서 정합성) 착수.

[절대 규칙 — 어기면 안 됨]
- 출석 쓰기 = Edge Function 경유만. 클라이언트 직접 INSERT 금지.
- 좌표(lat/lng) 저장·전송 금지. domain은 순수 Dart.
- AndroidManifest: BLUETOOTH_SCAN에 neverForLocation 금지, ACCESS_FINE_LOCATION에 maxSdkVersion 금지 (회귀 테스트가 지킴 — OS가 iBeacon을 걸러버리는 실기 회귀였음).
- 새 테이블에 Realtime 구독을 붙이면 supabase_realtime publication 등록 마이그레이션 필수.
- 개발은 더미 데이터만. 커밋/푸시는 내가 요청할 때만.
- 변경 후 flutter analyze + 관련 flutter test 통과로 완료 판단. 실패는 출력과 함께 보고.

지금 1)부터 시작해라.
```

---

## 현재 상태 (사람용 상세)

- **구현**: M0~M5. BLE 자동 출석 실기기 성공(2026-07-06). M5 = 교사 회원가입(이메일 OTP)·비밀번호 재설정(recovery OTP)·학생 일괄 생성(create_students)·연결 코드 발급/재발급(issue_link_code)·학생 기기 연결(redeem_link_code + StudentLinkPage)·동의 생성 통합(guardian_consented).
- **M5 계약 요지**: 연결 코드 = 32자 알파벳(I/O/0/1 제외)×12자(60bit), DB엔 sha256 해시만, 48시간·1회용, redeem 시 내부 비밀번호 회전. 학생 내부 이메일 `stu-<uuid>@student.chulseokping.internal`.
- **커밋 이력**: `d1a6c78`(핸드오프+백로그) ← `55bf90a`(LICENSE+README) ← `806c511`(조사 문서 6건)
- **오픈소스 공개 완료(2026-07-06)**: Apache-2.0 · README 배포자 법적 고지 · 전체 히스토리 시크릿 스캔 통과 · 커밋 신원 재작성(pblsketch noreply, 개인 이메일 제거). 저장소 Public 전환, main 기본 브랜치, SECURITY.md, secret scanning + push protection, 비공개 취약점 신고(PVR)까지 완료.

## ⚠ 함정 목록 (실기기에서 피 흘려 배운 것)

| 함정 | 내용 |
|---|---|
| class_secrets | 학급 QR secret이 **시드에서만** 생성됨 — M6 학급 생성 기능에서 동시 발급 안 하면 신규 학급 QR이 조용히 실패 |
| neverForLocation | BLUETOOTH_SCAN에 이 플래그가 있으면 Android OS가 iBeacon을 스캔 결과에서 필터링 — 감지 영원히 불가 (회귀 테스트: android_manifest_test.dart) |
| realtime publication | supabase_realtime에 미등록 테이블은 .stream()이 초기 1회 조회로 퇴화 (회귀 테스트: realtime_publication_test.dart) |
| 비컨 포맷 | 송신은 반드시 iBeacon layout + manufacturerId 0x004C (수신 dchs_flutter_beacon은 iBeacon만 파싱) |
| fakeAsync | Riverpod 컨트롤러 타이머 테스트에서 fakeAsync 동작 안 함 — @visibleForTesting static Duration 패턴 사용 |
| Edge Function 503 | 재부팅 후 supabase start가 edge_runtime을 못 띄우는 경우 있음 — stop→start로 해결 |
| CLI secure-by-default | `npx supabase`(버전 미고정)가 CLI 2.109+로 올라가면 public 스키마에서 API 롤(anon/authenticated/**service_role 포함**)의 SELECT/INSERT/UPDATE/DELETE 기본 GRANT가 사라짐 → service role조차 permission denied, 통합 테스트 전멸. 해결: `20260706000003_api_role_grants.sql`(명시 GRANT + default privileges). 새 스키마 마이그레이션은 이 파일 이후 순서면 자동 적용됨 |
| Docker E: 마운트 | Docker Desktop이 절전/강제종료 후 E: 드라이브 WSL 마운트가 깨지면 supabase start가 "mkdir /run/desktop/mnt/host/e: file exists"로 실패 — Docker Desktop 종료 → `wsl --shutdown` → Docker Desktop 재시작으로 해결 |
| 이메일 OTP 로컬 | 교사 가입/재설정 OTP는 config.toml `enable_confirmations=true` + `supabase/templates/*.html`({{ .Token }} 노출) 전제. 메일은 Mailpit(http://127.0.0.1:54324)에서 확인. config 변경은 supabase stop→start 필요 |
| 새 Edge Function 등록 | 함수 디렉터리를 새로 만들면 게이트웨이 라우트가 start 시점에만 등록됨 — db reset만으로는 "Function not found". **supabase stop→start 필수** |
| 학급 생성 경로 | classes 클라 직접 INSERT는 RLS가 거부(M6) — 학급 생성은 create_class Edge Function만. 시드는 postgres role이라 예외 |

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
