# 전자출결 "출석 수집 시간창(time window)" 업계 관행 조사

조사일: 2026-07-06 · 대상: 출석핑(K-12, 교사 수동 세션 시작/종료) — "수업 시작부터 10분만 수집하고 자동 종료" 요구 검토

---

## 1. 국내 대학 전자출결의 시간 규칙 실례

### 1.1 대학별 출석/지각/결석 자동 구분 기준 (수업 시작 시각 기준)

| 대학/시스템 | 출석 인정 | 지각 | 결석 | 근거 |
|---|---|---|---|---|
| **공주대** (전자출결) | 수업 시작 5분 전 ~ 시작 후 10분 | 10~30분 (자동) | 이후 | 공주대 출결시스템 학생 안내 매뉴얼 (기확보 사실과 일치) — https://www.kongju.ac.kr/bbs/kongju/1521/258989/artclView.do , https://www.kongju.ac.kr/bbs/kongju/1521/489684/download.do |
| **한양대** | 시작 전 10:00 ~ 시작 후 10:00 | 시작 후 10:01 ~ 30:00 | 시작 후 30:01 이후 | 전자출결시스템 학생용 매뉴얼 — https://site.hanyang.ac.kr/documents/10965283/13100339/elec_attendance_(student).pdf , https://www.hanyang.ac.kr/web/www/-118 |
| **아주대** | 시작 전 15분 ~ 시작 후 9:59 | 시작 후 10:00 ~ 19:59 | 이후 | 전자출결 안내 — https://www.ajou.ac.kr/kr/bachelor/class-attendance.do |
| **숭실대** | 시작 후 9분 이내 | 시작 후 10분 이후 | 학칙 기준 | 학사 공지 — https://sw.ssu.ac.kr/bbs/board.php?bo_table=notice&wr_id=612&page=26 |
| **동국대 (헤이영캠퍼스)** | **기본값: 시작 10분 전 ~ 시작 10분 후** | 이후 10분간 지각 | 이후 | 교원용 매뉴얼: "출석 처리 기본값은 수업시작 10분 전~10분 후, 이후 10분 지각. **수업별 개별설정 가능**" — https://wise.dongguk.ac.kr/resources/files/1_WISE_heyoung_guide_VER_20250827.pdf |

### 1.2 교수 재량 설정 범위

- **유체크(U-Check Plus, 리베카)**: 2012년 국내 최초 비콘 기반 출결. 교수용 앱/웹에서 지각·결석 시간 기준을 재량 설정 가능(예: 5분까지 출석, 15분까지 지각, 이후 결석). 개별 학생 상태(출석/결석/지각/조퇴) 수동 수정 지원. — https://www.mju.ac.kr/bbs/mjukr/143/204184/artclView.do , https://www.hibrain.net/braincafe/cafes/38/posts/211/articles/504100
- **헤이영캠퍼스(동국대)**: 교원이 출결 방식(비콘/휴대폰/인증키)과 **수업 시작 전/후 출석처리 가능 시간을 수업별로 설정**. 자동 출석체크 시간은 학생 수에 따라 30~60초 단계 설정. — https://wise.dongguk.ac.kr/resources/files/1_WISE_heyoung_guide_VER_20250827.pdf
- **경기대/한국외대/한성대** 등도 동일 계열 안내 페이지 존재 — https://www.kyonggi.ac.kr/www/contents.do?key=5127 , https://at.hufs.ac.kr/guide.html , https://hansung.ac.kr/eduinfo/8987/subview.do
- 공통 관행: **지각·조퇴 3회 = 결석 1회** 환산(대학 학칙 수준, K-12 나이스에는 없음).

**업계 표준 요약**: ①기본값은 "시작 전 5~15분 ~ 시작 후 10분 = 출석", ②"+10분 ~ +20/30분 = 지각 자동", ③담당 교원이 과목별로 창 길이를 조정 가능. "10분" 기본값은 사실상 국내 대학 전자출결의 데팍토 표준.

### 1.3 '히어로출결' 관련

"히어로출결"이라는 독립 제품은 공개 검색에서 확인되지 않음(동명 서비스 미발견). 검색상 대응물은 신한 **헤이영캠퍼스**(대학 통합앱 내 전자출결)로 추정되며 위 1.1/1.2에 반영. 별도 제품이 맞다면 추가 확인 필요.

---

## 2. 학원/K-12 앱의 등하원·출결 시간 규칙

