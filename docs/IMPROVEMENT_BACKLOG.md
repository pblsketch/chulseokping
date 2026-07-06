# 출석핑 개선 백로그 (조사 기반)

작성일: 2026-07-06 · 근거 문서: [RESEARCH_DEVICE_BINDING.md](RESEARCH_DEVICE_BINDING.md) · [RESEARCH_TIME_WINDOW.md](RESEARCH_TIME_WINDOW.md) · [RESEARCH_RIROSCHOOL.md](RESEARCH_RIROSCHOOL.md) · [COMPETITOR_ANALYSIS.md](COMPETITOR_ANALYSIS.md)

> 원칙 재확인: 좌표 무수집(PI-3) · 출석 쓰기 Edge Function 전용(BE-0) · 부정 의심은 로그-온리(suspicious_flags, 차단 없음) — 아래 모든 항목은 이 원칙 안에서 설계한다.

---

## P0 — 다음 마일스톤 후보 (출결 신뢰성의 뼈대)

### 1. 세션 수집 시간창 (auto-close + 지각 자동 구분) ✅ 구현 완료 (2026-07-06)

> 구현: sessions.close_at/auto_late_after_minutes + 체크인 3경로 서버 now() 판정(410 session_closed / late 기록, 사유는 교사 사후 확정) + pg_cron 1분 스윕(보조) + 시작 시트 칩(5/10기본/15/수동)·지각 토글(기본 off, +20분 유예)·카운트다운·+5분 연장. late의 사유 미확정(null)을 허용하도록 attendance_reason_check 완화.
사용자 요구 "수업 시작부터 10분만 수집" 대응. 대학 전자출결 데팍토 표준이 "시작 후 10분 출석 / 10~30분 지각"이며, 교육부 지침에는 전국 공통 N분 기준이 **없음**(학교장 재량) → 10분은 하드코딩이 아니라 **기본값 있는 교사 설정**이어야 한다.
- 스키마: `sessions.close_at timestamptz` + `auto_late_after_minutes smallint` (null = 현행 무기한, 하위 호환)
- 서버 강제(패턴 D): 체크인 Edge Function이 매 요청 서버 `now()`로 판정 — `close_at` 초과 → 410 거부, 지각 구간 → `late` 기록. **클라이언트 타이머는 UX 전용, 보안 경계 아님**
- pg_cron 1분 스윕은 화면 정리용 보조(늦어도 판정은 이미 옳음)
- 교사 UX: 세션 시작 시트에 `5분 / 10분(기본) / 15분 / 수동 종료` 칩 + 진행 중 "+5분 연장"
- 상세 설계: RESEARCH_TIME_WINDOW.md §5

### 2. 기기 바인딩 (계정당 active 1기기) ✅ 구현 완료 (2026-07-06)

> 구현: student_devices(서버 발급 uuid → flutter_secure_storage/Keychain·Keystore 보관, 학생당 active 1대) + register_device(최초 자동 active, 재바인딩 pending) + approve_device(교사 원탭 승인·회수) + QR/BLE 체크인 기기 판정. **차단 없음** — UNBOUND_DEVICE_CHECKIN / MULTI_ACCOUNT_SAME_DEVICE / RAPID_DEVICE_REBIND / SHARED_DEVICE 전부 로그-온리.
> **잔여**: device_model·App Set ID 수집은 플러그인 미도입으로 미전송(서버는 수용 준비됨 — v2), 교사 대시보드 suspicious_flags 배지 노출은 P0-3 헤드카운트와 함께.
"친구 폰 대신 들고 오기"는 업계 어느 시스템도 기술로 못 막는다(특허조차 헤드카운트 대조가 유일 대책). 기기 바인딩은 차단이 아니라 **공격 비용 인상 + 증거 확보** 수단.
- 식별자(2025 Play 정책 합규): **서버 발급 UUID를 Keychain(iOS)/Keystore 기반 저장소(Android)에 보관**. SSAID·IMEI·MAC·광고ID·FCM 토큰은 바인딩 키 금지
- 스키마: `student_devices` (학생당 `active` 1대 unique partial index, `pending`/`revoked` 상태) + `attendance_logs.student_device_id`
- 재바인딩 = **교사 원탭 승인**(대학의 "5일 대기"의 K-12 번안 — 눈앞의 학생 확인이 최고의 본인 인증)
- suspicious_flags 추가: `MULTI_ACCOUNT_SAME_DEVICE` / `RAPID_DEVICE_REBIND` / `SHARED_DEVICE`(형제 공유는 정상 케이스 多 — 차단 금지) / `UNBOUND_DEVICE_CHECKIN`
- 상세 설계: RESEARCH_DEVICE_BINDING.md §B-1, B-2

