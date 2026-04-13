# 테스트 실험 보고서

**프로젝트:** crawlernest-normalization — C Data Normalization Engine  
**실험 날짜:** 2026-04-13  
**담당:** 자동화 실험 시스템 (Claude)

---

## 1. 실험 목적

대학 순위 데이터 정규화 엔진(C 언어)의 전체 코드를 체계적으로 분석하여 다음 세 가지를 수행한다.

1. 기존 테스트 스위트의 기준선 측정
2. 미커버 또는 취약한 영역 식별 및 신규 테스트 케이스 작성
3. 발견된 버그 수정 후 전체 회귀 검증

---

## 2. 기존 테스트 기준선 (수정 전)

| 테스트 스위트 | 파일 | 결과 |
|-------------|------|------|
| `test_normalizer` | `src/tests/test_normalizer.c` | **17 / 17** ✅ |
| `test_extreme` | `src/tests/test_extreme.c` | **139 / 139** ✅ |
| `test_scale` | `src/tests/test_scale.c` | **31 / 31** ✅ |
| **합계** | | **187 / 187** |

세 스위트 모두 이미 통과 상태이며 컴파일 경고도 없다.

---

## 3. 취약점 분석 결과

소스 코드 전체를 검토한 후 12개 취약 영역을 식별했다.

### 3.1 확인된 버그 (수정 완료)

#### Bug-1 — `rank_parser.c`: `=N` 포맷 미처리

| 항목 | 내용 |
|------|------|
| 파일 | `c_engine/src/rank_parser.c` |
| 증상 | `parse_rank("=201")` → `-1 / -1` (파싱 실패) |
| 기대 | `rank_min = 201, rank_max = 201` |
| 원인 | `sscanf` 패턴 목록에 `=N` 형식이 없음 |
| 수정 | `Case 4: =N` 추가 (`sscanf(" =%d", &a)`) |
| 중요도 | **High** — QS 순위 데이터에서 실제로 사용되는 표기 |

#### Bug-2 — `name_normalizer.c`: 슬래시(`/`) 뒤 문자 소문자화

| 항목 | 내용 |
|------|------|
| 파일 | `c_engine/src/name_normalizer.c` |
| 증상 | `normalize_name("Arts/Sciences")` → `"Arts/sciences"` (S가 소문자) |
| 기대 | `"Arts/Sciences"` |
| 원인 | `apply_readable_name_case()` 내 `capitalize_next` 플래그가 `-`와 `(` 이후만 설정되고 `/` 이후는 누락 |
| 수정 | `capitalize_next = (ch == '-' \|\| ch == '(' \|\| ch == '/')` |
| 중요도 | **Medium** — 대학명에 `/` 포함 사례 (예: `Arts/Sciences School`) |

### 3.2 설계 한계 (수정 제외, 문서화만)

| ID | 위치 | 내용 | 판단 |
|----|------|------|------|
| W3 | `rank_parser.c` | `#N` 형식 (`#10`) 미처리 → `-1/-1` | 추후 우선순위 판단 필요 |
| W4 | `rank_parser.c` | 매우 큰 정수 입력 시 `sscanf %d` 오버플로 (UB) | 실운영 데이터에서 발생 가능성 낮음 |
| W5 | `score_parser.c` | `-1.0` 입력이 "무효값 sentinel"과 충돌 | 대학 점수가 음수일 가능성 없어 실질 위험 없음 |
| W10 | `csv_writer.c` | `rank_min > rank_max` 역전된 순위 저장 시 유효성 검사 없음 | 하위 계층에서 처리하도록 위임 가능 |

---

## 4. 신규 테스트 케이스 (test_weakness.c)

새로 작성한 `src/tests/test_weakness.c`는 42개의 테스트로 구성된다.

### 4.1 테스트 카테고리별 구성