- **클래스팅**: 원격수업 출결용으로 "학생이 **0시~24시 사이 클래스 접속·활동 시 자동 출석 처리**" — 즉 수집 창은 하루 전체로 열어두고 상태만 기록하는 모델. 교사는 출석부 메뉴에서 실시간 확인. 교육부 인정 원격수업 출결 서비스. — https://support.classting.com/hc/ko/articles/900000810683 , https://zdnet.co.kr/view/?no=20200403113749
- **하이클래스(아이스크림미디어)**: 알림장 중심. 결석/지각/조퇴/외출 현황 확인·관리 + 학부모 알림. 자동 판정 시간창 기능은 확인 안 됨(교사 수기 입력 + 통보 모델). — https://www.hiclass.net/ , https://shcomp.kr/entry/하이클래스-앱-사용-꿀팁-알림장-출결알리미
- **학원 등하원 계열(에듀클릭·출결선생·학원친구·모두출첵·아이엠클래스)**: QR/번호/단말기 태그 시각을 그대로 기록하고 **학부모에게 등원/하원 문자·알림톡 자동 발송**. 학생별 발송 조건 변경 가능. 시간표(반별 수업시간)에 원생을 배정해 두면 등원 시각과 대조하는 구조. — https://edusmart.co.kr/rollbook , https://hissam.kr/ , https://www.modoocheck.com/ , https://class.iamservice.net/ , https://apps.apple.com/kr/app/학원친구/id1123529010
- **패턴 정리**: 학원/K-12 앱은 대학처럼 "창 밖 체크인 거부"를 하지 않음. **수집은 상시(또는 하루 종일) 열어두고, 태그 시각 vs 시간표를 대조해 상태(등원/지각)를 구분하거나 교사가 수기 확정**하는 모델이 지배적. "자동 종료"보다 "자동 통보"가 핵심 가치.

---

## 3. 자동 종료(수집 창 마감)의 구현 패턴 비교

| 패턴 | 방식 | 장점 | 단점 |
|---|---|---|---|
| **A. 서버 스케줄러(cron)** | pg_cron 등이 주기적으로 `close_at < now()`인 ACTIVE 세션을 ENDED로 갱신 | 클라이언트 상태 무관하게 확정적 종료. 교사 앱이 죽어도 세션이 영원히 열려 있지 않음 | 분 단위 지연(폴링 주기), 인프라 요소 추가 |
| **B. 클라이언트 타이머** | 교사 앱이 10분 타이머 후 종료 API 호출 | 구현 최소, 서버 변경 없음 | 앱 백그라운드 전환/종료/네트워크 단절 시 미종료. **보안 경계가 아님**(위조 가능). 단독 사용 부적합 |
| **C. 판정형(수집 계속 + 시각으로 상태 구분)** | 세션은 열어두고 `check_in_time`과 `started_at + N분`을 비교해 present/late 자동 구분 | 스케줄러 불필요, 늦은 학생도 기록됨(지각으로), 데이터 손실 없음 | 세션이 "닫혔다"는 개념이 없어 UI가 모호. 창 밖 체크인을 막고 싶다는 요구는 미충족 |
| **D. 선언적 마감 + 서버 강제 (권장)** | 세션 생성 시 `close_at`을 **미리 기록**하고, 체크인 Edge Function이 매 요청마다 `now() vs close_at / late_after`를 평가해 거부·지각 판정. cron은 상태 표시 정리용 보조 | **강제 지점이 체크인 경로 자체**라 cron 지연·클라 타이머 실패와 무관하게 정확. 스케줄러는 있어도 되고 없어도 판정은 옳음 | 기존 세션 조회 로직에 시간 조건 추가 필요 |

- 업계 사례: RFID 학교 출결 시스템도 "7:00–8:00 출석, 8:01–8:30 지각, 8:31 자동 마감"의 **선언적 창 + 시각 판정** 모델 — https://arxiv.org/pdf/2507.14191
- Supabase에서 A/D 조합 구현: pg_cron + pg_net으로 주기 SQL 실행 또는 Edge Function 호출 — https://supabase.com/docs/guides/functions/schedule-functions , https://supabase.com/docs/guides/cron
- 핵심 원칙: **"닫힘"의 진실은 타이머 이벤트가 아니라 시각 비교여야 한다.** 이벤트(cron/타이머)는 UI 정리·알림용이고, 거부/지각 판정은 체크인 트랜잭션 안에서 `now()`로 결정해야 경쟁 조건·지연·위조에 안전.

---

## 4. 2026 교육부/나이스 지침의 지각·조퇴 판정 시각