### 3. 세션 마감 헤드카운트 확인 (대리출석의 유일한 실효 대책)
세션 종료 시 교사 태블릿에 "자동 출석 N명 — 실제 인원과 맞나요?" 원탭 스텝. "아니오" → 명렬표 뷰. 대학의 '불시 점검' 관행을 UX로 내재화. 불일치 시 `CHECKIN_HEADCOUNT_GAP` 플래그(로그-온리).

---

## P1 — 법·정책 대응 및 강화

### 4. 키오스크 PIN을 공동 1급 경로로 승격
**2026-03-01 시행 초·중등교육법 개정: 수업 중 스마트기기 사용 원칙 금지** + 중학생 75.9% 등교 시 폰 일괄수거. K-12에서 "학생이 폰을 쥐고 있다"는 BYOD 전제가 법·학칙상 다수 학교에서 성립하지 않음.
- 반별 "키오스크 모드" 프리셋(담임 1회 설정)
- BLE 자동 확정은 포그라운드+본인 조작 시점만(수거함에 모인 폰 오탐 방지 — 현행 Android 자동 제출 정책 재검토 필요)
- 학교 도입 가이드에 학칙 "교육 목적" 예외 조항 표준 문안 제공 → **출시 차단 게이트 법률 자문 항목에 추가**