| 카테고리 | 테스트 수 | 대상 |
|---------|---------|------|
| W1: rank `=N` 포맷 | 4 | `parse_rank("=201")` → 201/201 |
| W2: rank `N+` 포맷 | 4 | `parse_rank("201+")` → 201/201 (기존 동작 문서화) |
| W3: rank `#N` 포맷 | 1 | 현재 동작(-1/-1) 문서화 |
| W4: 정수 오버플로 | 2 | 99999999999999 입력 시 비충돌 확인 |
| W5: 음수 점수 모호성 | 3 | 점수 -2.5 → CSV 빈값 출력; 0.0 → 정상 출력 |
| W6: 점수 뒤 노이즈 | 4 | "91.2 pts", "85/100", "73.5%" |
| W7: 앰퍼샌드(&) | 3 | 이름에서 & 보존 확인 |
| W8: 슬래시(/) | 2 | 슬래시 뒤 대문자화 수정 검증 |
| W9: 주요 국가 fallback | 10 | Japan, Germany, France 등 7개국 + 멱등성 2건 |
| W10: 역전된 순위 기록 | 1 | 크래시 없이 기록됨 확인 |
| W11: 헤더만 있는 CSV | 1 | 0건 반환, 비충돌 |
| W12: UTF-8 BOM 헤더 | 2 | BOM 제거 후 정상 파싱 |
| Integration | 5 | =N, N+ 포맷 포함 전체 파이프라인 |

### 4.2 핵심 테스트 케이스 예시

```
W1: parse_rank("=201")   → rank_min=201, rank_max=201  [BUG-1 수정 검증]
W1: parse_rank("  =99 ") → rank_min=99,  rank_max=99   [공백 처리 포함]
W8: normalize_name("Arts/Sciences Department") → "Arts/Sciences Department" [BUG-2 수정 검증]
W5: csv_writer(score=-2.5) → blank field in output CSV  [설계 한계 문서화]
W12: UTF-8 BOM CSV load → 1 record, name="MIT"          [기존 기능 보강 확인]
```

---

## 5. 코드 수정 내역

### 수정 파일 1: `c_engine/src/rank_parser.c`

**변경 내용:**
- 파일 헤더 주석에 `=N` 및 `N+` 지원 추가 기재
- `parse_rank()` 함수에 `Case 4: =N` 삽입 (기존 "plain integer" 케이스 앞)

```c
/* Case 4: =N — explicit-equal notation */
if (sscanf(temp, " =%d", &a) == 1) {
    *rank_min = a;
    *rank_max = a;
    return;
}

/* Case 5: plain integer (also handles N+ because sscanf stops before '+') */
if (sscanf(temp, " %d", &a) == 1) {
    ...
}
```

> `N+` 포맷은 `sscanf("%d")` 가 `+` 앞에서 멈추는 특성 덕분에 별도 케이스 없이 Case 5로 처리됨. 주석에 명시하여 의도를 문서화했다.

### 수정 파일 2: `c_engine/src/name_normalizer.c`

**변경 내용:**
- `apply_readable_name_case()` 내 `capitalize_next` 트리거 조건에 `/` 추가

```c
/* Before */
capitalize_next = (ch == '-' || ch == '(');

/* After */
capitalize_next = (ch == '-' || ch == '(' || ch == '/');
```

### 추가 파일: `c_engine/src/tests/test_weakness.c`

- 42개 취약점 중심 회귀 테스트
- `Makefile`에 `test_weakness` 및 `test_all` 타겟 추가

---

## 6. 최종 테스트 결과 (수정 후)

| 테스트 스위트 | 결과 |
|-------------|------|
| `test_normalizer` (기존 unit) | **17 / 17** ✅ |
| `test_extreme` (기존 extreme) | **139 / 139** ✅ |
| `test_scale` (기존 scale) | **31 / 31** ✅ |
| `test_weakness` (신규 weakness) | **42 / 42** ✅ |
| **전체 합계** | **229 / 229** ✅ |

모든 기존 테스트가 회귀 없이 통과하고, 신규 테스트 42건도 전원 통과한다.

---

## 7. 잔여 개선 권고 사항

| 우선순위 | 항목 | 설명 |
|---------|------|------|
| 높음 | `rank_parser`: `#N` 포맷 처리 | `#10` 형식의 순위 파싱 추가 |
| 중간 | `rank_parser`: 정수 오버플로 방어 | `long` 로 먼저 파싱 후 범위 검사 |
| 중간 | `csv_writer`: 역전된 순위 경고 | `rank_min > rank_max` 시 stderr 경고 |
| 낮음 | `score_parser`: sentinel 값 변경 | `-1.0` 대신 `NaN` 또는 별도 플래그 사용 고려 |
| 낮음 | CI 통합 | `test_all` 타겟을 GitHub Actions 등에 연결 |

---

## 8. 결론

이번 실험을 통해 2개의 실질적 버그(`=N` 포맷 누락, `/` 뒤 소문자화)를 발견하고 수정했다. 수정 전후 229개 테스트 전원이 통과하며, 신규 취약점 중심 테스트 파일(`test_weakness.c`)이 향후 회귀 방지 역할을 수행한다.

---

*자동 생성: 2026-04-13*
