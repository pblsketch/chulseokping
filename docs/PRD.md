# 출결앱 v1 — PRD (Consensus / ralplan deliberate)

**코드네임:** banha-attend (Flutter 재작성)
**버전:** Consensus v1.1 · 2026-06-25 (v1.1: 나이스 내보내기를 사유 기준으로 정정 — `docs/ATTENDANCE_POLICY.md` §10.2 반영)
**파이프라인:** deep-interview(17% PASSED) → ralplan(Planner→Architect→Critic) → **pending approval**
**리스크 등급:** HIGH (미성년자 PII) → deliberate 모드(프리모템 + 확장 테스트)
**상태:** `pending approval` — 실행 미승인. 본 문서는 명세이며 코드/마이그레이션을 실행하지 않음.

> 합의 참고: Architect/Critic 패스는 메인 오케스트레이터가 직접 수행(서브에이전트 빈 응답). Critic 1차 ITERATE → 7개 수정 반영 → APPROVE.

---

## 1. 개요 / 문제 / 목표

banha 출결 컨셉을 **개별 교사가 셀프 도입**하는 독립 모바일 제품으로 재구성. 클라이언트는 Flutter 네이티브(Android+iOS) 재작성, 백엔드는 Supabase + banha 검증 로직(TOTP·멱등·좌표 미저장) 이식. v1 핵심 가치 = **빠른 출석 + 나이스 이관 최소화**, 차별 기능 = **BLE 근접 자동 출석(Android 우선)**.

### 목표
| G | 목표 | 측정 |
|---|---|---|
| G1 | 교사 1인 5분 내 첫 세션 | 온보딩→첫 세션 중앙값 ≤5분 |
| G2 | 자동 출석(BLE) | **Android** 동일 교실 30초 내 성공률 ≥85% |
| G3 | 나이스 이관 단축 | "예외만 내보내기"로 입력시간 ≥60% 절감 |
| G4 | PII 최소화 | 좌표 저장 0건 |

### 비목표(v1)
나이스 자동연동 / 기관·관리자·MDM / 게이미피케이션 / 강화 부정방지(mock·Play Integrity·차단형) / iOS 백그라운드 자동출석 / GPS 출석 / **시간표(NEIS) 자동 연동**(v1은 교사가 교시·학급을 수동 선택).

> 변경: 교시별(교과) 출결은 **v1 In-Scope로 승격**(사용자 요청). 데이터 단위가 "하루 1행" → "**세션(교시/조회) 단위**"로 바뀜. 타깃 사용자가 담임 + **교과 교사**로 확장됨.

---

## 2. 핵심 시나리오
- **S1 키오스크:** 교사가 갤탭 세션 시작 → 회전 QR + BLE 광고 + PIN/명단 → 학생 자동(BLE)/스캔/PIN 출석 → 대시보드 실시간 → 미출석 수동 처리.
- **S2 BYOD:** 키오스크 없이 교사 폰 → 회전 QR 표시 + 명단 수동(폰 BLE 광고는 불안정→비권장).
- **S3 학생 자동:** Android=백그라운드 가까운 수준 감지 / iPhone=앱 포그라운드 region 진입 시 **원탭 확인**.
- **S4 학생 QR(1급 경로):** 권한·기기 무관 항상 동작.
- **S5 나이스 이관:** 월별 일람표 → 예외만 추출 → 클립보드/엑셀/PDF → 나이스 붙여넣기.
- **S6 교과 교사(교시별):** 교과 교사가 매 수업 시작 시 학급·교시 선택 후 세션 시작 → 등록 학생만 출석 → 교시별 결과(수업 빠짐)·사유 기록 → 나이스 교시별 결과로 이관.

---

## 3. 출석 모드 & 데이터 일관성 (세션 단위 출결 — 교시별 포함)

