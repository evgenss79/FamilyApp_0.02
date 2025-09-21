import 'package:flutter_test/flutter_test.dart';
import 'package:FamilyAppFlutter/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Загружаем корневой виджет
    await tester.pumpWidget(MyApp());
  });
}
