# CLAUDE.md

Claude Code 전용 지침. **이 프로젝트의 규칙·스택·컨벤션은 [`AGENTS.md`](AGENTS.md)가 단일 진실 원천이다 — 항상 먼저 따른다.** 이 파일은 Claude Code에 특화된 보강만 담는다.

## 먼저 읽을 것 (순서)
1. [`AGENTS.md`](AGENTS.md) — 황금 규칙·스택·컨벤션·명령어·DoD
2. [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — 클린 아키텍처 경계
3. [`docs/design.md`](docs/design.md) — 디자인 토큰
4. [`docs/PRD.md`](docs/PRD.md) — 제품 요구사항 (Consensus v1.1)
5. [`docs/ATTENDANCE_POLICY.md`](docs/ATTENDANCE_POLICY.md) — 2026 출결 처리 지침 (상태/사유·나이스 매핑 근거)

## 절대 잊지 말 것 (요지 재확인)
- **출석 쓰기 = Edge Function 경유.** 클라이언트 직접 INSERT 금지.
- **좌표(lat/lng) 저장·전송 금지.** BLE는 근접 boolean + 회전 minor만.
- **domain은 순수 Dart.** flutter/supabase/BLE import 금지.
- **iPhone iBeacon 감지는 `dchs_flutter_beacon`(CoreLocation).** `flutter_blue_plus` 아님.
- **미성년자 PII 최소화 + 동의 서버 강제.**
- ⚠ **출시 차단 게이트**(위치정보법·14세 동의 법률 자문) 전 실데이터 운영 금지 — 개발은 더미 데이터로.

## Claude Code 작업 방식
- **변경 후 검증 루프:** 코드 수정 → `flutter analyze` → 관련 `flutter test` 실행 → 결과로 완료 판단. 렌더링/실행 산출물은 추측 말고 실제 실행으로 확인.
- **완료 주장은 이 세션의 실제 도구 결과로 뒷받침.** 테스트 실패 시 숨기지 말고 출력과 함께 보고.
- **범위 준수:** 요청된 것만. 곁다리 리팩터·대규모 변경은 먼저 제안 후 승인.
- **모르면 멈춤:** API/플러그인 사용법이 불확실하면 추측 코드 대신 확인(context7 MCP로 라이브러리 문서 조회 가능) 후 진행.
- **파괴적/되돌리기 어려운 작업**(스키마 reset, 대량 삭제, 브랜치 force, 커밋/푸시)은 사용자 승인 후.
- **커밋/푸시는 사용자가 명시 요청할 때만.** 기본 브랜치 직접 작업 금지(기능 브랜치).

## 빠른 명령 (상세는 AGENTS.md §6)
```bash
cd app && flutter pub get && dart run build_runner build --delete-conflicting-outputs
flutter analyze && dart format . && flutter test
```

## 현재 상태
- **PRD pending approval.** 빌드는 마일스톤 M0(백엔드)부터. 빌드 착수는 사용자 승인 후 시작.
- 신규 코드 0 — 본 저장소는 현재 기획/하네스 문서만 존재.
