# Deep Interview Spec: 출결앱 (banha 출결 컨셉 → Flutter 네이티브)

## Metadata
- Interview ID: di-banha-attend-001
- Rounds: 8
- Final Ambiguity Score: 17%
- Type: greenfield (banha를 설계 레퍼런스로 참고하는 신규 앱)
- Generated: 2026-06-25
- Threshold: 0.2
- Threshold Source: default
- Initial Context Summarized: no
- Status: PASSED
- Reference Codebase: E:/github/banha (세션 내 분석 완료, 백엔드/로직 재사용)

## Clarity Breakdown
| Dimension | Score | Weight | Weighted |
|-----------|-------|--------|----------|
| Goal Clarity | 0.86 | 0.40 | 0.344 |
| Constraint Clarity | 0.85 | 0.30 | 0.255 |
| Success Criteria | 0.78 | 0.30 | 0.234 |
| **Total Clarity** | | | **0.833** |
| **Ambiguity** | | | **0.167** |

## Topology
| Component | Status | Description | Coverage / Deferral Note |
|-----------|--------|-------------|--------------------------|
| 1. 학생 출석 클라이언트 | active | Flutter 앱(Android+iOS): QR 스캔 + BLE 근접 자동 출석, 아이폰=감지 역할 | AC: QR/BLE 체크인, 아이폰 감지 동작 |
| 2. 교실 태블릿 키오스크 | active | 갤럭시탭(Android): 회전 QR 표시 + PIN/명단 체크인 + BLE 비컨 광고 + 화면 고정 잠금 | AC: 회전 QR, PIN 체크인, 이탈 방지 |
| 3. 교사 대시보드 | active | 세션 시작/중단, 실시간 현황, 월별 조회, 수동 수정, 나이스 내보내기 | AC: 월별 일람표 + 예외만 내보내기 |
| 4. 백엔드 & 검증 | active | Supabase(스키마/RLS/method 확장) + 다중검증 + 로그-온리 부정기록 | AC: 거리·근접·회전코드 재검증, 중복차단, 의심 로그 |
| 5. 동의·개인정보 | active | 최소 동의 플로우 + 데이터 최소화(좌표 미저장) | AC: 처리방침+보호자동의 확인, 항목 최소 |
| 게이미피케이션(밈/시각화/보상) | deferred | 학생 몰입용 보상 시스템 | v2 확장 — 사용자 '확장'으로 명시 (2026-06-25) |
| 학교/교육청 기관 도입(관리자·MDM) | deferred | 전교 일괄 배포·관리자 콘솔 | v2 — v1은 개별 교사 셀프 도입 |
| 강화 부정방지(mock탐지/Play Integrity) | deferred | 루팅/스푸핑 능동 차단 | v2 — v1은 로그-온리 |
| 나이스 자동연동 | deferred | NEIS/교무시스템 동기화 | 미채택 — 공개 API 부재로 비현실적 |

## Goal
개별 교사가 **자기 반 출석을 30초 내에** 받고(교실 태블릿 키오스크 또는 학생 폰 자동 출석), 그 결과를 **나이스(NEIS)로 쉽게 옮기도록** 월별 조회·예외만 내보내기를 제공하는, **Android+iOS 네이티브(Flutter)** 출결 도구. BLE 근접 기반 "자동 출석"이 핵심 차별점이며, 학교마다 다른 폰 정책에 대응하기 위해 키오스크 모드와 학생 폰 모드를 모두 지원한다. 디자인은 밝고 미니멀한 도구형.

## Constraints
- **Flutter 네이티브 필수** (PWA 불가 — BLE 광고/감지 때문)
- **Android + iOS 동시 출시** 목표
- **개별 교사 셀프 도입** — v1에 학교 관리자·MDM·교육청 트랙 없음
- **갤럭시탭 = BLE 비컨 역할**, 학생 **아이폰 = 감지 역할**(아이폰은 비컨 광고하지 않음)
- **iOS BLE는 포그라운드 전용** — 백그라운드 무인 자동출석은 보장하지 않음(사양/마케팅에 명시)
- **데이터 최소화** — GPS/근접 좌표 미저장, 수집 항목 최소(이름/번호/출결/사유)
- **밝고 미니멀 디자인** — 키오스크·교사 대시보드·학생 폰 3 surface가 일관된 톤 공유
- 백엔드는 **Supabase 재사용**(banha의 Auth/DB/Realtime/RLS/거리·중복 재검증 로직 이식)
- **출시 전 법률 자문 필수** — 미성년자 개인정보(14세 미만 보호자 동의), 위치정보법(LBS) 적용 여부

