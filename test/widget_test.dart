import 'package:flutter_test/flutter_test.dart';
import 'package:cielo_obs_20240191/main.dart';

void main() {
  testWidgets('App arranges without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const CieloObsApp());
    expect(find.text('Cielo Obs'), findsWidgets);
  });
}
