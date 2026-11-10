import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iraq_ai/main.dart';
void main(){TestWidgetsFlutterBinding.ensureInitialized();testWidgets('welcome screen', (tester)async{SharedPreferences.setMockInitialValues({});await tester.pumpWidget(const IraqAI());await tester.pumpAndSettle();expect(find.text('IRAQ AI – ذكاء العراق'),findsOneWidget);});}
