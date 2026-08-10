import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:growup/main.dart';

void main() {
  testWidgets('opens the action library from home', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const GrowUpApp());
    await tester.pumpAndSettle();

    expect(find.text('오늘 어떤 걸\n해볼까?'), findsOneWidget);
    await tester.tap(find.text('오늘 해볼 행동'));
    await tester.pumpAndSettle();

    expect(find.text('오늘 어떤 행동을 해볼까요?'), findsOneWidget);
    expect(find.text('손을 씻어요'), findsOneWidget);
  });
}