- 근거 규정: **「학교생활기록 작성 및 관리지침」(교육부훈령 제555호, 2026. 3. 1. 시행)** — https://star.moe.go.kr/web/contents/m20103.do?schM=view&id=108056 , https://www.law.go.kr/행정규칙/학교생활기록작성및관리지침
- 정의: **지각 = "학교장이 정한 등교시각까지 출석하지 않은 경우", 조퇴 = "등교시각과 하교시각 사이에 하교한 경우"**. 지각·조퇴에 서로 다른 기준 시각을 적용할 수 없음(동일 기준 시각). — https://star.moe.go.kr/web/contents/m30102.do?schM=view&id=89744
- **결론: "수업 시작 후 N분"이라는 전국 공통 수치 기준은 지침에 없다.** 기준 시각(등교/교시 시작)과 세부 처리(N분)는 **학교장이 학교 규정으로 정함**. 지각·조퇴·결과는 결석에 준해 처리하되 절차는 학교 규정 위임. 출결상황은 질병/미인정/기타 구분의 연간 횟수로 기재. — https://star.moe.go.kr/web/contents/m30103.do?schM=view&id=100215
- 시사점: 출석핑이 "10분"을 하드코딩하면 안 되고, **학교/교사 설정값**이어야 함. 나이스 내보내기 관점에서는 지각 "횟수"만 필요하므로, 판정 시각 자체는 내부 정책 파라미터.

---

## 5. 출석핑 적용 설계 제안

### 5.1 sessions 테이블 확장 (마이그레이션 안)

현행: `sessions(status ACTIVE/ENDED, started_at, ended_at)` + `attendance_logs.check_in_time` (`supabase/migrations/20260705000001_init_m0_schema.sql`).

```sql
alter table sessions
  add column close_at timestamptz,                       -- 수집 창 마감 시각(선언적). null = 수동 종료 전까지 무기한(현행 동작 보존)
  add column auto_late_after_minutes smallint,           -- 시작 후 N분 이후 체크인 = late 자동 판정. null = 자동 지각 없음
  add constraint sessions_close_after_start check (close_at is null or close_at > started_at),
  add constraint sessions_late_within_close check (
    auto_late_after_minutes is null or auto_late_after_minutes >= 0
  );
```

- `close_at`(절대 시각) 채택 이유: `duration_minutes`보다 판정 SQL이 단순하고(`now() > close_at`), 교사가 "5분 연장"을 하면 `close_at`만 갱신하면 됨. 세션 생성 시 Edge Function이 `started_at + interval '10 min'`으로 계산해 넣는다.
- 대학 관행(수업 전 5~15분 조기 수집)은 K-12 교사 수동 시작 모델에선 불필요 — 세션 시작 = 수집 시작.
- 인덱스: `create index sessions_active_close_idx on sessions (close_at) where status = 'ACTIVE';` (cron 스윕용).

### 5.2 서버 강제 (권장: 패턴 D — Edge Function 판정 + cron 보조)

황금 규칙("출석 쓰기 = Edge Function 경유")과 정합. `supabase/functions/_shared/checkin.ts`의 ACTIVE 세션 조회에 시간 판정 추가:

1. **체크인 시점 판정 (진실의 원천)**
   - `now() > close_at` → `410 SESSION_CLOSED` 거부(또는 정책상 지각 허용 창이 따로 있으면 late 기록).
   - `close_at >= now() > started_at + auto_late_after_minutes` → status `late`로 기록(현행 enum에 `late` 이미 존재).
   - 그 외 → `present`.
   - 판정은 반드시 서버 `now()` 기준(클라 시계 불신).
2. **cron 스윕 (표시 정리용, 보조)** — pg_cron 1분 주기:
   ```sql
   select cron.schedule('close-expired-sessions', '* * * * *', $$
     update sessions set status = 'ENDED', ended_at = close_at
     where status = 'ACTIVE' and close_at < now()
   $$);
   ```
   이 스윕이 1~2분 늦어도 1번의 시각 판정 덕에 창 밖 체크인은 이미 차단됨. 스윕은 학생/교사 화면의 "진행 중" 표시와 Realtime 갱신을 정리하는 역할.
3. **클라이언트 타이머는 UX 전용**: 교사 화면 카운트다운·"곧 종료" 알림만. 종료 권위는 서버.
4. **RLS/무결성**: `close_at`·`auto_late_after_minutes`는 세션 생성/수정 Edge Function만 쓰기(교사 본인 세션 한정). 학생 클라이언트는 읽기 전용.

**UI 안내만으로 처리(비권장)**: 창을 UI에서만 닫으면 조작된 클라이언트가 창 밖 체크인 가능 → 출결 신뢰성 훼손. 서버 강제 필수.

