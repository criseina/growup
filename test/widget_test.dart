import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:growup/card_detail_content.dart';
import 'package:growup/main.dart';
import 'package:growup/profile_repository.dart';

void main() {
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

  testWidgets('renders the home screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_completed_v1': true});

    await tester.pumpWidget(const GrowUpApp());
    await tester.pumpAndSettle();

    expect(find.text('오늘 어떤 걸\n해볼까?'), findsOneWidget);
    expect(find.text('오늘 해볼 행동'), findsOneWidget);
    expect(find.text('내 성장 기록'), findsOneWidget);
  });
}
