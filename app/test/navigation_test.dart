import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kina_data/kina_data.dart';

import 'helpers.dart';

void main() {
  late KinaDatabase db;

  setUp(() => db = memoryDatabase());
  tearDown(() => db.close());

  testWidgets('wide windows use a side rail', (tester) async {
    await pumpApp(tester, db);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    final title = find.descendant(
      of: find.byType(AppBar),
      matching: find.byType(Text),
    );
    expect(tester.widgetList<Text>(title).map((t) => t.data), [
      'KINA CALCULATOR',
    ]);
    await goTo(tester, 'Analysis');
    expect(tester.widgetList<Text>(title).map((t) => t.data), [
      'KINA CALCULATOR',
      'Analysis',
    ]);
  });

  testWidgets('phones use a bottom bar and keep page state', (tester) async {
    await pumpApp(tester, db, size: const Size(412, 915));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);

    await goTo(tester, 'Marketplace');
    await tester.enterText(find.byKey(const Key('marketPrice')), '7m');
    await goTo(tester, 'Calculator');
    await goTo(tester, 'Marketplace');
    expect(find.widgetWithText(TextField, '7m'), findsOneWidget);
  });
}
