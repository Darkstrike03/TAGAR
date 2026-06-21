import 'package:flutter_test/flutter_test.dart';
import 'package:tagar/app.dart';

void main() {
  testWidgets('App renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const TagarApp());
    expect(find.text('Tagar'), findsOneWidget);
  });
}
