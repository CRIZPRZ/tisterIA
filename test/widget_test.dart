import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:tipster_ia/main.dart';
import 'package:tipster_ia/state/app_state.dart';

void main() {
  testWidgets('Onboarding screen shows on launch', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const TipsterApp(),
      ),
    );

    expect(find.text('Tipster IA'), findsOneWidget);
    expect(find.text('Comenzar'), findsOneWidget);
  });
}
