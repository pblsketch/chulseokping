# 출석핑 — 아키텍처 (Clean Architecture)

> 이 문서는 코딩 에이전트·기여자가 반드시 따라야 하는 **구조적 계약**이다. 레이어 경계를 어기는 코드는 리뷰에서 반려한다.

## 1. 원칙

1. **의존성 규칙(Dependency Rule):** 의존은 항상 **안쪽(domain)으로만** 향한다. `presentation → domain ← data`. domain은 그 무엇에도 의존하지 않는다.
2. **domain은 순수 Dart.** `package:flutter`, `supabase`, BLE 플러그인 import 금지. 프레임워크 교체가 domain을 건드리지 않아야 한다.
3. **프레임워크/외부 I/O는 data 레이어에만.** Supabase, BLE, 로컬 DB, 카메라(QR)는 전부 `data/datasources`에 격리.
4. **UI는 usecase만 호출한다.** 위젯이 repository나 datasource를 직접 부르지 않는다.
5. **모든 출석 쓰기는 검증 Edge Function 경유**(PRD BE-0). 클라이언트는 attendance를 직접 INSERT하지 않는다 → data 레이어의 RemoteDataSource가 `functions.invoke()`만 호출.
6. **좌표 미저장(PRD PI-3):** entity·model·payload 어디에도 위/경도 필드를 두지 않는다. BLE는 근접 boolean + 회전 minor만.

## 2. 레이어

### domain (순수 Dart)
- `entities/` — 비즈니스 객체: `Session`, `AttendanceRecord`, `Student`, `ClassRoom`, `KioskDevice`, `ConsentRecord`, `SuspiciousFlag`.
- `value_objects/` — `AttendanceStatus`(present/late/earlyLeave/classAbsent/absent), `AbsenceReason`(recognized/sick/unrecognized/other), `CheckInMode`(qr/pin/ble/manual/list), `SessionType`(homeroom/period).
- `repositories/` — **추상 인터페이스만**: `SessionRepository`, `AttendanceRepository`, `RosterRepository`, `ExportRepository`, `ConsentRepository`.
- `usecases/` — 1 usecase = 1 책임. 예: `StartSession`, `EndSession`, `CheckInByBle`, `CheckInByQr`, `CheckInByPin`, `UpdateAttendanceStatus`, `WatchLiveAttendance`, `BuildNeisExceptionExport`. 입력은 파라미터 객체, 출력은 `Result<T>`.

### data (domain 구현)
- `models/` — DTO. `freezed` + `json_serializable`. **`toEntity()` / `fromEntity()` 매퍼 필수.** DTO와 entity를 섞지 않는다.
- `datasources/` —
  - `SupabaseRemoteDataSource` — PostgREST 읽기(RLS), Realtime 구독, **출석 쓰기는 `functions.invoke('check_in_*')`**.
  - `BeaconScanDataSource` — 비컨 감지(아래 §6).
  - `BeaconAdvertiseDataSource` — 키오스크 비컨 광고.
  - `LocalQueueDataSource` — 오프라인 출석 큐(`drift` 또는 `sqflite`).
- `repositories/` — 위 datasource를 조합해 domain 인터페이스 구현. `Exception → Failure` 변환은 여기서.

### presentation (Flutter UI)
- surface별 폴더: `student/`, `kiosk/`, `teacher/`, `shared/`.
- 상태관리 = **Riverpod 2**. 화면별 `Notifier`/`AsyncNotifier` 컨트롤러가 usecase를 호출. 위젯은 `ref.watch`로 상태만 구독.
- 위젯은 **로직 없음**(표현만). 분기/검증은 컨트롤러·usecase에.

