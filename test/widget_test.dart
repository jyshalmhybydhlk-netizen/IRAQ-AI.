import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iraq_ai/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('IRAQ AI loads successfully', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const IraqAI());
    await tester.pumpAndSettle();

    expect(find.text('IRAQ AI - الذكاء الاصطناعي العراقي'), findsOneWidget);
    expect(find.text('اكتب سؤالك هنا...'), findsOneWidget);
  });
}
