import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/main.dart';

void main() {
  testWidgets('NutriGuideApp loads home screen with bottom navigation',
      (WidgetTester tester) async {
    await tester.pumpWidget(const NutriGuideApp());
    await tester.pumpAndSettle();

    // Verify main app bar title
    expect(find.text('NutriGuide'), findsOneWidget);

    // Verify NavigationBar items
    expect(find.text('Browse'), findsOneWidget);
    expect(find.text('Assistant'), findsOneWidget);

    // Verify Compact Disclaimer Banner is present
    expect(
      find.text('Informational only — not medical advice.'),
      findsOneWidget,
    );
  });

  testWidgets('NutriGuideApp switches tabs on navigation bar tap',
      (WidgetTester tester) async {
    await tester.pumpWidget(const NutriGuideApp());
    await tester.pumpAndSettle();

    // Tap on 'Assistant' tab
    final assistantTab = find.text('Assistant');
    expect(assistantTab, findsOneWidget);
    await tester.tap(assistantTab);
    await tester.pumpAndSettle();

    // Verify Assistant greeting text
    expect(
      find.textContaining('Ask me what you want to know about any particular human disease'),
      findsOneWidget,
    );
  });
}