## Non-Goals (v1)
- 게이미피케이션(밈/시각화/보상 시스템)
- 학교/교육청 기관 도입, MDM 일괄배포, 관리자 콘솔
- 나이스(NEIS) 자동 동기화/연동
- 강화 부정방지(mock-location 탐지, Play Integrity 능동 차단)
- 앱을 공식 출결 원장(source of truth)으로 사용 — v1은 보조 도구

## Acceptance Criteria
- [ ] 교사가 학급 생성 → 초대코드 발급 → 학생 가입 가능
- [ ] 교사가 출석 세션을 시작/중단할 수 있고, 실시간 현황을 본다
- [ ] 키오스크(갤탭): ≤5초 갱신 회전 QR 표시 + 학생 PIN/명단 체크인 동작, 화면 고정으로 앱 이탈 방지
- [ ] 학생 앱: QR 스캔 출석 + BLE 근접(임계 RSSI 내) 자동 출석, **아이폰에서 감지 정상 동작**
- [ ] 서버: 거리/근접·회전코드 재검증, 중복 출석 차단, 의심 케이스는 **차단 없이 로그 기록**
- [ ] 출결 상태(출석/지각/결석/조퇴) + 사유(질병/미인정/기타/인정) 기록
- [ ] 월별 일람표 화면 조회 + **예외(결석·지각·조퇴)만** 내보내기(엑셀/PDF/클립보드 복사)
- [ ] 동의: 가입 시 처리방침 동의 + 미성년자 보호자 동의 확인 체크, **좌표 미저장**
- [ ] 밝고 미니멀 디자인이 3 surface에 일관 적용

## Assumptions Exposed & Resolved
| Assumption | Challenge | Resolution |
|------------|-----------|------------|
| 첫 사용자가 학교(기관)일 것 | "남는 갤탭/폰정책은 학교를 시사하나, 실제 첫 사용자는 개별 교사 아닌가?" | 개별 교사 셀프 도입으로 확정, 기관 트랙 v2 |
| 앱이 공식 출결 원장 | "최종 데이터는 어디로 가나?" | 보조 도구 + 나이스 이관 최적화(자동연동 X) |
| 단일 모드면 충분 | "폰 수거 학교엔 학생앱 무용지물" | 키오스크 + 학생앱 둘 다 풀 지원(C) |
| BLE는 정확도에 필수 | (Contrarian) "회전 QR이 이미 교실 단위 정확도를 줌. BLE 빼도 되나?" | BLE는 '자동 출석' 핵심 차별점 → v1 유지 |
| 동의·개인정보는 기관급 구현 | (Simplifier) "개별 교사 보조도구에 기관급은 과하지 않나?" | 최소 동의 + 데이터 최소화, 법률 자문 명시 |
| 부정방지는 강하게 차단 | "정상 학생 오차단 위험" | 로그-온리: 기록만, 차단은 v2 |
| 디자인 방향 미정 | "v1 필수 제약인데 비어 있음" | 밝고 미니멀(도구형, 교사 신뢰·가독성) |

## Technical Context
- **백엔드 재사용(Supabase):** banha의 `attendance_logs`(student_id, class_id, date, method, status, emotion, check_in_time, unique 제약), 거리검증(`isWithinGeofence`/Haversine), TOTP 회전코드(`qr.ts`, period 5s), 교사 브로드캐스트/수신(Realtime 채널), Admin 클라이언트 중복검증 패턴, 좌표 미저장 구조.
- **확장 필요:** `method` enum에 `KIOSK_PIN`/`KIOSK_QR`/`PHONE_QR`/`PHONE_BLE` 추가, 출결 상태(LATE/ABSENT/EARLY_LEAVE) + 사유 분류 컬럼, 키오스크 기기 인증 토큰, 부정 의심 로그 테이블.
- **클라이언트(신규 Flutter):** `flutter_blue_plus`(BLE 감지/central), `beacon_broadcast`(갤탭 비컨 광고/peripheral), QR(스캔/표시), `supabase_flutter`, 키오스크 잠금(Android 화면 고정/Knox 옵션).
- **BLE 역할 배치:** 갤탭(Android)=비컨 광고 + 학생 폰=감지. 아이폰은 CoreLocation 기반 iBeacon 감지(포그라운드)로 동작.
- **빌드/출시:** Apple Developer($99/년)+맥/클라우드빌드, Google Play($25). iOS purpose strings, Android 12 BLE 권한 분리(SCAN/ADVERTISE/CONNECT, neverForLocation).

