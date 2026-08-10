import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    expect(cards, hasLength(26));
    for (final card in cards.cast<Map<String, dynamic>>()) {
      final cardId = card['cardId'] as String;
      expect(cardDetailContentById[cardId], isNotNull, reason: cardId);
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
}
