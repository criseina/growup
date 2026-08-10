class CardDetailContent {
  const CardDetailContent({
    required this.parentTip,
    required this.materials,
    required this.safetyNote,
  });

  final String parentTip;
  final String materials;
  final String safetyNote;
}

const defaultCardDetailContent = CardDetailContent(
  parentTip: '완벽하게 해내는 것보다 아이가 스스로 시도한 과정을 충분히 기다려 주세요.',
  materials: '활동에 필요한 물건',
  safetyNote: '아이의 발달 수준과 주변 환경을 살펴 안전하게 함께해 주세요.',
);

const cardDetailContentById = <String, CardDetailContent>{
  'H-01': CardDetailContent(
    parentTip: '순서를 끝까지 기억하지 못해도 괜찮아요. 다음 단계는 짧은 말이나 그림으로만 알려 주세요.',
    materials: '비누, 수건, 발판',
    safetyNote: '바닥이 미끄러울 수 있으니 발밑을 확인해 주세요.',
  ),
  'H-02': CardDetailContent(
    parentTip: '모든 이를 오래 닦는 것보다, 아이가 칫솔을 입에 넣고 닦아 보는 경험을 먼저 칭찬해 주세요.',
    materials: '어린이 칫솔, 치약, 컵',
    safetyNote: '치약은 삼키지 않도록 적은 양만 사용하고 보호자가 곁에 있어 주세요.',
  ),
  'H-03': CardDetailContent(
    parentTip: '얼굴에 물이 닿는 감각이 낯설 수 있어요. 수건이나 물 적신 손부터 천천히 시작해 주세요.',
    materials: '수건, 미지근한 물, 세안용품',
    safetyNote: '눈에 물이나 세안제가 들어가지 않게 도와 주세요.',
  ),
  'H-04': CardDetailContent(
    parentTip: '씻어야 할 부위를 모두 기억하게 하기보다 한 부위씩 함께 이름 붙여 주세요.',
    materials: '수건, 순한 비누, 목욕 스펀지',
    safetyNote: '물 온도와 미끄러운 바닥을 먼저 확인해 주세요.',
  ),
  'C-01': CardDetailContent(
    parentTip: '옷의 앞뒤를 틀려도 스스로 팔과 머리를 넣어 본 시도를 인정해 주세요.',
    materials: '여유 있는 상의 한 벌',
    safetyNote: '목 부분이 너무 좁거나 끈이 긴 옷은 피해주세요.',
  ),
  'C-02': CardDetailContent(
    parentTip: '앉아서 시작하면 균형 잡기가 쉬워요. 필요한 만큼만 말로 도와 주세요.',
    materials: '허리 밴딩 하의 한 벌',
    safetyNote: '서서 입을 때 넘어지지 않도록 안정된 장소에서 해주세요.',
  ),
  'C-03': CardDetailContent(
    parentTip: '양말의 방향을 맞추는 것보다 발가락을 넣고 끌어올리는 과정을 살펴 주세요.',
    materials: '신축성 있는 양말',
    safetyNote: '미끄러운 바닥에서는 앉아서 신도록 해주세요.',
  ),
  'C-04': CardDetailContent(
    parentTip: '신발끈보다 벨크로나 넓은 입구의 신발로 성공 경험을 먼저 만들어 주세요.',
    materials: '아이에게 맞는 신발',
    safetyNote: '신발을 신은 뒤 끈이나 벨크로가 걸리지 않는지 확인해 주세요.',
  ),
  'C-05': CardDetailContent(
    parentTip: '지퍼 고리나 큰 단추처럼 잡기 쉬운 것부터 시작하고 충분히 시간을 주세요.',
    materials: '큰 지퍼 또는 단추가 있는 옷',
    safetyNote: '피부나 머리카락이 지퍼에 끼지 않도록 가까이에서 지켜봐 주세요.',
  ),
  'M-01': CardDetailContent(
    parentTip: '흘려도 괜찮다는 분위기가 중요해요. 컵을 두 손으로 잡는 것부터 살펴 주세요.',
    materials: '가벼운 컵, 물, 닦을 수건',
    safetyNote: '뜨거운 음료나 깨지기 쉬운 컵은 사용하지 마세요.',
  ),
  'M-02': CardDetailContent(
    parentTip: '숟가락과 포크를 모두 잘 쥐지 않아도 됩니다. 아이에게 편한 도구 하나부터 사용해 보세요.',
    materials: '어린이 숟가락, 포크, 작은 음식',
    safetyNote: '날카롭거나 무거운 식기는 피하고 앉은 자세를 확인해 주세요.',
  ),
  'M-03': CardDetailContent(
    parentTip: '먹는 양이나 속도보다 식사 자리에 머물며 스스로 먹어 보는 과정을 기록해 주세요.',
    materials: '아이 식기, 닦을 수건',
    safetyNote: '질식 위험이 있는 음식은 아이에게 맞는 크기로 준비해 주세요.',
  ),
  'M-04': CardDetailContent(
    parentTip: '한 번에 모든 것을 치우기보다 컵이나 수저처럼 가벼운 물건 하나부터 맡겨 주세요.',
    materials: '가벼운 식기, 닦을 수건',
    safetyNote: '뜨겁거나 깨질 수 있는 그릇은 보호자가 정리해 주세요.',
  ),
  'B-01': CardDetailContent(
    parentTip: '정리 장소를 그림이나 사진으로 표시하면 아이가 스스로 찾기 쉬워요.',
    materials: '정리할 물건, 표시된 수납 공간',
    safetyNote: '무겁거나 높은 곳의 물건은 아이에게 맡기지 마세요.',
  ),
  'B-02': CardDetailContent(
    parentTip: '모든 장난감을 치우는 목표보다 장난감 세 개처럼 끝이 보이는 목표를 정해 주세요.',
    materials: '장난감 바구니 또는 선반',
    safetyNote: '작은 부품은 삼킴 위험이 없는지 먼저 확인해 주세요.',
  ),
  'B-03': CardDetailContent(
    parentTip: '벗은 옷을 보자마자 바구니에 넣을 수 있도록 바구니 위치를 일정하게 유지해 주세요.',
    materials: '낮은 빨래 바구니',
    safetyNote: '무거운 빨래 바구니를 들게 하지 마세요.',
  ),
  'B-04': CardDetailContent(
    parentTip: '흘린 것을 발견하고 어른에게 알리는 것도 중요한 성공이에요.',
    materials: '작은 수건 또는 키친타월',
    safetyNote: '유리 조각, 세제, 뜨거운 음식은 아이가 닦지 않도록 해주세요.',
  ),
  'B-05': CardDetailContent(
    parentTip: '색이나 종류 한 가지 기준으로만 나누어도 충분해요.',
    materials: '깨끗한 빨래, 바구니 두 개',
    safetyNote: '세제나 세탁기 조작은 보호자가 담당해 주세요.',
  ),
  'O-01': CardDetailContent(
    parentTip: '정답을 맞히게 하기보다 날씨 그림을 보고 이유를 말해 보는 경험을 도와 주세요.',
    materials: '날씨에 맞는 옷 두 가지 선택지',
    safetyNote: '기온 변화와 자외선, 비 예보는 보호자가 최종 확인해 주세요.',
  ),
  'O-02': CardDetailContent(
    parentTip: '가방에 넣을 물건을 두세 개로 제한하면 아이가 순서를 익히기 좋아요.',
    materials: '가방, 그림 준비물 카드',
    safetyNote: '약, 날카로운 물건, 개인정보가 든 물건은 보호자가 챙겨 주세요.',
  ),
  'O-03': CardDetailContent(
    parentTip: '글을 읽지 않아도 그림 체크표를 보고 하나씩 확인할 수 있게 해주세요.',
    materials: '그림 체크표, 가방, 신발',
    safetyNote: '출발 시간과 문 잠금, 교통수단 확인은 보호자가 맡아 주세요.',
  ),
  'S-01': CardDetailContent(
    parentTip: '실제 위험한 장소가 아닌 집 안의 안전한 공간에서 멈추고 보기 연습을 해주세요.',
    materials: '멈춤 그림 카드',
    safetyNote: '도로, 주차장, 출입문 근처에서는 항상 보호자가 가까이 있어야 합니다.',
  ),
  'S-02': CardDetailContent(
    parentTip: '손을 잡고 신호를 기다리는 두 가지 행동만 먼저 연습해 주세요.',
    materials: '안전한 산책 환경',
    safetyNote: '아이가 혼자 길을 건너도록 연습시키지 마세요.',
  ),
  'S-03': CardDetailContent(
    parentTip: '위험한 물건을 보았을 때 만지지 않고 어른에게 알리는 말을 함께 연습해 주세요.',
    materials: '위험 물건 그림 카드',
    safetyNote: '실제 칼, 약, 세제, 전기 제품으로 연습하지 마세요.',
  ),
  'S-04': CardDetailContent(
    parentTip: '도움이 필요할 때 쓸 짧은 문장을 가족과 반복해 보세요.',
    materials: '도움 요청 그림 또는 문장 카드',
    safetyNote: '위급한 상황에서는 아이 곁을 떠나지 말고 보호자가 즉시 대응해 주세요.',
  ),
  'S-05': CardDetailContent(
    parentTip: '개인정보를 외우게 하기보다 믿을 수 있는 보호자에게 도움을 요청하는 방법을 우선해 주세요.',
    materials: '가족 사진 또는 연락 카드',
    safetyNote: '주소와 연락처 같은 개인정보를 낯선 사람에게 말하도록 연습시키지 마세요.',
  ),
};