- **v1 출결 단위 = 세션.** 세션은 두 종류: **HOMEROOM**(담임 조회 출석, 하루 1회) / **PERIOD**(교과 교시별, 1~N교시). 교사가 세션 시작 시 유형·학급·(교시) 선택.
- `attendance_logs`는 **학생 × 세션 1행**(`unique(student_id, session_id)`). 같은 세션 내 상태 변화(조퇴 등)는 **기존 행 status 갱신**(새 행 금지).
- 한 학생이 하루에 **여러 행**(조회 1 + 교시 N)을 가질 수 있음 → 나이스의 *일 출결(담임)* + *교시별 결과(교과)* 구조와 1:1 정합.
- **교과 멤버십:** 교과 세션엔 해당 교과 학급에 등록된 학생만 출석 가능 → banha `036_student_classes`(다대다) 이식.
- **시간표 자동연동은 v2.** v1은 교사가 매 세션 교시·학급 수동 선택(빠르게 1탭).
- 4개 경로(키오스크PIN / 키오스크QR / 학생앱QR / 학생앱BLE)는 세션 내 **공존**, 최초 성공 method 확정, 이후 경로 무시(흔적은 suspicious_flags).
- **기본 모드:** 키오스크 등록 기기 있으면 KIOSK(QR+PIN+BLE), 없으면 BYOD(QR+명단). 세션 중 기기 회수 시 BYOD 강등.

---

## 4. 기능 요구사항 (P0/P1/P2 · Given/When/Then)

### 4.1 학생앱
- **ST-1 로그인(P0):** Supabase Auth, 본인 class 연결.
- **ST-2 BLE 자동출석/Android(P0):** SCAN 권한+세션활성에서 키오스크 비컨(UUID+major+**회전 minor**) RSSI≥임계 안정 감지 → Edge Function에 (session_id, major, minor) 제출 → 검증 통과 시 1건(멱등).
- **ST-3 iBeacon 감지/iPhone(P0):** 위치권한+포그라운드, region 진입 → ranging으로 현재 minor 획득 → **원탭 확인** 후 제출. 백그라운드/종료 시 미보장(명시).
- **ST-4 QR 스캔(P0, 1급 경로):** 회전 QR(TOTP) 스캔 → Edge Function verifyTOTP(±5s) → 출석. 만료 시 "다시 스캔".
- **ST-5 오늘 상태(P1)** / **ST-6 권한 온보딩(P1)** / **ST-7 오프라인 큐잉(P1):** 단절 중 트리거→복구 후 전송, 서버 멱등으로 1건.

### 4.2 키오스크(갤럭시탭/Android)
- **KO-1 기기 등록(P0):** 교사 발급 device_token 입력 → kiosk_devices 등록.
- **KO-2 회전 QR(P0):** TOTP 5s 갱신, payload=class secret 기반.
- **KO-3 BLE 비컨 광고(P0):** beacon_broadcast, **고정 UUID + class별 major + 회전 minor(TOTP)**. 세션 종료 시 광고 중단.
- **KO-4 PIN 체크인(P0)** / **KO-5 명단 탭(P1, 교사 모드)**.
- **KO-6 화면 고정(P0, 소프트):** Android screen pinning(lockTask, 비-MDM) + 교사 PIN 해제. **완전 잠금 아님(우회 가능)을 문서·UX에 명시, 교사 근접 권고.**
- **KO-7 키오스크 현황 미러(P2).**

### 4.3 교사 대시보드
- **TE-1 세션 시작/중단(P0)** / **TE-2 실시간 현황(P0, Realtime ≤3s)** / **TE-3 수동 수정(P0, updated_by/at)** / **TE-4 월별 일람표(P0, 세션유형·교시 필터 + 교시 드릴다운)** / **TE-5 나이스 예외 내보내기(P0)** / **TE-6 명단·PIN·동의(P0, 4.5 연계)** / **TE-7 키오스크 기기 관리(P1, revoke)** / **TE-8 의심 로그 능동 배지(P1):** 대시보드 상단에 미검토 플래그 배지 노출(교사가 안 찾아도 보이게 — R-A 수정).

