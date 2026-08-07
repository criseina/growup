# Data Model

> GrowUp 프로젝트의 Action Card 데이터 구조 정의

---

# 목적

모든 Action Card는 동일한 데이터 구조를 사용한다.

이 문서는 Flutter 모델, JSON 파일, 데이터베이스의 기준이 된다.

---

# Action Card 구조

| 필드 | 설명 |
|------|------|
| cardId | 카드 ID |
| category | 카테고리 |
| titleKo | 한글 제목 |
| titleEn | 영문 제목 |
| difficulty | 난이도 |
| image | 이미지 파일명 |
| childTitle | 아이에게 보여줄 제목 |
| parentGuide | 부모 가이드 |
| status | 혼자 / 같이 / 안 해봤어요 |
| prerequisite | 선행 행동 |
| nextActions | 추천 행동 |
| tags | 검색 태그 |
| version | 데이터 버전 |

---

# 상태 정의

## 🟢 혼자

아이가 스스로 수행할 수 있다.

## 🟡 같이

아이가 부모의 도움이나 안내와 함께 수행할 수 있다.

## ⚪ 안 해봤어요

아직 경험하지 못했거나 시도하지 않았다.

---

# 데이터 원칙

- 하나의 카드에는 하나의 행동만 포함한다.
- 제목은 아이가 읽기 쉬운 짧은 문장으로 작성한다.
- 모든 카드는 JSON으로 변환 가능해야 한다.
- 모든 필드는 일관된 형식을 유지한다.
