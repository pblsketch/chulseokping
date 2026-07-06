# 출석핑 — 실기기 테스트 가이드 (M2 키오스크 + M3 BLE)

> 대상: Android 태블릿(키오스크 겸 개발 기기) + 로컬 Supabase 스택.
> 모든 데이터는 seed 더미 계정만 사용한다 — 실 학생 PII 금지 (AGENTS.md §10).

## 0. 사전 조건 (PC)
- Docker Desktop 실행 + `supabase start` (프로젝트 루트에서)
- `supabase db reset` 으로 더미 데이터 적용
- PC와 태블릿이 **같은 Wi-Fi**에 연결
- PC IP 확인: `ipconfig` → IPv4 주소 (예: 192.168.0.10)
- Windows 방화벽에서 54321 포트 인바운드 허용 (또는 테스트 중 일시 허용)

## 1. 태블릿 준비
1. 설정 → 휴대전화 정보 → 빌드번호 7회 탭 → 개발자 모드
2. 개발자 옵션 → USB 디버깅 켜기
3. USB 연결 → `flutter devices` 로 인식 확인

## 2. 앱 실행
```powershell
cd app
C:\dev\flutter\bin\flutter.bat run `
  --dart-define=SUPABASE_URL=http://<PC-IP>:54321 `
  --dart-define=SUPABASE_ANON_KEY=<supabase status의 ANON_KEY>
```
> `supabase status -o env` 로 ANON_KEY 확인. 키는 커밋 금지.

## 3. 더미 계정 (seed.sql)
| 역할 | 이메일 | 비밀번호 | 비고 |
|---|---|---|---|
| 교사 | dummy-teacher@example.com | password123 | 더미 1학년 1반 담당 |
| 학생1 | dummy-student1@example.com | password123 | 동의O, 멤버 |
| 학생2 | dummy-student2@example.com | password123 | **동의X** → 출석 403 확인용 |
| 학생4 | dummy-student4@example.com | password123 | 동의O (BLE 테스트 권장) |

시드 키오스크 토큰: `dummy-kiosk-token-001` (major 101)

## 4. 시나리오 체크리스트

### A. 교사 + QR (M1)
- [ ] 교사 로그인 → 학급 카드 → 세션 시작(조회)
- [ ] 세션 화면: 회전 QR 5초 갱신, 명단 표시
- [ ] (두 번째 기기/학생 계정) QR 스캔 → 즉시 대시보드에 출석 반영 (≤3초)
- [ ] 학생 타일 탭 → 지각+질병 수동 수정 → 반영 확인
- [ ] 미출석 학생 → 결석+미인정 수동 처리

### B. 키오스크 (M2)
- [ ] 교사: 학급 카드의 태블릿 아이콘 → 기기 발급 → 토큰 확인
- [ ] 태블릿: 로그인 화면 → "키오스크 모드" → 토큰 입력 → 학급명 표시
- [ ] 세션 시작 시 10초 내 특대 QR 자동 표시 / 종료 시 대기 화면 복귀
- [ ] "학번+PIN으로 출석": 학번 10105 + PIN 4321 → 출석
  (사전 준비: PIN 해시는 통합 테스트가 심는 방식이라, 실기 테스트 전에
  `deno test supabase/tests/integration_m0_test.ts` 를 한 번 돌려두거나 학생 PIN 설정 UI(M4+)를 기다린다)
- [ ] 화면 고정: 홈/뒤로 버튼 이탈이 막히는지(소프트 — 시스템 제스처로는 해제 가능)
- [ ] nRF Connect 앱(별도 폰)으로 iBeacon 광고 확인: UUID 4CC5A2E8-...,
  major=101, **minor가 5초마다 바뀌는지**

### C. BLE 자동 출석 (M3) — BYOD: 교사 기기가 비컨
- [ ] 교사 태블릿: 세션 시작 → QR 아래 "비컨 송신 중 — 근처 학생은 자동 출석돼요" 배지
  (첫 실행 시 "근처 기기" 블루투스 권한 팝업 → 허용)
- [ ] 학생 폰(학생4): 위치·블루투스 권한 허용 → "교실 비컨(핑) 감지 중..." 표시
- [ ] 교실 거리(수 m)에서 **자동 출석** → 대시보드 BLE 반영, 30초 내 (G2 목표)
- [ ] 비컨이 없을 때(교사 태블릿 배지 꺼짐) 25초 후 "비컨을 찾지 못했어요" + 다시 감지 버튼
- [ ] 멀리(다른 방)에서는 감지 안 됨 → RSSI 임계(-75dBm) 보정 필요 시
  `BeaconSightingStabilizer` 기본값 조정 (ADR follow-up #3 실측)
- [ ] 이미 QR로 출석한 학생의 BLE 재감지 → 중복 행 없음(멱등), suspicious_flags 기록
- [ ] 학생2(동의X)로 시도 → "보호자 동의 확인이 필요해요" + QR 안내
- [ ] (키오스크 방식도 동일하게 동작 — 시나리오 B의 광고를 켠 상태로 위 항목 반복 가능)

### D. 실시간 반영 (2026-07-06 회귀 수정 확인)
- [ ] 학생 폰 홈을 열어둔 채 교사가 세션 종료 → 새로고침 없이 "아직 세션이 없어요"로 전환
- [ ] 교사가 세션 재시작 → 학생 홈이 자동으로 새 세션 카드로 전환
- [ ] 학생이 QR로 출석 → 학생 홈 카드가 즉시 "출석되었어요!"로 전환
- [ ] 교사 대시보드 카운트(출석 n/m)가 3초 내 갱신

## 5. 알려진 한계 (v1 명시 사항)
- iPhone은 포그라운드 원탭 확인(자동 미보장) — 별도 iOS 기기 필요, 맥에서 빌드.
- 화면 고정은 소프트(screen pinning) — 완전 잠금 아님.
- BLE 광고는 태블릿 기종에 따라 미지원일 수 있음(`checkTransmissionSupported`) → QR/PIN 폴백.
