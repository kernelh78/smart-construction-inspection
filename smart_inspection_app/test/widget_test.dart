import 'package:flutter_test/flutter_test.dart';
import 'package:smart_inspection_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartInspectionApp());
    expect(find.byType(SmartInspectionApp), findsOneWidget);
  });
}