## Ontology (Key Entities)
| Entity | Type | Fields | Relationships |
|--------|------|--------|---------------|
| School | supporting | name, code | has many Class |
| Teacher | core domain | id, name, email | owns Class, opens AttendanceSession |
| Student | core domain | id, name, student_number, pin | belongs to Class, has AttendanceRecord |
| Guardian | supporting | consent_confirmed | linked to Student (consent) |
| Class | core domain | id, teacher_id, invite_code, qr_secret | has many Student, AttendanceSession |
| AttendanceSession | core domain | id, class_id, started_at, mode | produces AttendanceRecord |
| AttendanceRecord | core domain | student_id, class_id, date, method, status, reason, check_in_time | belongs to Session/Student |
| AttendanceStatus | enum | PRESENT/LATE/ABSENT/EARLY_LEAVE | field of AttendanceRecord |
| AbsenceReason | enum | 질병/미인정/기타/인정 | field of AttendanceRecord |
| CheckInMode | enum | KIOSK_PIN/KIOSK_QR/PHONE_QR/PHONE_BLE | field of Session/Record |
| KioskDevice | external system | device_token, class_id | bound to Class, advertises BLE |
| RotatingCode | supporting | totp, period(5s) | derived from Class.qr_secret |
| BleProximitySignal | supporting | rssi, threshold | between KioskDevice and Student phone |
| ConsentRecord | supporting | policy_agreed, guardian_confirmed | per Student |
| NeisExport | supporting | month, format(xlsx/pdf/clipboard), exceptions_only | derived from AttendanceRecord |
| FraudAuditLog | supporting | suspicion_type, logged_at, blocked=false | references AttendanceRecord |

## Ontology Convergence
| Round | Entity Count | New | Changed | Stable | Stability Ratio |
|-------|-------------|-----|---------|--------|----------------|
| 1 | 7 | 7 | - | - | N/A |
| 2 | 9 | 2 | 0 | 7 | 78% |
| 3 | 10 | 1 | 0 | 9 | 90% |
| 4 | 12 | 2 | 0 | 10 | 83% |
| 5 | 13 | 1 | 0 | 12 | 92% |
| 6 | 14 | 1 | 0 | 13 | 93% |
| 7 | 15 | 1 | 0 | 14 | 93% |
| 8 | 15 | 0 | 0 | 15 | 100% |

## Interview Transcript
<details>
<summary>Full Q&A (8 rounds + Round 0)</summary>

### Round 0 — Topology
**Q:** 최상위 구성요소 5개 확인 + 동의(#5) v1 포함 여부
**A:** 게이미피케이션(밈/시각화/보상)은 v2 확장으로 보류, 디자인은 v1 필수 제약. (5개 활성 토폴로지 + 디자인 제약 잠금)

### Round 1
**Q:** v1을 누가 처음 도입하는 그림? (개별교사/학교/둘다)
**A:** (A) 개별 교사 셀프 도입. + "출석 받은 뒤 조회·관리도 가능해야 함" 추가
**Ambiguity:** 68%

### Round 2
**Q:** 출석 데이터 최종 목적지? (보조도구/공식원장/나이스연동)
**A:** (A) 보조 도구 — 대신 나이스에 옮기기 쉽게 최적화
**Ambiguity:** 44%

### Round 3
**Q:** v1 범위 — 키오스크 단독 / 학생앱 포함 / 둘 다?
**A:** (C) 둘 다 풀 지원
**Ambiguity:** 37%

### Round 4 (Contrarian)
**Q:** v1에서 BLE를 빼면 잃는 게 있나?
**A:** (B) BLE 유지 — 자동 출석이 핵심 차별점
**Ambiguity:** 32%

### Round 5
**Q:** 나이스 이관 최적 출력 형태? + 사유 분류 입력?
**A:** (C) 월별 일람표 조회 + 예외만 내보내기 + 엑셀/PDF/클립보드 (사유 분류 포함으로 해석)
**Ambiguity:** 27%

### Round 6 (Simplifier)
**Q:** 동의·개인정보 최소화 범위?
**A:** (A) 최소 — 데이터 최소화 우선, 좌표 미저장, 보호자 동의 교사 확인
**Ambiguity:** 22%

### Round 7
**Q:** 부정출석 방어 강도?
**A:** (C) 로그-온리 — v1은 기록만, v2에서 강화
**Ambiguity:** 21%

### Round 8
**Q:** 디자인 방향?
**A:** (B) 밝고 미니멀
**Ambiguity:** 17% → PASSED

</details>
