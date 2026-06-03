import 'package:flutter_test/flutter_test.dart';
import 'package:wanderly/app.dart';
import 'package:wanderly/features/auth/providers/auth_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final authProvider = AuthProvider();
    await tester.pumpWidget(WanderlyApp(authProvider: authProvider));
  });
}