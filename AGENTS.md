# AGENTS.md — 출석핑 개발 가이드

> 모든 코딩 에이전트(Codex / Claude / 기타)와 기여자를 위한 **단일 진실 원천(SSOT)**.
> Claude Code는 `CLAUDE.md`가 이 문서를 참조한다. 충돌 시 이 문서가 우선한다.

## 1. 프로젝트 한 줄
**출석핑(Ping)** — 개별 교사가 5분 내 도입하는 K-12 출결 앱. 교실 갤럭시탭/교사 폰이 BLE 비컨이 되어 자동 출석, QR/PIN 폴백, 나이스(NEIS) 이관 최적화. **Flutter(Android+iOS) + Supabase.**

자세한 요구사항은 `docs/PRD.md`, 구조는 `docs/ARCHITECTURE.md`, UI는 `docs/design.md`, **출결 법규는 `docs/ATTENDANCE_POLICY.md`(2026 지침 — 상태/사유 enum·NEIS 매핑의 근거)**.

## 2. 황금 규칙 (어기면 리뷰 반려)
1. **Clean Architecture 의존성 규칙 준수** — `presentation → domain ← data`. `docs/ARCHITECTURE.md` §1·§9 참조.
2. **domain은 순수 Dart** — flutter/supabase/BLE import 금지.
3. **출석 쓰기는 검증 Edge Function 경유** — 클라이언트가 `attendance_logs` 직접 INSERT 금지.
4. **좌표(lat/lng) 절대 저장·전송 금지** — entity/model/payload 어디에도. BLE는 근접 boolean + 회전 minor만.
5. **미성년자 PII 최소화** — 수집 항목 = 식별자/출결상태/시각/방식. 동의 미확인 학생은 **서버에서** 수집 거부.
6. **추측 금지** — 모르면 PRD/ARCHITECTURE 확인, 그래도 불명확하면 멈추고 질문. 환각 금지.
7. **요청 범위 안에서만** 변경. 곁다리 리팩터 금지.
8. **출결 상태/사유·NEIS 매핑은 `docs/ATTENDANCE_POLICY.md`를 따른다** — 사유=출석인정은 NEIS상 출석(내보내기 제외), 교외체험학습은 학생부 미기재, 지각·조퇴·결과를 결석으로 자동 환산 금지.

## 3. 기술 스택 (고정)
- 앱: **Flutter** (Dart 3+). 상태/DI: **Riverpod 2**. 라우팅: **go_router**. 모델: **freezed + json_serializable**. 에러: sealed `Result`/`Failure`.
- 백엔드: **Supabase** (Auth/DB/Realtime/RLS/Edge Functions(Deno/TS)).
- BLE: 감지 **dchs_flutter_beacon**(iPhone CoreLocation iBeacon ranging 필수), 광고 **beacon_broadcast**(키오스크 고정 UUID+major+회전 minor). ※ `flutter_blue_plus`로 iPhone iBeacon 감지 불가 — 쓰지 말 것.
- 로컬 큐(오프라인): **drift**(권장).
- 코드젠: build_runner.

> 새 의존성 추가는 신중히. 추가 시 이유를 PR 설명에 적고, 가벼운 대안을 먼저 검토.

## 4. 폴더 구조 (요약)
```
app/lib/{ core, domain, data, presentation }   # ARCHITECTURE.md §3
supabase/{ migrations, functions }
docs/{ PRD.md, ARCHITECTURE.md, design.md, ATTENDANCE_POLICY.md, HANDOFF.md, deep-interview-spec.md }
```
- 새 기능 = surface(presentation) + usecase(domain) + repository 구현(data) 세트로 추가. usecase 없이 위젯에서 바로 I/O 호출 금지.

## 5. 코딩 컨벤션
- 파일/디렉토리: `snake_case.dart`. 클래스: `PascalCase`. 멤버/변수: `camelCase`. 상수: `lowerCamel` 또는 `kPrefix`는 지양.
- usecase 클래스명 = 동사구(`StartSession`, `CheckInByBle`), `call()` 또는 `execute()` 단일 진입.
- entity ↔ DTO는 항상 매퍼 경유. DTO를 presentation에 노출 금지.
- 위젯은 표현만, 분기/검증은 컨트롤러/usecase.
- 한국어 사용자 대상이므로 **UI 문자열은 한국어**, 에러 메시지도 한국어(코드 식별자는 영어).
- 매직 값 금지 — 컬러/스페이싱/타이포는 `core/theme` 토큰(design.md) 참조.
- 주석은 "왜"에 집중. 자명한 코드 주석 금지.

## 6. 명령어
```bash
# 앱 (app/ 에서)
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # freezed/riverpod/json
flutter analyze
dart format .
flutter test
flutter run                      # 기기/에뮬
flutter build apk / ipa

# Supabase (supabase/ 에서)
supabase start                   # 로컬
supabase db reset                # 마이그레이션 재적용
supabase functions serve         # Edge Function 로컬
supabase functions deploy check_in_ble
```
> 환경변수: `--dart-define`(SUPABASE_URL/ANON_KEY) 또는 `.env`(gitignore). 키를 커밋 금지.

## 7. 작업 완료 정의 (DoD)
- `flutter analyze` 0 경고, `dart format` 적용.
- 관련 **테스트 추가/통과**(domain usecase는 필수, ARCHITECTURE.md §7).
- Clean Architecture 경계·황금 규칙 위반 없음.
- 회귀 가드 통과: 좌표 필드 부재, 클라 직접 INSERT 부재, 동의 서버 강제.
- 완료 주장은 **실제 실행 결과(테스트 출력)** 로 뒷받침. 실패하면 실패라고 보고.

## 8. 테스트
- domain: 순수 단위(repo mock, mocktail). 가장 두텁게.
- data: datasource mock으로 매핑·에러변환·멱등.
- presentation: ProviderContainer + usecase override, 위젯/골든(키오스크 포함).
- Edge Function: Deno 테스트(TOTP·세션·멤버십·멱등).

## 9. Git
- 기본 브랜치 직접 커밋 금지 — 기능 브랜치(`feat/…`, `fix/…`).
- 원자적 커밋, 명령형 한 줄 요약. 커밋/푸시는 **사용자가 요청할 때만**.
- 비밀/키/`.env` 커밋 금지.

## 10. ⚠ 출시 차단 게이트 (코드로 우회 불가)
다음 미해결 전에는 **스토어 제출/실데이터 운영 금지**(PRD §8, ADR Follow-ups):
- 위치정보법상 BLE 근접 해당 여부 — **법률 자문**
- 14세 미만 보호자 동의 "교사 확인 갈음" 적법성 — **법률 자문**
개발/테스트는 더미·합성 데이터로 진행. 실제 학생 PII 투입 전 게이트 확인.

## 11. 마일스톤(빌드 순서, PRD §11)
M0 백엔드(스키마+Edge Function+RLS) → M1 대시보드+QR → M2 키오스크 → M3 BLE → M4 나이스+동의/법무 → M5 출시.
각 마일스톤 Exit 기준은 PRD 참조.

## 12. 참고 원본
- `E:/github/banha` — 출결 컨셉·검증 로직(TOTP `qr.ts`, 멱등, Realtime, 상세상태 스키마) 이식 원본. 웹(Next.js)이므로 **로직만 참고, 코드는 Flutter로 재작성**.
