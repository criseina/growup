import 'package:flutter_test/flutter_test.dart';
import 'package:growup/main.dart';

void main() {
  testWidgets('shows the action library', (WidgetTester tester) async {
    await tester.pumpWidget(const GrowUpApp());
    await tester.pumpAndSettle();

    expect(find.text('오늘 어떤 행동을 해볼까요?'), findsOneWidget);
    expect(find.text('손을 씻어요'), findsOneWidget);
  });
}
