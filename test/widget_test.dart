import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:growup/main.dart';

void main() {
  testWidgets('shows the action library and parent mode', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const GrowUpApp());
    await tester.pumpAndSettle();

    expect(find.text('오늘 어떤 행동을 해볼까요?'), findsOneWidget);
    expect(find.text('손을 씻어요'), findsOneWidget);

    await tester.tap(find.text('부모 모드'));
    await tester.pumpAndSettle();

    expect(find.text('행동을 관찰하고 다음을 살펴보세요.'), findsOneWidget);
    expect(find.text('손 씻기'), findsOneWidget);
  });
}