### core (횡단)
- `error/` — `Failure`(sealed: `NetworkFailure`, `AuthFailure`, `ValidationFailure`, `ServerFailure`, `BleFailure`, `ConsentRequiredFailure`).
- `result/` — `sealed class Result<S> { Ok<S>(S value) | Err<S>(Failure failure) }` (또는 `fpdart`의 `Either<Failure,S>` 채택 가능 — 택1 후 일관 사용).
- `di/` — Riverpod provider 모음(usecase·repository·datasource 와이어링). repository/datasource는 provider로 주입, 테스트에서 `overrideWithValue`.
- `router/` — `go_router`. 역할 기반 redirect(§5).
- `theme/` — design.md의 토큰을 Dart로 구현(`AppColors`, `AppTypography`, `AppSpacing`, `AppTheme`).
- `config/` — 환경변수(`--dart-define` / `.env`), 상수.

## 3. 폴더 구조

```
chulseokping/
├─ app/                         # Flutter 앱 (flutter create)
│  ├─ lib/
│  │  ├─ main.dart              # bootstrap + ProviderScope
│  │  ├─ app.dart               # MaterialApp.router + theme
│  │  ├─ core/ { error/ result/ di/ router/ theme/ config/ utils/ }
│  │  ├─ domain/ { entities/ value_objects/ repositories/ usecases/ }
│  │  ├─ data/ { models/ datasources/ repositories/ }
│  │  └─ presentation/ { student/ kiosk/ teacher/ shared/ }
│  └─ test/                     # lib/ 구조를 미러링
├─ supabase/
│  ├─ migrations/               # 스키마(PRD §5): sessions, kiosk_devices,
│  │                            #   student_classes, consents, suspicious_flags,
│  │                            #   attendance_logs 확장
│  ├─ functions/                # 검증 쓰기 Edge Function (Deno/TS)
│  │  ├─ check_in_qr/           # TOTP 재검증 → INSERT
│  │  ├─ check_in_ble/          # 회전 minor + session/device 검증 → INSERT
│  │  └─ check_in_pin/          # 명단 매칭 → INSERT
│  └─ config.toml
├─ docs/ { PRD.md, ARCHITECTURE.md, design.md, ATTENDANCE_POLICY.md, HANDOFF.md, deep-interview-spec.md }
├─ CLAUDE.md
└─ AGENTS.md
```

## 4. 기술 선택 (확정)

| 관심사 | 선택 | 비고 |
|---|---|---|
| 상태관리/DI | **Riverpod 2** (`flutter_riverpod`, `riverpod_annotation`) | provider = DI + 상태. 테스트 override 용이 |
| 라우팅 | **go_router** | 역할 기반 redirect |
| 불변 모델 | **freezed** + **json_serializable** | entity/DTO, 매퍼 |
| 에러 | **sealed `Result`/`Failure`** (또는 `fpdart`) | 예외 누수 금지 |
| 백엔드 | **supabase_flutter** | 읽기=RLS, 쓰기=Edge Function |
| 로컬 큐 | **drift**(권장) 또는 sqflite | 오프라인 출석 |
| 코드젠 | build_runner | freezed/riverpod/json |
| 테스트 | flutter_test, mocktail | 레이어별 |

### BLE 플러그인 (중요 — 정확성)
- **감지(학생앱):** **`dchs_flutter_beacon`**(유지보수 포크). iPhone iBeacon 감지는 **CoreLocation 기반 ranging**이라 `flutter_blue_plus`로는 불가 → 반드시 iBeacon 전용 플러그인 사용. Android도 동일 플러그인으로 ranging.
- **광고(키오스크):** **`beacon_broadcast`** — 갤럭시탭이 iBeacon으로 광고(고정 UUID + class별 major + **회전 minor=TOTP**).
- 일반 BLE/GATT가 필요해지면 그때만 `flutter_blue_plus` 추가. 기본 출석 경로엔 iBeacon 플러그인만.

## 5. 멀티 surface 전략

**단일 Flutter 앱 + 역할 기반 라우팅**(코드베이스 1개, domain/data 공유).