### 5. QR/minor 토큰 서버 1회성 소비
회전 QR(5초)·회전 minor는 이미 원격 공모를 구조적으로 차단. 여기에 서버가 동일 토큰 재사용을 거부(1회성 소비)하면 스크린샷 전송 공격이 완전 봉쇄됨. (COMPETITOR_ANALYSIS #8)

### 6. 개인정보 문서 정합성 — 리로스쿨 반면교사
리로스쿨의 약점이 우리의 차별점: 위치 권한 사용인데 방침에 위치정보 미기재, Play 데이터 보안 "수집 없음" 허위성 선언, 학교(처리자)↔업체(수탁자) 관계 불명시, 14세 미만 동의를 약관 한 줄 처리, 필수 앱 내 광고. **우리는 반대로**:
- 처리방침에 학교=개인정보처리자 / 출석핑=수탁자 관계·데이터 소유 명시
- 앱 권한 고지 ↔ 처리방침 수집 항목 완전 일치 (BLE 권한의 용도를 방침에 명문화)
- 스토어 데이터 보안 섹션 정확 신고
- 14세 미만 보호자 동의: 서버 강제 + 증빙 보관 (이미 원칙, 방침에 절차 명문화)
- "좌표 무수집"을 검증 가능한 형태(회귀 테스트 존재)로 영업 최전면에

### 7. Wi-Fi 동일 AP 보조 신호 (⚠ 법적 쟁점 — 배포자 고지로 처리)
현장 피드백(대학 LMS 실전 사례) + 중원대 특허 KR101425345B1과 동일 아이디어: 교사·학생 단말이 접속한 Wi-Fi AP가 같으면 동일 공간으로 판정. 단:
- **BSSID(공유기 MAC)는 위치정보법상 위치정보로 취급될 소지** — 법제처 자체 점검 결과 직접 해석례 없음(미해결 쟁점). 오픈소스 방향에 따라 [LAUNCH_GATE_LEGAL_RESEARCH.md](LAUNCH_GATE_LEGAL_RESEARCH.md) §7·§8의 배포자 고지 프레임으로 처리
- K-12 오탐 요인: 단일 SSID 메시망 로밍(옆 반 AP에 붙음), LTE-only 학생 다수 → **차단 조건 금지, 보조 증거로만**
- 프라이버시 보존 구현: 원본 BSSID 미전송 — 양측이 `HMAC(세션 secret, BSSID)` 해시만 제출, 서버는 일치 여부만 비교. 불일치 시 출석은 정상 처리 + `WIFI_AP_MISMATCH` 플래그(로그-온리)
- 권한 비용: Android는 BLE용 FINE_LOCATION을 이미 보유해 추가 부담 없음. iOS는 Access WiFi Information entitlement 필요

### 8. 출석 스파이크 부하 설계
수업 시작 동시 제출 폭주 대비: 멱등키(이미 unique 제약 있음) + 클라이언트 지수 백오프 재시도. 경쟁 앱 최다 장애 리뷰가 "사람 많으면 먹통". (COMPETITOR_ANALYSIS #9)

---

## P2 — UX·사업

### 9. 무폰 학생 UX
키오스크 PIN 화면 문구를 "폰 없이 출석하는 표준 방법"으로(낙인 방지). 초등 고학년 보유율 81%, 학급당 1~2명 무폰 전제.

### 10. 셀프 진단 화면 ("왜 출석이 안 됐나요?")
실패 로그 기반 자가 진단. 경쟁사(개발사 답변 0건·복붙 답변)가 별점을 잃는 지점. (COMPETITOR_ANALYSIS #11)

### 11. 가격·영업 벤치마크 (리로스쿨)
학교당 연 300만 원 내외(2020 기준)가 수용 가격대, 학생·학부모 무료가 표준. 기본 구독 + 부가 업셀, 학교장터(S2B) 수의계약 경로, 사립고 선공략 → 교육청 권고 확보 순. 출석핑은 하드웨어 0원이 진입가 무기. 리로가 안 하는 것: 정규 수업 자동 출석, 초등 시장, 검증 가능한 프라이버시.

---

## M5~M7 — 서비스 운영 기반 기능 (기능 공백 분석, 2026-07-06)

현재 계정·명단·학교 관리가 전부 시드(더미 데이터) 의존 — 실사용을 위한 공백 분석. 순서 의존: M5 → M6 → M7.

### M5 — 계정·온보딩 ✅ 구현 완료 (2026-07-06)

> **결정(사용자, 2026-07-06): 하이브리드 (b)+(c)** — 교사 일괄 생성이 기본, 초대 코드는 "학생이 자기 폰을 계정에 연결하는 기기 연결 코드"로 재정의.
> 구현: `student_link_codes`(해시 저장·48h·1회용) + Edge Function 3종(create_students/issue_link_code/redeem_link_code) + 교사 가입(이메일 OTP)/비밀번호 재설정(recovery OTP) + StudentLinkPage. 학생 비밀번호 재설정 = 담임의 연결 코드 재발급.
- **교사 회원가입**: 이메일+비밀번호, 이메일 인증. 쟁점: 교사 사칭 방지 — 초기엔 자유 가입(자기 학교·학급을 스스로 생성), 학교 관리(M7) 도입 후 관리자 승인으로 강화
- **학생 계정 모델 (최대 설계 결정)**:
  - (a) 학생 자가 가입: 이메일 필요 — K-12 저학년 비현실적, 14세 미만은 가입 시점에 법정대리인 동의 필요
  - (b) **교사 일괄 생성 (권장)**: 학번 기반 내부 이메일 + 초기 비밀번호, Edge Function(service role)으로 생성 — K-12 표준 관행, PII 최소화 정합, 기존 consents 흐름과 자연 통합
  - (c) 초대 코드 참여: 현재 표시만 되는 invite_code의 용도 재정의 필요 (학급 참여용 vs 기기 연결용)
- **비밀번호 재설정**: 교사=이메일 링크, 학생=담임이 리셋(학생 이메일 부재 전제)
- **14세 미만 동의 통합**: 계정 생성 시점과 기존 PI-2 동의 확인의 관계 정리 (배포자 고지와 연동)

### M6 — 학급·명단 관리 ✅ 구현 완료 (2026-07-06, 연도 진급 제외)

> 구현: create_class Edge Function(학급+invite_code+QR secret 동시 발급, 클라 직접 INSERT는 RLS 차단), 학급 이름 변경·보관(archived_at — 삭제 대신 숨김), 명단 제외(student_classes 해제 — 출결·계정 보존). 학생 일괄 등록은 M5 create_students로 커버.
> **잔여**: 연도 진급(새 학년도 재편성)은 데이터 수명주기 정책(M7)과 함께 설계 — 현재는 "구 학급 보관 + 새 학급 생성 + 명단 재등록"으로 수동 대응 가능.
- **학급 CRUD**: ⚠ 학급 생성 시 `class_secrets`(QR secret) 동시 발급 필수 — 현재 시드에서만 만들어져서, 생성 기능만 넣으면 신규 학급은 QR이 조용히 안 되는 버그가 예정돼 있음. service role 필요 → Edge Function으로
- **학생 일괄 등록**: 명단 붙여넣기/CSV → 계정 생성 + student_classes 배정 + PIN 발급을 한 흐름으로
- **학생 제거/전학/졸업**: soft delete(출결 이력은 나이스 근거라 보존), student_classes만 해제
- **연도 진급**: 새 학년도 학급 재편성 — 데이터 수명주기 정책과 함께 설계

### M7 — 학교 단위 관리
- **school_admin 역할 신설**: `user_role` enum 확장 마이그레이션 + `is_school_admin()` RLS 헬퍼 + 정책 확장
- **학교 생성·교사 소속 승인**: profiles.school_id는 있으나 흐름 없음
- **학교 정책·대시보드**: 세션 시간창 기본값, 키오스크 모드 프리셋 등 학교 단위 설정 + 학년/반 통계
- **데이터 수명주기**: 학년도 종료 후 보존·파기 정책 (개보법 보유 기간 — 배포자 고지 §8와 연결)

## 결정 필요 (사용자)
- [x] P0 착수 순서 — 1→2→3 확정 (2026-07-06, 1번 구현 완료)
- [ ] Android BLE 자동 제출 유지 vs 원탭 확인으로 통일 (수거함 오탐 vs 편의성 트레이드오프)
- [x] 지각 자동 구분 기본 off — 구현 반영 (세션 시트 토글 기본 off, 학교장 재량 존중)
