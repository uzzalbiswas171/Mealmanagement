import 'package:flutter_test/flutter_test.dart';
import 'package:mealmanagement/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MealManagerApp());
    expect(find.text('Meal Manager'), findsOneWidget);
  });
}
