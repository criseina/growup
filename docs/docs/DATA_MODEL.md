# Data Model

> GrowUp 프로젝트의 Action Card 데이터 구조 정의

---

# 목적

모든 Action Card는 동일한 데이터 구조를 사용한다.

이 문서는 Flutter 모델, JSON 파일, 데이터베이스의 기준이 된다.

---

# Action Card

| 항목 | 설명 |
|------|------|
| cardId | 카드 ID |
| category | 영역 코드 |
| titleKo | 한글 제목 |
| titleEn | 영문 제목 |
| difficulty | 난이도 |
| image | 그림 파일 |
| childText | 아이 카드 제목 |
| parentGoal | 행동 목표 |
| aloneCriteria | 🟢 혼자 기준 |
| togetherCriteria | 🟡 같이 기준 |
| notYetCriteria | ⚪ 안 해봤어요 기준 |
| parentTip | 부모 팁 |
| prerequisite | 선행 행동 |
| nextActions | 다음 추천 행동 |
| jsonId | JSON ID |
| status | Draft / Review / Complete |

---

# 상태 값

## 🟢 혼자

아이가 도움 없이 수행할 수 있다.

---

## 🟡 같이

아이가 말이나 작은 도움을 받으면 수행할 수 있다.

---

## ⚪ 안 해봤어요

아직 경험하지 못했거나 스스로 시도하지 않았다.

---

# 데이터 원칙

- 하나의 카드에는 하나의 행동만 포함한다.
- 제목은 짧고 명확하게 작성한다.
- 아이는 그림 중심으로 이해한다.
- 부모는 관찰 가능한 행동으로 판단한다.
- 모든 카드는 JSON으로 변환 가능해야 한다.