### 5.3 교사 설정 UX

- **세션 시작 시트**: "출석 수집 시간" 칩 선택 — `5분 / 10분(기본) / 15분 / 수동 종료`. 기본값 10분은 대학 데팍토 표준(§1)과 일치. `수동 종료` 선택 시 `close_at = null`(현행 동작).
- **지각 자동 구분 토글(선택 기능)**: "N분 이후 체크인은 지각으로 표시" — 기본 off. K-12 지각 판정 기준은 학교장 재량(§4)이므로 강제 기본값을 두지 않고, 켜면 기본 10분. 지각은 어차피 교사가 최종 확정 가능(attendance_logs 갱신 경로 유지).
- **진행 중 화면**: 남은 시간 카운트다운 + "+5분 연장" 버튼(= `close_at` 갱신 Edge Function) + 즉시 종료 버튼(현행).
- **종료 후**: 미체크인 학생은 현행대로 교사 확정(자동 absent 확정은 하지 않음 — 나이스 기재는 교사 책임이므로 "미확인" 상태로 남겨 교사 검토 유도).
- **학급 기본값**: classes 수준 `default_collect_minutes` 저장은 v2로 미룸(세션 시트에서 마지막 선택 기억 정도로 시작).
- 반복 일정(요일별 시간표) 연동 자동 시작은 학원 앱들의 시간표 모델(§2)처럼 수요가 있으나, "교사 수동 시작" 철학과 충돌하므로 별도 기획으로 분리 권장.

### 5.4 마이그레이션 리스크

- 기존 ACTIVE 세션은 `close_at = null`이라 동작 불변(하위 호환).
- 통합 테스트 추가 지점: `integration_m1_test.ts` 계열에 ①창 내 present ②late 구간 ③close_at 이후 410 ④연장 후 재허용 4케이스.

---

## 출처 전체 목록

1. 공주대 전자출결 매뉴얼: https://www.kongju.ac.kr/bbs/kongju/1521/258989/artclView.do · https://www.kongju.ac.kr/bbs/kongju/1521/489684/download.do
2. 한양대 전자출결 학생용 매뉴얼: https://site.hanyang.ac.kr/documents/10965283/13100339/elec_attendance_(student).pdf · https://www.hanyang.ac.kr/web/www/-118
3. 아주대 전자출결 안내: https://www.ajou.ac.kr/kr/bachelor/class-attendance.do
4. 숭실대 출석·지각·결석 인정 기준: https://sw.ssu.ac.kr/bbs/board.php?bo_table=notice&wr_id=612&page=26
5. 동국대 헤이영캠퍼스 교원용 매뉴얼: https://wise.dongguk.ac.kr/resources/files/1_WISE_heyoung_guide_VER_20250827.pdf
6. 명지대 U-Check 사용법: https://www.mju.ac.kr/bbs/mjukr/143/204184/artclView.do · 교수 재량 지각 세팅 사례: https://www.hibrain.net/braincafe/cafes/38/posts/211/articles/504100
7. 경기대/한국외대/한성대 전자출결 안내: https://www.kyonggi.ac.kr/www/contents.do?key=5127 · https://at.hufs.ac.kr/guide.html · https://hansung.ac.kr/eduinfo/8987/subview.do
8. 클래스팅 출석부(출결 관리): https://support.classting.com/hc/ko/articles/900000810683 · https://zdnet.co.kr/view/?no=20200403113749
9. 하이클래스: https://www.hiclass.net/ · https://shcomp.kr/entry/하이클래스-앱-사용-꿀팁-알림장-출결알리미
10. 학원 출결 서비스: 에듀클릭 https://edusmart.co.kr/rollbook · 출결선생 https://hissam.kr/ · 모두출첵 https://www.modoocheck.com/ · 아이엠클래스 https://class.iamservice.net/ · 학원친구 https://apps.apple.com/kr/app/학원친구/id1123529010
11. EDURFID (RFID 학교 출결, 시간창 모델): https://arxiv.org/pdf/2507.14191
12. Supabase 스케줄링: https://supabase.com/docs/guides/functions/schedule-functions · https://supabase.com/docs/guides/cron
13. 학교생활기록 작성 및 관리지침(2026 시행, 교육부훈령 555호): https://star.moe.go.kr/web/contents/m20103.do?schM=view&id=108056 · https://www.law.go.kr/행정규칙/학교생활기록작성및관리지침 · 지각/조퇴 기준 Q&A: https://star.moe.go.kr/web/contents/m30102.do?schM=view&id=89744 · https://star.moe.go.kr/web/contents/m30103.do?schM=view&id=100215
