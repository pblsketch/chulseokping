# 한국 전자출결 "대리출석 방지" 업계 관행 조사 + 출석핑 설계 제안

조사일: 2026-07-06 · 방법: WebSearch/WebFetch (나무위키는 Cloudflare 차단으로 본문 미확보 — 우회 시도 실패, 대체 출처로 보완)

---

## Part A. 발견 사실

### A-1. "친구 기기 대신 들고 오기" 문제 — 업계는 사실상 못 막는다

**공격의 실재.** 대학 전자출결(블루투스 폰투폰/비콘 방식)에서 "친구에게 핸드폰을 맡기거나, 강의실 문 앞에서 출결 체크 시작을 기다렸다가 블루투스 연결 가능한 거리에서 출석만 찍고 가는" 수법이 대학 언론에 공공연히 보도된다. 학생 출결 불시 점검(수동 재확인)이 필요하다는 지적과 함께다 ([호서대신문](https://news.hoseo.ac.kr/news/articleView.html?idxno=902)). 덕성여대신문도 대리출석·"출튀"(출석 체크 후 이탈)가 대형 강의·강사 수업에서 빈번하며, 교수 개인이 시작·종료 시점 재확인, 조교 활용, 수업 중 질문 등으로 대응할 뿐 대형 강의에서는 실질 제재가 어렵다고 보도했다 ([덕성여대신문](https://www.dspress.org/news/articleView.html?idxno=5311)).

**기술적 방어의 물리적 한계 — 업계 스스로 인정.** 블루투스 출석체크 특허(KR101658577B1)는 "학생이 부재인 상태에서 휴대전화만 강의실에 있는 경우에도 출석체크가 가능해지는 점을 악용할 우려"를 명시하고, 그 대책으로 앱이 아니라 **별도의 실제 인원수 카운트 장치**(출석학생수 > 실제학생수면 대리출석 경보)를 제안한다 ([Google Patents KR101658577B1](https://patents.google.com/patent/KR101658577B1/ko)). 즉 "폰 N대를 한 사람이 들고 왔는지"는 RF 신호만으로는 구분 불가능하고, 업계가 아는 유일한 자동 대책은 **사람 수 세기(헤드카운트) 대조**라는 뜻이다.

**실제 벤더들의 접근 = 억제(deterrence) + 절차, 차단 아님.**
- **유체크(UCheck/UCheckPlus, 리베카)**: 2012년 국내 최초 블루투스(비콘) 실내 위치인증 출석 솔루션. "친구 폰 맡기기"를 기술로 차단한다는 주장은 어디에도 없음. 대신 계정-기기 1:1 바인딩(아래 A-2)과 학칙 처벌 경고로 억제 ([UCheck Plus Play 스토어](https://play.google.com/store/apps/details?id=com.libeka.attendance.ucheckplusstud), [경기대 안내](https://www.kyonggi.ac.kr/www/contents.do?key=5127)).
- **씨드시스템(xidsys)**: 하드웨어 없는 폰투폰 블루투스 방식, 전국 100여 대학 60만 사용자. 역시 근접성 인증까지만 — 소지자 본인 여부는 검증 범위 밖 ([씨드시스템](https://xidsys.co.kr/)).
- **QR 방식**: 경북대 LMS는 QR을 **3초 간격 자동 갱신**해 "QR 사진 전송" 형태의 원격 대리출석을 차단 ([경북대 공지](https://cse.knu.ac.kr/bbs/board.php?bo_table=sub5_1&wr_id=28827)). 학원용 에듀허브도 "수초에 한 번씩 새 QR"로 부정출결 예방을 광고 ([에듀허브](https://eduhub.co.kr/)). 그러나 회전 QR도 **폰 자체를 대신 들고 온 경우**는 못 막는다(폰이 현장에 있으므로).
- **처벌·법 억제**: 대리출석은 형법 제314조(업무방해, 5년 이하 징역/1,500만원 이하 벌금) + 학칙상 성적 취소·근신·정학·제적 대상으로 공지된다 ([부산외대 공지](https://www.bufs.ac.kr/bbs/board.php?bo_table=stat_board&wr_id=38), [단대신문](http://dknews.dankook.ac.kr/news/articleView.html?idxno=9365)). 최근에는 대학 학생증 자체를 20만원에 대여하는 시장까지 보도됨 ([머니투데이 2026-05](https://www.mt.co.kr/society/2026/05/31/2026053017035326496)).

**감지 휴리스틱으로 업계가 실제 쓰는 것:**
| 휴리스틱 | 사용처 | 한계 |
|---|---|---|
| 계정 1개를 복수 단말에 로그인 → 강제 로그아웃 + 오류 | 세종대 U-Check | 반대 방향(한 단말 복수 계정)은 별도 감지 필요 |
| 단말기 변경 신청이 잦음/번갈아 신청 → "부정 사용 간주", 승인 거부 | 세종대·명지대 U-Check | 사후 절차적 억제 |
| 출석 인원 vs 실제 인원 카운트 대조 | 특허 제안(KR101658577B1) | 별도 장치 필요, 상용 보급 미미 |
| 교사/교수의 불시 재점검·중간체크·퇴실체크 | 전 대학 공통 관행 | 자동화 불가, 노동 비용 |
| QR 수초 단위 회전 | 경북대 LMS, 에듀허브 등 | 원격 공모만 차단, 기기 지참형은 못 막음 |

**결론(A-1): "한 사람이 폰 2대 지참"은 국내 어떤 상용 시스템도 기술적으로 차단하지 못하며, 업계 표준은 (1) 기기 바인딩으로 공격 비용 올리기, (2) 이상 패턴 로그, (3) 교사의 육안 대조 + 학칙 처벌 억제의 3중 조합이다.**

### A-2. 기기 바인딩(계정당 1기기) 관행

**등록 절차 — "최초 로그인 = 기기 등록"이 표준.**
- 명지대(U-Check): 포털에서 앱용 비밀번호 설정 → 앱 설치 → 학번+비밀번호 로그인 → "학생인증성공" 시 해당 단말이 그 계정의 기기로 고정 ([명지대 안내](https://www.mju.ac.kr/bbs/mjukr/143/3801/artclView.do)).
- 세종대: 동일 구조 + **"2개 이상의 단말기에 1개 학번을 인증하면 오류 발생, 로그아웃 처리"** 명시 ([세종대 2026-1 공지](https://www.sejong.ac.kr/kor/intro/notice3.do?mode=view&articleNo=863778)).

**기기 변경(재바인딩) 절차 — 마찰(friction)을 의도적으로 설계.**
- 명지대: 앱 내 "폰변경 신청" 셀프서비스. 단, **분실 시에만** 사용하도록 안내하고 "폰변경 신청이 잦은 경우 승인처리가 되지 않을 수 있음" ([명지대](https://www.mju.ac.kr/bbs/mjukr/143/3801/artclView.do)).
- 세종대: 단말기 변경 신청 → **승인까지 최소 5일 소요**(대리출석 방지 목적 명시). 그 사이 출석은 교수에게 직접 확인. "휴대폰↔태블릿을 번갈아 변경 신청하면 부정 사용으로 간주". 오류 시 학생회관 205호 **대면 방문 승인** ([세종대](https://www.sejong.ac.kr/kor/intro/notice3.do?mode=view&articleNo=863778)). → 즉 업계는 "자동 즉시 재바인딩"을 대리출석 백도어로 보고, 지연·횟수 제한·대면 확인 중 하나 이상을 끼워 넣는다.
- "다른 학생에게 내 스마트폰을 빌려주면 본인 인증에 장애 발생, 반드시 본인 스마트폰으로 출석" 경고문이 표준 문구 (세종대).

**기기 식별 방법(기술).** 벤더들이 식별자 구현을 공개하진 않으나, 플랫폼 정책상 선택지는 정리돼 있다:
- **Android**: Google Play는 2025-04-10 정책 변경으로 **Android ID(SSAID)를 더 이상 영구 기기 식별자로 취급하지 않음**(리셋 가능 식별자로 재분류, 개인정보 연결 제한) ([Play Console 정책 공지](https://support.google.com/googleplay/android-developer/answer/15899442?hl=en-GB), [IDAC 분석](https://digitalwatchdog.org/google-play-changes-to-android-device-identifiers-a-step-in-the-right-direction/)). 공식 가이드는 "하드웨어 식별자(SSAID·IMEI·MAC) 회피, 대부분의 비광고 용도는 **앱 자체 발급 GUID(설치 식별자)**로 충분, 사기 방지·분석에는 **App Set ID**" ([Android 식별자 모범사례](https://developer.android.com/identity/user-data-ids)). App Set ID는 같은 개발자 앱 전체 삭제 또는 13개월 미접근 시 리셋.
- **iOS**: `identifierForVendor`는 같은 벤더 앱을 모두 지우면 재생성. 재설치에도 살아남는 식별이 필요하면 **Keychain에 자체 UUID 저장**(앱 삭제 후에도 유지)이 관행 ([iOS 식별자 정리](https://medium.com/@maatheusgois/unique-identifiers-in-ios-identifierforvendor-advertisingidentifier-and-uuid-in-swift-53c9e4b9bc10), [Keychain 영속 식별자](https://medium.com/@miguelcma/persistent-cross-install-device-identifier-on-ios-using-keychain-ac9e4f84870f)).
- **FCM 토큰**: 앱 재설치·토큰 갱신 시 바뀌므로 "기기 바인딩 키"로는 부적합(푸시 라우팅 용도로만).
- 종합하면 합규 스택은 **"서버가 발급한 UUID를 클라이언트 보안 저장소(iOS Keychain / Android Keystore-backed 저장)에 보관" + 보조 신호(App Set ID, 기기 모델/OS 메타데이터)**다. IMEI·MAC·SSAID 하드웨어 식별자는 정책·API 양쪽에서 사실상 봉인됨.

**공유 기기(부모·형제) 문제.** 대학은 성인 1인 1폰 전제라 공식 언급이 거의 없다(세종대의 "복수 단말 인증 = 오류"가 유일한 간접 규정). K-12/학원 쪽은 반대로 **학생 폰 바인딩 자체를 포기**하고 카드·키오스크로 우회하는 게 주류(A-3) — 형제가 폰 1대를 공유하거나 부모 폰으로 대신 찍는 문제를 원천 회피하는 구조다. "한 단말에 복수 학생 계정" 감지는 공개된 상용 사례를 찾지 못했다(우리 설계에서 명시적으로 다룰 가치가 있는 공백).

### A-3. 개인 기기가 없는 학생 처리 — K-12는 BYOD가 원래 전제가 아니다

**대학조차 수동 폴백이 공식 절차.** 세종대: "스마트폰 미소지 학생 또는 오류가 발생한 학생은 담당교수님께 출결 정보 수정을 요청" ([세종대](https://www.sejong.ac.kr/kor/intro/notice3.do?mode=view&articleNo=863778)). 즉 1위 벤더(유체크) 도입교도 **교수 수동 정정이 1급 폴백**이다.

**K-12·학원의 주류는 학생 폰이 아니라 '태그 + 키오스크 + 보호자 알림'.**
- 초등: 교육부 주관 "안심알리미" — 가방에 붙이는 카드/블루투스 태그를 교문 수신기가 인식, 보호자 앱에 푸시. 아이알리미(제이티통신), T안심알리미(SKT·루키스) 등. 경기도교육청은 2026년에도 운영 계획 문서를 냄 ([아이알리미](https://jtts.co.kr/), [경기도교육청 2026 운영계획 PDF](https://www.goe.go.kr/resource/goe/na/bbs_1995/2026/01/26e5e77d-8eba-476c-a33d-5311d09c3a5b.pdf)).
- 학원: 출결버스·에듀클릭·어나더클래스·학원조아 등 — 학생별 번호(PIN) 입력 또는 QR/카드 태그를 **학원 태블릿·키오스크**에서 처리하고 보호자에게 알림톡 발송. 학생 개인 폰을 요구하지 않는 것이 표준 ([출결버스 FAQ](https://checkbuss.co.kr/default/contact/faq_page.php?rel=), [에듀클릭](https://edusmart.co.kr/rollbook)).
- 고교학점제 이동수업용 QR 출결도 "교사 화면의 회전 QR을 학생 폰으로 스캔" 또는 "학생 QR을 교사 단말이 스캔"의 양방향이 혼재 ([QR체크](https://qrcheck.net/), [에듀허브 가이드](https://www.eduhub.help/323QRTypeC.html)).

**보유율 — BYOD 커버리지의 실측치.** 초등 저학년 보유율 30%대 진입, 초등 고학년 81.2%, 중·고생 95%+ (KISDI 미디어패널) ([뉴스1](https://www.news1.kr/it-science/general-it/2839220), [KISDI 통계](https://stat.kisdi.re.kr/statHtml/statHtml.do?orgId=405&tblId=DT_405001_I008&conn_path=I2)). → 중·고교라도 학급당 1~2명은 무폰·공기계·피처폰을 전제해야 한다.

**휴대폰 수거 정책과 BYOD 출결의 정면 충돌 — 구조적, 그리고 법제화됨.**
- 실태: 서울 학생인권 실태조사(2020)에서 **중학생 75.9%, 고등학생 47.2%가 "등교 시 휴대전화 일괄수거"** 응답 ([경향신문](https://www.khan.co.kr/article/202210160805001)).
- 2024-10 국가인권위가 10년 만에 입장을 뒤집어 "등교 시 일괄 수거는 인권침해 아님" 결정 ([한국경제](https://www.hankyung.com/article/2024100702757), [인권위 보도](http://humanrights.go.kr/base/board/read?boardManagementNo=24&boardNo=7611162&menuLevel=3&menuNo=91)).
- 2025-08-27 초·중등교육법 개정안 국회 통과, **2026-03-01 시행: 수업 중 스마트기기(휴대전화+태블릿) 사용 원칙 금지**. 예외는 (1) 장애·특수교육 보조기기 (2) 교육 목적 (3) 긴급 상황 — 학교장·교원 허용 전제. 소지 제한의 구체 기준은 학칙 위임 ([정책브리핑](https://www.korea.kr/news/policyNewsView.do?newsId=148953078), [경향신문](https://www.khan.co.kr/article/202508271538001)).
- 함의: **2026년 현재 K-12에서 "학생이 수업 시작 시 폰을 손에 쥐고 있다"는 가정은 법·학칙상 성립하지 않는 학교가 다수.** 조회(아침) 시간 수거 전 짧은 창구, "교육 목적" 예외로 학칙에 출결 앱을 명시하는 경로, 또는 폰이 수거함에 있어도 되는 방식(키오스크/교사 확인)이 필요하다. 참고로 BLE 자동출석은 "폰이 수거함에 모여 있는" 상태에서 비컨 범위에 들면 전원 출석 처리되는 오탐 시나리오도 만든다(수거함 위치가 교실 안일 때).

---

## Part B. 출석핑 적용 설계 제안

전제 재확인: 교사 태블릿 비컨(회전 minor) + 회전 QR + 학생 폰 BYOD + 키오스크 PIN 폴백, 좌표 수집 금지, suspicious_flags 로그-온리(차단 없음), 출석 쓰기 Edge Function 전용 — 기존 M0 스키마(`attendance_logs`, `suspicious_flags`, `kiosk_devices`)와 정합되게 제안한다.

### B-1. 기기 바인딩 스키마

식별자 선택 (Play 정책 2025-04 이후 합규 스택):
- **1차 키: 서버 발급 `device_uuid`** — 최초 로그인 시 Edge Function이 발급, 클라이언트는 iOS Keychain / Android EncryptedSharedPreferences(Keystore-backed)에 저장. 앱 재설치 시 iOS는 Keychain으로 생존, Android는 소실 → "기기 변경" 플로우로 자연 유도(의도된 마찰).
- **보조 신호(evidence용, 키 아님)**: Android App Set ID(사기 방지 용도 허용), 플랫폼/모델/OS 버전. SSAID·IMEI·MAC·광고ID·FCM 토큰은 바인딩 키로 사용 금지(정책·안정성 양쪽 사유).

```sql
create table student_devices (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references profiles (id),
  device_uuid uuid not null unique,        -- 서버 발급, 클라 보안저장소 보관
  platform text not null check (platform in ('android','ios')),
  device_model text,                        -- 메타데이터 (PII 아님)
  app_set_id text,                          -- Android만, nullable, 사기방지 보조
  status text not null default 'active'
    check (status in ('active','pending','revoked')),
  registered_at timestamptz not null default now(),
  revoked_at timestamptz,
  revoked_by uuid references profiles (id), -- 교사/관리자 승인 흔적
  replaced_by uuid references student_devices (id)
);
-- 핵심 불변식: 학생당 active 1대
create unique index student_devices_one_active
  on student_devices (student_id) where status = 'active';
create index student_devices_student_idx on student_devices (student_id);
```

- `attendance_logs`에 `student_device_id uuid references student_devices(id)` nullable 컬럼 추가(QR/BLE 경로만 기록, PIN/MANUAL/LIST는 null). check-in Edge Function이 `device_uuid` 헤더를 검증해 채운다.
- RLS: 클라 INSERT/UPDATE deny, 등록·해제는 Edge Function(`register_device`) 전용. 교사는 자기 반 학생의 기기 목록 read + revoke 요청 가능.

**등록·변경 플로우 (업계 관행의 K-12 번안):**
1. 최초 로그인 → 자동 등록(`active`). 대학처럼 별도 절차 없음 — 마찰 없는 온보딩.
2. 기기 변경 → 새 기기 로그인 시 기존 active 기기 존재를 감지 → 새 기기는 `pending` + **교사(또는 담임) 승인으로 활성화**. 세종대의 "5일 대기"는 K-12에 과하므로 **교사 원탭 승인**으로 치환(교사가 눈앞의 학생을 확인하는 것이 최고의 본인 인증). 승인 대기 중 출석은 키오스크 PIN/교사 수동으로.
3. 자동 승인 예외 금지 규칙: 동일 학생의 재바인딩이 30일 내 2회 이상이면 승인 UI에 경고 배지 + `suspicious_flags(flag_type='RAPID_DEVICE_REBIND')`. (명지대 "잦은 신청 승인 거부"의 로그-온리 번안.)
4. 형제·부모 공유 기기: `device_uuid`가 다른 학생의 active/이력 기기와 겹치면 차단하지 말고 `SHARED_DEVICE` 플래그만. 실제로 형제가 폰을 물려받는 정상 케이스가 많다 — 차단하면 CS 폭탄.

### B-2. 감지 vs 차단 정책 (로그-온리 원칙 유지 — 업계 근거 충분)

업계 결론(A-1)이 우리 원칙을 지지한다: 기술 차단은 불가능하고, 오탐 차단은 K-12에서 학생 불이익(출결은 학생부 기재 사항)으로 직결되므로 **감지→교사 대시보드 배지→교사 판단**이 옳다. 추가할 flag_type:

| flag_type | 트리거 | evidence(최소) |
|---|---|---|
| `MULTI_ACCOUNT_SAME_DEVICE` | 같은 `device_uuid`(또는 App Set ID)로 한 세션에 2명 이상 체크인 | 세션 id, 학생 id 쌍, 시각 차 |
| `RAPID_DEVICE_REBIND` | 30일 내 재바인딩 2회+ | 횟수, 직전 등록일 |
| `SHARED_DEVICE` | device_uuid가 타 학생 이력과 중복 | 중복 상대 학생 id |
| `UNBOUND_DEVICE_CHECKIN` | pending/revoked 기기에서 체크인 시도 | 기기 status |
| `CHECKIN_HEADCOUNT_GAP` (v2) | BLE 체크인 수 > 교사가 확인한 인원 | 차이 수만 |

- **"한 사람이 폰 2대 지참"의 유일한 실효 대책은 교사 헤드카운트다** (특허 KR101658577B1과 동일 결론). 출석핑은 교사 태블릿이 이미 교실에 있으므로 구조적 우위: 세션 마감 화면에 "BLE/QR 자동 출석 N명 — 실제 인원과 맞나요?" **원탭 확인 스텝**을 넣고, 교사가 "아니오"를 누르면 명렬표 뷰로 전환. 이것이 대학의 "불시 점검"을 UX로 내재화한 것. RSSI 그룹핑(두 폰이 같은 궤적) 같은 신호 기반 감지는 좌표 금지 원칙·오탐률 때문에 비권장.
- 회전 QR·회전 minor는 이미 원격 공모(스크린샷 전송)를 차단하고 있음 — 경북대 3초 QR과 동급. 유지.

### B-3. 기기 없는 학생 UX (BYOD 붕괴 대비 — K-12에선 기본값에 가깝다)

근거: 초등 고학년 보유율 81%, 중학교 75.9%가 등교 시 수거, 2026-03부터 수업 중 사용 원칙 금지. **출석핑에서 키오스크 PIN은 '폴백'이 아니라 공동 1급 경로로 설계·홍보해야 한다** (학원 업계 표준이 이미 그 형태).

1. **키오스크 PIN 상시 노출**: 학급 단위로 "이 반은 키오스크 모드" 프리셋 제공(폰 수거 학교용). 학생별이 아니라 반별 정책 스위치 — 담임이 한 번 설정.
2. **교사 수동/명렬표 경로 유지**: 세종대조차 "미소지 학생은 교수에게 수정 요청"이 공식 절차. 우리는 이미 `MANUAL`/`LIST` method가 스키마에 있음 — UI에서 3탭 이내 접근 보장.
3. **수거함 오탐 방지**: BLE 자동 체크인은 "학생 앱이 포그라운드+본인 조작" 시점만 인정(백그라운드 자동 확정 금지). 수거함에 모인 폰이 비컨 범위에 들어도 출석 처리되지 않게.
4. **시간 창 설계**: 조회 세션의 BLE/QR 창을 등교~수거 시점 전으로 짧게 잡는 옵션(학교별 설정). 수업(교시) 세션은 키오스크/교사 확인 우선.
5. **무폰 학생 낙인 방지**: 키오스크 PIN 화면에 "폰 없이 출석하는 표준 방법"으로 문구 설계. PIN은 기존 `set_student_pin` Edge Function 재사용.
6. **법 대응 문서화**: 학교 도입 가이드에 "학칙의 '교육 목적' 예외 조항에 출결 앱 사용을 명시"하는 표준 문안 제공(초·중등교육법 개정 대응 — 출시 차단 게이트 법률 자문 항목에 추가 권장).

### B-4. 요약 — 업계 대비 출석핑 포지션

| 항목 | 업계 관행 (대학) | 출석핑 제안 |
|---|---|---|
| 기기 바인딩 | 최초 로그인 고정, 변경 시 5일 대기/대면 승인 | 최초 로그인 자동 등록, 변경은 교사 원탭 승인 |
| 식별자 | 비공개(하드웨어 ID 추정 구형 다수) | 서버 발급 UUID + Keychain/Keystore, App Set ID 보조 (2025 Play 정책 합규) |
| 폰 2대 지참 | 기술 차단 불가, 불시 점검 | 동일 — 세션 마감 헤드카운트 원탭 확인 + 로그-온리 플래그 |
| 복수 계정/기기 | 강제 로그아웃(차단형) | suspicious_flags 로그-온리 + 대시보드 배지 |
| 무폰 학생 | 교수 수동 정정 | 키오스크 PIN을 공동 1급 경로로, 반별 프리셋 |
| 수거 정책 충돌 | 해당 없음(대학) | BLE 포그라운드 한정 + 시간 창 + 키오스크 모드 |

---

## 출처 전체 목록

- 세종대 2026-1 전자출결 안내: https://www.sejong.ac.kr/kor/intro/notice3.do?mode=view&articleNo=863778
- 명지대 U-Check 사용자등록 안내: https://www.mju.ac.kr/bbs/mjukr/143/3801/artclView.do
- 경기대 전자출결 안내: https://www.kyonggi.ac.kr/www/contents.do?key=5127
- UCheck Plus (Play 스토어): https://play.google.com/store/apps/details?id=com.libeka.attendance.ucheckplusstud
- 씨드시스템: https://xidsys.co.kr/
- 호서대신문 (전자출결 악용 수법): https://news.hoseo.ac.kr/news/articleView.html?idxno=902
- 덕성여대신문 (대리출석·출튀): https://www.dspress.org/news/articleView.html?idxno=5311
- 부산외대 대리출석 공지 (처벌): https://www.bufs.ac.kr/bbs/board.php?bo_table=stat_board&wr_id=38
- 단대신문 (형법 제314조): http://dknews.dankook.ac.kr/news/articleView.html?idxno=9365
- 머니투데이 (학생증 대여 시장): https://www.mt.co.kr/society/2026/05/31/2026053017035326496
- 헤럴드경제 (중앙대 전자출결): https://mbiz.heraldcorp.com/article/1306649
- 경북대 LMS QR 3초 갱신: https://cse.knu.ac.kr/bbs/board.php?bo_table=sub5_1&wr_id=28827
- 특허 KR101658577B1 (헤드카운트 대조): https://patents.google.com/patent/KR101658577B1/ko
- Android 고유 식별자 모범사례: https://developer.android.com/identity/user-data-ids
- Google Play 정책 공지 2025-04-10 (Android ID 재분류): https://support.google.com/googleplay/android-developer/answer/15899442
- IDAC (Play 식별자 정책 분석): https://digitalwatchdog.org/google-play-changes-to-android-device-identifiers-a-step-in-the-right-direction/
- iOS identifierForVendor 정리: https://medium.com/@maatheusgois/unique-identifiers-in-ios-identifierforvendor-advertisingidentifier-and-uuid-in-swift-53c9e4b9bc10
- iOS Keychain 영속 식별자: https://medium.com/@miguelcma/persistent-cross-install-device-identifier-on-ios-using-keychain-ac9e4f84870f
- 정책브리핑 (2026-03 수업 중 스마트폰 금지): https://www.korea.kr/news/policyNewsView.do?newsId=148953078
- 경향신문 (개정안 통과 속보): https://www.khan.co.kr/article/202508271538001
- 한국경제 (인권위 판단 변경 2024-10): https://www.hankyung.com/article/2024100702757
- 인권위 보도자료: http://humanrights.go.kr/base/board/read?boardManagementNo=24&boardNo=7611162&menuLevel=3&menuNo=91
- 경향신문 (수거 실태 75.9%/47.2%): https://www.khan.co.kr/article/202210160805001
- 뉴스1 (초등 저학년 보유율 30%): https://www.news1.kr/it-science/general-it/2839220
- KISDI 스마트폰·키즈폰 보유 통계: https://stat.kisdi.re.kr/statHtml/statHtml.do?orgId=405&tblId=DT_405001_I008&conn_path=I2
- 아이알리미 (안심알리미): https://jtts.co.kr/
- 경기도교육청 2026 안심알리미 운영계획: https://www.goe.go.kr/resource/goe/na/bbs_1995/2026/01/26e5e77d-8eba-476c-a33d-5311d09c3a5b.pdf
- 출결버스 FAQ: https://checkbuss.co.kr/default/contact/faq_page.php?rel=
- 에듀클릭: https://edusmart.co.kr/rollbook
- 에듀허브: https://eduhub.co.kr/ · https://www.eduhub.help/323QRTypeC.html
- QR체크: https://qrcheck.net/