### 4.4 백엔드·검증 (Supabase) — **쓰기는 Edge Function 전용 (R-A3)**
- **BE-0 출석 쓰기 게이트(P0):** **클라이언트는 attendance_logs에 직접 INSERT 불가(RLS deny).** 모든 출석은 검증 Edge Function(service role)만 기록.
- **BE-1 TOTP 재검증(P0)** / **BE-2 멱등 중복방지(P0, unique student×session)** + 교과 세션은 student_classes 멤버십 검증 / **BE-3 BLE 검증(P0):** active session + 등록 device + class 매칭 + **회전 minor TOTP 검증**.
- **BE-4 RLS(P0):** 학생=본인 read, 교사=class 범위 CRUD, attendance write=service role only.
- **BE-5 세션 수명주기(P0):** 자동 만료, BLE 광고 좀비 방지.
- **BE-6 부정 로깅(P1):** 로그-온리.

### 4.5 동의·개인정보 — **서버 강제 (R-A4)**
- **PI-1 처리방침 동의(P0)** / **PI-2 보호자 동의 교사 확인(P0):** 14세 미만 등록 시 필수 체크. **미동의 학생은 Edge Function이 출석 수집 거부(서버 강제, UI만 아님).**
- **PI-3 좌표 미저장(P0):** 모든 경로 lat/lng 0. BLE=근접 boolean+minor만. *좌표 저장 시도 감지 시 즉시 경보.*
- **PI-4 데이터 최소화·보존정책(P1)** / **PI-5 법률 자문 하드 게이트(P0):** 위치정보법·14세 미만 자문 미완 시 **스토어 제출 차단**.

---

## 5. 데이터 모델 (Supabase, banha 이식 + 수정)

`attendance_logs`(banha 004+034 이식): method `('QR','PIN','BLE','MANUAL','LIST')`(GPS 제거), status 5종, absence_type 4종, reason_code/detail, document_submitted, updated_at/by, **+session_id(필수)**, **+kiosk_device_id**, **unique(student_id, session_id)**(세션=교시/조회 단위 — date·period는 session에서 파생), **좌표 컬럼 없음**, **클라 INSERT RLS deny**.

- `sessions`(id, class_id, teacher_id, **type HOMEROOM/PERIOD**, **period smallint null**(PERIOD일 때 교시), date, mode KIOSK/BYOD, status ACTIVE/ENDED, started/ended_at, totp_secret_ref) — 한 학생은 하루에 조회 1 + 교시 N 세션에 각각 출결.
- `student_classes`(student_id, class_id) — banha 036 이식. 교과 세션은 등록 학생만 출석 허용.
- `kiosk_devices`(id, class_id, teacher_id, device_token unique, beacon_major, **beacon_minor는 회전(서버 시간기반 파생, 저장은 base secret만)**, revoked, last_seen_at).
- `suspicious_flags`(attendance_log_id, flag_type, evidence jsonb — **RSSI/델타 최소·보존기간 제한, 좌표 제외**) — 차단 없음.
- `consents`(subject_id, policy_version, guardian_confirmed_by, consented_at) — 미존재 시 서버가 수집 거부.

---

## 6. 나이스 내보내기 (사유 기준 — ATTENDANCE_POLICY §10.2)
- **집계 대상(포함):** 사유∈{**질병, 미인정, 기타**}인 결석/지각/조퇴/결과. PRESENT 제외.
- **집계 제외:** 사유=**출석인정**(경조사·감염병·천재지변·학폭피해 등)은 NEIS상 출석 처리 → 미포함. **교외체험학습**은 출석인정이면서 학생부 미기재 → 내보내기 제외, 별도 목록으로만 관리.
- 행 컬럼: 학번·이름·날짜·**교시(조회=일과)**·상태(한글)·사유(질병/미인정/기타)·세부사유·증빙제출. 정렬 학생→날짜→교시, 월 필터. HOMEROOM→나이스 일 출결, PERIOD→나이스 교시별 결과로 매핑.
- 형식: **클립보드 TSV + 엑셀(.xlsx, 시트2=집계) P0**, PDF P1. 내부값(RSSI/minor/좌표) 미포함.
- G/W/T: NEIS 집계 대상(사유∈{질병,미인정,기타}) N건 → 정확히 N행. PRESENT·출석인정·교외체험학습 0행.

