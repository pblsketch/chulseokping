# 출석핑 — Claude Code 핸드오프

> 이 저장소(`E:\github\chulseokping`)에서 **Claude Code를 열고** 아래 "붙여넣기 프롬프트"를 그대로 입력하면 이어서 개발할 수 있다. 기획·하네스·법규 리서치는 끝났고, 다음은 **환경 마무리 → M0 백엔드 → Flutter 스캐폴딩** 순서다.

---

## 📋 붙여넣기 프롬프트 (이 블록을 Claude Code에 그대로 입력)

```
너는 "출석핑(Ping)" 교사용 출결 앱을 이어서 개발한다. 작업 디렉토리는 E:\github\chulseokping 이다.

[먼저 읽어라 — 순서대로]
1. CLAUDE.md, AGENTS.md  (개발 규칙·황금 규칙·SSOT)
2. docs/ARCHITECTURE.md  (Clean Architecture 경계)
3. docs/design.md         (밝고 미니멀 디자인 토큰)
4. docs/PRD.md            (제품 요구사항 Consensus v1.1)
5. docs/ATTENDANCE_POLICY.md (2026 출결 법규 — 상태/사유 enum·나이스 매핑 근거)

[절대 규칙 — 어기면 안 됨]
- Clean Architecture 의존성 규칙: presentation → domain ← data. domain은 순수 Dart(flutter/supabase/BLE import 금지).
- 출석 쓰기는 검증 Edge Function 경유만. 클라이언트가 attendance_logs 직접 INSERT 금지.
- 좌표(lat/lng) 절대 저장·전송 금지. BLE는 근접 boolean + 회전 minor만.
- 동의 미확인(미성년자) 학생은 서버에서 출결 수집 거부.
- 나이스 내보내기는 "사유 기준": 사유∈{질병,미인정,기타}만 포함, 출석인정·교외체험학습 제외 (ATTENDANCE_POLICY §10.2).
- 개발/테스트는 더미 데이터로만. 실 학생 PII 투입은 법률 자문 게이트 통과 후.
- 커밋/푸시는 내가 요청할 때만. 기능 브랜치 사용.

[현재 상태]
- 앱 코드 0. 기획/하네스 문서만 존재.
- 백엔드: Supabase 신규 프로젝트 필요(아직 없음). 로컬은 Docker Desktop + `supabase start`.
- 도구: Supabase CLI / Deno / Git / Docker(설치됨, 켜야 함) 있음. Flutter는 C:\dev\flutter 에 설치 중(아래 환경 마무리 참고). Android Studio 미설치. iOS는 맥 필요.

[해야 할 일 — 이 순서로, 각 단계 내 승인 받고 진행]
0) 환경 마무리:
   - Flutter: `powershell -ExecutionPolicy Bypass -File tool\setup_flutter.ps1` 실행(다운로드 이어받기→추출→PATH→flutter doctor). 새 터미널에서 `flutter --version` 확인.
   - Docker Desktop 실행. 필요시 `winget install Google.AndroidStudio`(Android 빌드용).
1) M0 백엔드 (Flutter 불필요):
   - supabase/migrations 작성: PRD §5 + ATTENDANCE_POLICY §10.1 기준. 테이블 = sessions, kiosk_devices, student_classes, consents, suspicious_flags + attendance_logs(확장: method enum QR/PIN/BLE/MANUAL/LIST, status 5종, absence_type 4종, reason_code, session_id, kiosk_device_id, unique(student_id, session_id), 좌표 컬럼 없음).
   - RLS: 학생=본인 read / 교사=class 범위 / attendance write=service role only(클라 INSERT deny).
   - Edge Functions(Deno/TS): check_in_qr(TOTP window:1 재검증), check_in_ble(회전 minor+session+device+class 검증), check_in_pin(명단+동의 검증). 전부 멱등 INSERT.
   - supabase/seed.sql: 더미 학교/교사/학급/학생(실 PII 금지).
   - Exit: 로컬에서 QR 출석 1건이 멱등으로 기록되고, 클라 직접 INSERT가 거부됨을 테스트로 확인.
2) Flutter 스캐폴딩 (app/):
   - `flutter create` 후 ARCHITECTURE §3 폴더구조(core/domain/data/presentation).
   - 패키지: flutter_riverpod, riverpod_annotation, go_router, freezed, json_serializable, build_runner, supabase_flutter, dchs_flutter_beacon(감지), beacon_broadcast(키오스크 광고), drift(오프라인 큐), mocktail.
   - core/theme: design.md 토큰 구현(AppColors/AppTypography/AppSpacing). 매직값 금지.
   - 빈 셸 3종: student / kiosk / teacher (go_router 역할 라우팅).
3) 이후 M1(QR 출석)→M2(키오스크)→M3(BLE)→M4(나이스+동의)→M5(출시), PRD §11.

[작업 방식]
- 각 단계는 작게 쪼개 PR 단위로. domain usecase엔 단위 테스트 필수.
- `flutter analyze` 0 경고, `dart format`, 관련 테스트 통과 후 완료 보고. 실패하면 출력과 함께 실패 보고.
- 추측 금지 — 플러그인 API 불확실하면 context7 MCP로 문서 확인 후 진행.

지금 0)부터 시작해라. 먼저 환경 상태를 점검(flutter/supabase/docker 버전)하고, Flutter 설치 마무리부터 진행한 뒤 보고해.
```

---

## 환경 마무리 메모 (사람용 참고)
- **Flutter 설치 중**: `C:\dev\flutter_3.44.4-stable.zip` 로 받는 중(이 네트워크가 ~200MB에서 끊겨서 이어받기 루프 사용). 완료/추출/PATH/doctor는 `tool/setup_flutter.ps1` 한 방으로 끝남. (zip이 덜 받아졌어도 스크립트가 이어받아 완성함.)
- **Supabase**: 호스티드 프로젝트를 새로 만들거나, 로컬은 Docker Desktop 켜고 `supabase start`. 키는 `.env.example` 참고(`.env`는 커밋 금지).
- **Android Studio**: Android 실기/에뮬 빌드 시 `winget install Google.AndroidStudio` → `flutter doctor --android-licenses`.
- **iOS**: Windows에서 빌드 불가 → 맥 또는 클라우드 빌드(Codemagic 등)는 추후.

## ⚠ 출시 차단 게이트 (코드로 우회 불가)
실데이터 운영/스토어 제출 전 **법률 자문 필수**:
- 위치정보법상 BLE 근접 해당 여부
- 14세 미만 보호자 동의 "교사 확인 갈음" 적법성
→ 개발은 더미 데이터로 계속 진행.

## 문서 지도
```
CLAUDE.md / AGENTS.md          개발 규칙(SSOT)
docs/PRD.md                    제품 요구사항(v1.1)
docs/ARCHITECTURE.md           Clean Architecture
docs/design.md                 디자인 시스템
docs/ATTENDANCE_POLICY.md      2026 출결 법규
docs/deep-interview-spec.md    요구사항 인터뷰 기록
docs/HANDOFF.md                (이 파일)
tool/setup_flutter.ps1         Flutter 설치 마무리
.env.example                   환경변수 템플릿
```
