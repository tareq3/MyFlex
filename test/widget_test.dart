import 'package:dhaka_flix/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App loads without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const DhakaFlixApp());
    expect(find.text('DHAKA'), findsOneWidget);
  });
}
