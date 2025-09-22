import 'package:flutter_test/flutter_test.dart';
import 'package:family_app_flutter/main.dart';
import 'package:family_app_flutter/providers/chat_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Создаём минимальный экземпляр приложения с пустым ChatProvider.
    final chatProvider = ChatProvider();
    await tester.pumpWidget(MyApp(chatProvider: chatProvider));
  });
}