- 인증 사용자 역할: `student` / `teacher` → `go_router` redirect로 각 셸 진입.
- **키오스크는 사용자 역할이 아니라 "기기 모드"**: 갤럭시탭에 교사가 발급한 `device_token`을 등록하면 kiosk 셸로 진입(로그인된 교사 세션을 대행). 키오스크는 화면 고정(screen pinning).
- surface별 presentation은 분리하되 **같은 usecase/repository를 재사용**.
- (선택) 빌드 flavor `student` / `kiosk`로 분리 가능하나 v1은 단일 앱 내 라우팅으로 시작.

## 6. 데이터 흐름 예시

### A. 학생 BLE 자동 출석
```
KioskBeaconAdvertise(고정UUID+major+회전minor=TOTP)
        │  (광고)
        ▼
StudentApp: BeaconScanDataSource(dchs_flutter_beacon)
  → region 진입(iPhone)/RSSI 임계(Android) 감지, 현재 minor 획득
        ▼
CheckInByBle usecase (domain)  ──> AttendanceRepository (domain 인터페이스)
        ▼
AttendanceRepositoryImpl (data) ──> SupabaseRemoteDataSource
        ▼
functions.invoke('check_in_ble', {session_id, major, minor})   # 좌표 없음
        ▼
[Edge Function] minor TOTP 재검증 + active session + 등록 device + class 매칭
        ▼  성공
attendance_logs INSERT (unique(student, session) 멱등)  ──Realtime──> 교사 대시보드
```
- 권한 거부/미감지 → `Result.Err(BleFailure)` → UI가 **QR 폴백 배너** 노출.
- 네트워크 단절 → `LocalQueueDataSource`에 적재 → 복구 시 재전송(서버 멱등으로 1건).

### B. QR 출석
`QrScan(presentation) → CheckInByQr → functions.invoke('check_in_qr',{class_id, totp}) → [EF] verifyTOTP(window:1) → INSERT`.

### C. 나이스 예외 내보내기
`BuildNeisExceptionExport usecase → ExportRepository(읽기, 사유∈{질병,미인정,기타} 필터 — 출석인정·교외체험학습 제외, 교시 포함; ATTENDANCE_POLICY §10.2) → TSV/xlsx/pdf 생성(presentation에서 공유/복사)`.

## 7. 레이어별 테스트 전략

- **domain (usecase·entity):** 순수 단위 테스트. repository는 mock. 가장 많은 커버리지.
- **data (repository·매퍼):** datasource를 mock하여 매핑·에러변환·멱등 검증.
- **presentation (controller·위젯):** Riverpod `ProviderContainer` + usecase override. 골든/위젯 테스트(키오스크 대형 UI 포함).
- **Edge Function:** Deno 테스트로 TOTP·세션·멤버십·멱등 단독 검증(클라이언트와 분리).
- 회귀 가드: "attendance payload에 좌표 필드가 없다", "클라이언트가 attendance_logs에 직접 INSERT하지 않는다"를 테스트로 고정.

## 8. PRD 컴포넌트 ↔ 레이어 매핑

| PRD 컴포넌트 | domain | data | presentation |
|---|---|---|---|
| 학생앱 | CheckInBy* usecases | Beacon/Supabase/Queue DS | student/ |
| 키오스크 | StartSession, advertise | BeaconAdvertise DS | kiosk/ |
| 교사 대시보드 | Watch/UpdateAttendance, Export | Supabase DS, Export | teacher/ |
| 백엔드·검증 | repository 인터페이스 | EF 호출 | — (supabase/functions) |
| 동의·개인정보 | ConsentRepository, ConsentRequiredFailure | consents DS | 온보딩 |

## 9. 금지 사항 (리뷰 반려 트리거)
- domain에서 `package:flutter`/`supabase`/BLE import.
- 위젯이 repository/datasource 직접 호출.
- attendance를 클라이언트에서 직접 INSERT.
- entity/model/payload에 위경도(lat/lng) 필드 추가.
- DTO를 presentation까지 그대로 노출(entity로 매핑할 것).
- 동의 미확인 학생 출석 수집을 UI에서만 막고 서버에서 안 막는 것.
