import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:growup/avatar_reward_catalog.dart';
import 'package:growup/avatar_room.dart';
import 'package:growup/card_detail_content.dart';
import 'package:growup/growth_reward_repository.dart';
import 'package:growup/main.dart';
import 'package:growup/profile_repository.dart';

void main() {
  testWidgets('shows onboarding on first launch', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const GrowUpApp());
    await tester.pumpAndSettle();

    expect(find.text('작은 시도를 함께 기록해요'), findsOneWidget);
  });

  test('creates a default child profile', () async {
    SharedPreferences.setMockInitialValues({'onboarding_completed_v1': true});
    final profiles = await ProfileRepository().loadProfiles();

    expect(profiles, hasLength(1));
    expect(profiles.single.id, ProfileRepository.defaultProfileId);
  });

  test('all action cards have parent detail content', () async {
    final raw = await rootBundle.loadString('data/action_cards_v1.json');
    final cards =
        (jsonDecode(raw) as Map<String, dynamic>)['cards'] as List<dynamic>;

    expect(cards, hasLength(61));
    for (final card in cards.cast<Map<String, dynamic>>()) {
      final cardId = card['cardId'] as String;
      expect(
        cardDetailContentById[cardId] ?? defaultCardDetailContent,
        isNotNull,
        reason: cardId,
      );
    }
  });

  test('unlocks a reward only once for a first independent action', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = GrowthRewardRepository();

    final first = await repository.unlockFirstIndependent(
      profileId: 'child-a',
      cardId: 'H-01',
    );
    final second = await repository.unlockFirstIndependent(
      profileId: 'child-a',
      cardId: 'H-01',
    );

    expect(first?.item.id, 'bathroom_soap_01');
    expect(second, isNull);
    expect((await repository.loadEvents('child-a')), hasLength(1));
    expect(
      (await repository.unlockedItems('child-a')).single.id,
      'bathroom_soap_01',
    );
  });

  testWidgets('renders the home screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_completed_v1': true});

    await tester.pumpWidget(const GrowUpApp());
    await tester.pumpAndSettle();

    expect(find.text('오늘 어떤 걸 해볼까?'), findsOneWidget);
    expect(find.text('행동'), findsOneWidget);
    expect(find.text('아바타'), findsOneWidget);
    expect(find.text('기록'), findsOneWidget);
  });

  testWidgets('opens parent mode after a left swipe on a child card', (
    WidgetTester tester,
  ) async {
    var openedParentMode = false;
    const card = ActionCard(
      id: 'H-01',
      category: 'hygiene',
      title: '손 씻기',
      childTitle: '손을 씻어요',
      parentGuide: '',
      prerequisiteCardIds: [],
      nextActionCardIds: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ChildCardPage(
          card: card,
          initialLevel: null,
          onOpenParentMode: () => openedParentMode = true,
        ),
      ),
    );

    await tester.drag(
      find.byKey(const ValueKey('child-card-swipe-area')),
      const Offset(-260, 0),
    );
    expect(openedParentMode, isTrue);
  });

  test('all action cards map to a valid avatar reward', () async {
    final raw = await rootBundle.loadString('data/action_cards_v1.json');
    final cards = (jsonDecode(raw) as Map<String, dynamic>)['cards'] as List;
    final itemIds = avatarRewardItems.map((item) => item.id).toSet();

    expect(avatarRewardByCardId.length, cards.length);
    for (final card in cards.cast<Map<String, dynamic>>()) {
      final rewardId = avatarRewardByCardId[card['cardId']];
      expect(rewardId, isNotNull, reason: '${card['cardId']} 보상 누락');
      expect(itemIds, contains(rewardId));
    }
  });

  test('all six rooms have walking, fixed objects and theme-only slots', () {
    expect(avatarRooms, hasLength(6));
    final spaceItems = avatarRewardItems.where(
      (item) => item.type == UnlockableItemType.spaceItem,
    );
    for (final room in avatarRooms) {
      expect(room.walkableArea.polygon.length, greaterThanOrEqualTo(4));
      expect(
        room.walkableArea.contains(room.initialAvatarPosition),
        isTrue,
        reason: '${room.label}의 시작 발 위치가 바닥 밖에 있습니다.',
      );
      expect(room.fixedObjects, isNotEmpty);
      expect(room.slots, isNotEmpty);
      final allowedIds = room.slots
          .expand((slot) => slot.allowedItemIds)
          .toSet();
      final roomItemIds = spaceItems
          .where((item) => item.spaceId == room.id)
          .map((item) => item.id)
          .toSet();
      expect(allowedIds, containsAll(roomItemIds));
      expect(
        room.slots.every(
          (slot) => slot.allowedItemIds.every(roomItemIds.contains),
        ),
        isTrue,
      );
      expect(
        room.fixedObjects.every(
          (object) => room.walkableArea.contains(object.approachPoint),
        ),
        isTrue,
        reason: '${room.label} 고정 물건의 접근 지점이 바닥 밖에 있습니다.',
      );
      expect(
        room.slots.every(
          (slot) => room.walkableArea.contains(slot.approachPoint),
        ),
        isTrue,
        reason: '${room.label} 배치 물건의 접근 지점이 바닥 밖에 있습니다.',
      );
    }
  });

  test('avatar rooms follow the six-theme specification', () {
    expect(avatarRooms.map((room) => room.id), [
      'bathroom',
      'bedroom',
      'kitchen',
      'playroom',
      'entrance',
      'toilet',
    ]);
    expect(roomById('bathroom').categoryIds, {'hygiene'});
    expect(
      roomById('entrance').categoryIds,
      containsAll({'outing', 'safety_help'}),
    );
    expect(roomById('toilet').categoryIds, {'toilet'});
    expect(
      avatarRooms.expand((room) => room.categoryIds).toSet(),
      containsAll({
        'hygiene',
        'dressing',
        'meals',
        'belongings_home',
        'outing',
        'safety_help',
        'toilet',
      }),
    );
  });

  test(
    'avatar world uses independent layered backgrounds and object visuals',
    () {
      final backgrounds = avatarRooms
          .map((room) => room.backgroundAsset)
          .toSet();
      expect(backgrounds, hasLength(6));
      expect(
        backgrounds.every(
          (asset) => asset.startsWith('assets/avatar_layers/backgrounds/'),
        ),
        isTrue,
      );
      for (final room in avatarRooms) {
        for (final object in room.fixedObjects) {
          expect(object.visualAssetId, isNotEmpty);
          expect(object.visualSize.width, greaterThan(0));
          expect(object.visualSize.height, greaterThan(0));
          expect(object.visualDepth, inInclusiveRange(0, 100));
          expect(room.walkableArea.contains(object.approachPoint), isTrue);
        }
      }
    },
  );

  test('toilet rewards stay in the toilet theme', () {
    final toiletItems = avatarRewardItems.where(
      (item) => item.id.startsWith('toilet_'),
    );
    expect(toiletItems, hasLength(4));
    expect(toiletItems.every((item) => item.spaceId == 'toilet'), isTrue);
    for (var number = 1; number <= 7; number++) {
      expect(
        avatarRewardByCardId['T-${number.toString().padLeft(2, '0')}'],
        startsWith('toilet_'),
      );
    }
  });

  test('rejects placing an acquired object in another theme', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = GrowthRewardRepository();

    expect(
      () => repository.placeItem(
        profileId: 'child-a',
        spaceId: 'kitchen',
        itemId: 'bathroom_soap_01',
        x: .5,
        y: .5,
      ),
      throwsArgumentError,
    );
  });

  test('snaps a valid acquired object to its placement anchor', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = GrowthRewardRepository();

    final placement = await repository.placeItem(
      profileId: 'child-a',
      spaceId: 'toilet',
      itemId: 'toilet_soap_01',
      x: .76,
      y: .42,
    );

    expect(placement.x, .76);
    expect(placement.y, .42);
  });
}