---

## 7. 보안·부정방지 (정직한 재서술 R-A2)
- **신뢰 모델 = 교사 인-더-루프.** v1 기술적 부정방지는 약함을 전제로 설계. 마케팅에서 "강한 부정방지"로 과대선전 금지.
- 계층: ① TOTP 5s(QR + BLE 회전 minor) — 재생창 최소화(주 방어) ② 서버 재검증(Edge Function) ③ 교사 실시간 가시성+의심 배지(주 방어) ④ BLE 근접 = **편의**(자기보고라 단독 부정방지 아님).
- 정책: 의심(BLE 없이 QR만, 동일 PIN 다기기, 만료 근접 대량)은 **차단 없이 suspicious_flags 기록 + 대시보드 배지**. v2에서 mock 탐지/Play Integrity/차단형.

---

## 8. 개인정보·법규 (하드 게이트 R-A7)
- **위치정보법:** 좌표 미수집 설계로 방어하되 **BLE 근접도 '위치정보' 해석 여지 있음 → 아키텍처가 회피를 단정하지 않음.** PI-5 자문으로 확정.
- **14세 미만:** "교사 확인 체크"가 법정대리인 동의로 충분한지 자문 필수. 불충분 시 **보호자 직접 동의 흐름을 범위 승격**(스코프 변경 트리거).
- 데이터 최소화: 식별자+상태+시각+방식. emotion·RSSI raw·좌표는 정본 제외.

---

## 9. 비기능
출석 처리 P95 ≤30초(자동감지 포함) / Realtime ≤3초 / 오프라인 큐잉 중복 0 / Android 8(API26)+·12 권한분리(neverForLocation) / WCAG AA·키오스크 ≥24sp·색+텍스트 라벨 / 세션 자동만료·BLE 좀비 방지.

## 10. 디자인
밝고 미니멀·도구형. 3 surface(학생앱/키오스크/대시보드) 컬러토큰·타이포·상태색(출석=중립/지각=주의/결석=경고) 공유. 키오스크=원거리 가독·단일동작. 색맹 안전+텍스트 병기.

---

## 11. 마일스톤 & KPI
- **M0 기반 이식:** 스키마 마이그레이션, TOTP/멱등 Edge Function, RLS(쓰기 차단). *Exit: QR 출석 1건 멱등 기록, 클라 직접 INSERT 거부 확인.*
- **M1 대시보드+QR:** 세션, 실시간, 학생 QR, 수동수정. *Exit: QR만으로 한 수업 완결.*
- **M2 키오스크:** 회전 QR, PIN/명단, 화면고정, 기기등록.
- **M3 BLE:** 비컨 광고(고정UUID+회전minor) + Android 감지 + iPhone 원탭확인 + BE-3. *Exit: Android ≥85%.*
- **M4 나이스+동의/법무:** 일람표, 예외 3형식, 동의 서버강제, **법률 자문 게이트 통과**.
- **M5 출시:** 스토어(Apple$99/Google$25), 교사 베타 파일럿, 접근성·저사양.

| KPI | 목표 |
|---|---|
| 첫 세션 시간 | ≤5분 |
| BLE 자동출석 | Android ≥85% / **iPhone(원탭) ≥ —, 파일럿 후 설정** |
| 나이스 입력 절감 | ≥60% |
| 좌표 저장 | 0 |
| 멱등 위반 | 0 |

---

