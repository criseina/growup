import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:growup/avatar_reward_catalog.dart';
import 'package:growup/avatar_character_system.dart';
import 'package:growup/avatar_quality.dart';
import 'package:growup/avatar_room.dart';
import 'package:growup/card_detail_content.dart';
import 'package:growup/growth_reward_repository.dart';
import 'package:growup/growth_reward_pages.dart';
import 'package:growup/main.dart';
import 'package:growup/profile_repository.dart';
import 'package:growup/room_object_sprite.dart';

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

  test('avatar QC loop keeps every room above the release threshold', () {
    final reports = AvatarQualityEvaluator.evaluateAll(avatarRooms);

    expect(reports, hasLength(6));
    for (final report in reports) {
      expect(
        report.issues.where((issue) => issue.level == AvatarQualityLevel.fail),
        isEmpty,
        reason: '${report.roomId}: ${report.issues.map((issue) => issue.code)}',
      );
      expect(report.overall, greaterThanOrEqualTo(75), reason: report.roomId);
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

  test('entrance keeps structural door and excludes outdoor fixed objects', () {
    final entrance = roomById('entrance');
    final ids = entrance.fixedObjects.map((object) => object.id).toSet();
    expect(ids, contains('entrance_door'));
    expect(ids, isNot(contains('entrance_traffic_light')));
    expect(ids, isNot(contains('entrance_crosswalk')));
    expect(
      entrance.fixedObjects
          .singleWhere((object) => object.id == 'entrance_door')
          .visualSource,
      RoomObjectVisualSource.backgroundStructure,
    );
  });

  testWidgets('space decoration renders the same fixed room objects', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const MaterialApp(home: SpacePage(profileId: 'child-a')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byType(PositionedRoomObject),
      findsNWidgets(
        roomById(
          'bathroom',
        ).fixedObjects.where((object) => object.shouldRenderAtlas).length,
      ),
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

  test('avatar movement speed is exactly 1.5 times the current speed', () {
    expect(
      AvatarMovementSystem.previousJourneyDuration,
      const Duration(milliseconds: 6000),
    );
    expect(AvatarMovementSystem.previousSpeedMultiplier, .2);
    expect(AvatarMovementSystem.speedIncrease, 1.5);
    expect(AvatarMovementSystem.speedMultiplier, closeTo(.3, .000001));
    expect(
      AvatarMovementSystem.journeyDuration,
      const Duration(milliseconds: 4000),
    );
    expect(
      AvatarMovementSystem.previousJourneyDuration.inMilliseconds /
          AvatarMovementSystem.journeyDuration.inMilliseconds,
      1.5,
    );
    expect(
      AvatarMovementSystem.walkCycleDuration,
      const Duration(milliseconds: 800),
    );
    final split = AvatarMovementSystem.durations(const RoomPoint(0, 0), const [
      RoomPoint(10, 0),
      RoomPoint(30, 0),
    ]);
    expect(split, const [
      Duration(milliseconds: 1333),
      Duration(milliseconds: 2667),
    ]);
    expect(
      split.fold<int>(0, (sum, duration) => sum + duration.inMilliseconds),
      AvatarMovementSystem.journeyDuration.inMilliseconds,
    );
    expect(
      AvatarMovementSystem.durations(const RoomPoint(0, 0), const [
        RoomPoint(20, 0),
      ]).single,
      const Duration(milliseconds: 4000),
    );
  });

  test('all room backgrounds share the canonical portrait viewport', () {
    expect(AvatarViewportSystem.designAspectRatio, closeTo(941 / 1672, .0001));
    for (final available in const [Size(360, 640), Size(800, 400)]) {
      final viewport = AvatarViewportSystem.contain(available);
      expect(viewport.width / viewport.height, closeTo(941 / 1672, .0001));
    }
  });

  test('walkable clamp keeps the avatar canvas inside the viewport', () {
    const area = WalkableArea([
      RoomPoint(0, 0),
      RoomPoint(100, 0),
      RoomPoint(100, 100),
      RoomPoint(0, 100),
    ]);
    final left = area.clamp(const RoomPoint(0, 50), const []);
    final right = area.clamp(const RoomPoint(100, 50), const []);
    expect(left.x, greaterThanOrEqualTo(WalkableArea.avatarHorizontalMargin));
    expect(
      right.x,
      lessThanOrEqualTo(100 - WalkableArea.avatarHorizontalMargin),
    );
  });

  test('fixed object visual bounds stay inside every theme viewport', () {
    for (final room in avatarRooms) {
      for (final object in room.fixedObjects.where(
        (item) => item.shouldRenderAtlas,
      )) {
        final bounds = object.visualBounds;
        expect(bounds.left, greaterThanOrEqualTo(0), reason: object.id);
        expect(bounds.top, greaterThanOrEqualTo(0), reason: object.id);
        expect(
          bounds.left + bounds.width,
          lessThanOrEqualTo(100),
          reason: object.id,
        );
        expect(
          bounds.top + bounds.height,
          lessThanOrEqualTo(100),
          reason: object.id,
        );
      }
    }
  });

  test('fixed objects use explicit wall or floor anchors', () {
    for (final room in avatarRooms) {
      for (final object in room.fixedObjects) {
        if (object.visualLayer == RoomVisualLayer.back) {
          expect(object.anchor, RoomObjectAnchor.wallCenter, reason: object.id);
        } else if (object.shouldRenderAtlas) {
          expect(
            object.anchor,
            RoomObjectAnchor.floorBottomCenter,
            reason: object.id,
          );
        }
      }
    }
  });

  test('same-layer floor objects do not substantially overlap', () {
    for (final room in avatarRooms) {
      final objects = room.fixedObjects
          .where(
            (object) =>
                object.shouldRenderAtlas &&
                object.anchor == RoomObjectAnchor.floorBottomCenter,
          )
          .toList();
      for (var i = 0; i < objects.length; i++) {
        for (var j = i + 1; j < objects.length; j++) {
          final overlap = objects[i].visualBounds.overlapRatio(
            objects[j].visualBounds,
          );
          expect(
            overlap,
            lessThan(.2),
            reason: '${room.id}: ${objects[i].id} / ${objects[j].id}',
          );
        }
      }
    }
  });

  test('avatar directions use one shared four-frame registry', () {
    expect(AvatarAnimationRegistry.walkFramesPerDirection, 4);
    expect(AvatarAnimationRegistry.directionRow(AvatarFacing.front), 0);
    expect(AvatarAnimationRegistry.directionRow(AvatarFacing.back), 1);
    expect(AvatarAnimationRegistry.directionRow(AvatarFacing.left), 2);
    expect(AvatarAnimationRegistry.directionRow(AvatarFacing.right), 3);
    expect(AvatarCharacterMetrics.runtimeScale, 1);
    expect(AvatarCharacterMetrics.groundAnchor, Alignment.bottomCenter);
  });

  test('movement path does not cross a room obstacle', () {
    const walkable = WalkableArea([
      RoomPoint(0, 0),
      RoomPoint(100, 0),
      RoomPoint(100, 100),
      RoomPoint(0, 100),
    ]);
    const obstacle = RoomRect(40, 30, 20, 40);
    final path = AvatarMovementSystem.path(
      from: const RoomPoint(20, 20),
      wanted: const RoomPoint(80, 80),
      walkableArea: walkable,
      obstacles: const [obstacle],
    );
    expect(path.length, greaterThanOrEqualTo(2));
    var cursor = const RoomPoint(20, 20);
    for (final destination in path) {
      final distance = cursor.distanceTo(destination);
      for (var step = 0; step <= distance.ceil(); step++) {
        final ratio = distance == 0 ? 0.0 : step / distance.ceil();
        final sample = RoomPoint(
          cursor.x + (destination.x - cursor.x) * ratio,
          cursor.y + (destination.y - cursor.y) * ratio,
        );
        expect(obstacle.contains(sample), isFalse);
        expect(walkable.contains(sample), isTrue);
      }
      cursor = destination;
    }
  });

  test('every room interaction resolves to an allowed ground point', () {
    for (final room in avatarRooms) {
      for (final object in room.fixedObjects) {
        final point = object.resolvedInteractionPoint;
        expect(room.walkableArea.contains(point), isTrue, reason: object.id);
        expect(
          room.collisions.any((area) => area.contains(point)),
          isFalse,
          reason: object.id,
        );
      }
    }
  });

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