## 12. 프리모템 (3)
- **PM-1 BLE 신뢰성 붕괴:** 다기종 실측 RSSI 보정, iPhone 포그라운드 정직 고지, QR 1급 폴백, Android<85% 시 출시 보류.
- **PM-2 개인정보 위반 신고:** PI-5 하드 게이트, 좌표0, 불충분 시 보호자 직접동의 승격.
- **PM-3 출석 조작 발각:** 의심 배지 능동 노출, BLE 없는 QR-only 플래그, TOTP 5s, 교사 1회 교육, v2 강화 로드맵.

## 13. 확장 테스트 계획
- **Unit:** TOTP(±5s 경계·잘못된 secret), 멱등(2회→1건), 나이스 추출(사유 기준 — PRESENT·출석인정·교외체험학습 제외, 행수=집계대상수, 내부값 제외; ATTENDANCE_POLICY §10.4 회귀 가드 포함), 동의 가드(consents 없으면 거부), 좌표/ GPS 거부(PI-3 회귀).
- **Integration:** BLE(mock 비컨 session+device+회전minor→기록, 미등록 거부), QR(만료 422), RLS(타학생 차단·클라 직접 INSERT 거부), 세션 만료·키오스크 revoke 거부.
- **E2E:** S1 키오스크 풀(BLE/QR/PIN 각1건→실시간→수동→예외 TSV), S3 Android 자동·iPhone 원탭/백그라운드 실패→QR, S5 한달 더미→예외 추출·집계, 오프라인 중복0.
- **Observability:** method 분포·BLE 성공률(플랫폼별)·P95·멱등충돌·플래그 발생/검토율, 알람(멱등>0·좀비세션·좌표저장시도>0 즉시), 감사(consent·updated_by 이력).

---

## ADR (Architecture Decision Record)

**결정:** Flutter 네이티브(Android+iOS) + Supabase(Edge Function 쓰기 게이트) + **고정 UUID·회전 minor BLE** + 일일 출결 멱등 + 로그-온리.

**Drivers:** ① 미성년자 PII 법적 리스크 ② BLE 자동출석 실현성(iOS 포그라운드 제약) ③ 나이스 이관 효율.

**대안 검토:**
- BLE 회전 payload(전체) → iPhone region 감지 불가로 무효 → **고정 UUID+회전 minor**로 절충 채택.
- MDM 키오스크 → v1 셀프도입 비목표와 충돌, 무효 → screen pinning(소프트) 채택.
- 클라 직접 INSERT(간단) → TOTP 우회 가능, 무효 → **Edge Function 쓰기 전용** 채택.
- 일일 1행 모델 → 교시별 출결 미표현으로 **무효**(사용자 요청 반영) → **세션 단위 출결(`unique student×session`, 세션=교시/조회)** 채택. 시간표 자동연동만 v2.

**Why chosen:** PII 최소화·검증자산 재사용·멱등 흡수·교사 인더루프 원칙에 정합. iPhone 호환과 신선도를 회전 minor로 동시 달성.

**Consequences:** BLE 단독 부정방지 약함(설계상 수용, 교사 가시성으로 보완) / iPhone 자동성은 원탭 수준 / **교시별 출결 지원(세션 단위) — 타깃이 교과 교사로 확장, 대시보드·멤버십(student_classes)·내보내기 복잡도 증가** / 시간표 자동연동 v2 / 법률 자문 통과 전 출시 불가.

**Follow-ups (미해결, 출시 전 선결):**
1. 위치정보법상 BLE 근접 해당 여부 — 법률 자문
2. 14세 미만 "교사 확인 갈음" 적법성 — 법률 자문
3. RSSI 임계·지속시간 기본값 — M3 다기종 실측
4. 데이터 보존기간 수치 — 정책 확정
5. iPhone 자동출석 KPI — 파일럿 후 설정
6. 키오스크 화면고정 해제(교사 PIN vs 생체)

---
**상태: `pending approval`** — 실행하려면 team / ralph / autopilot 중 명시적 선택 필요.
