// Widget tests for ZeroFlip: Up Is Down
import 'package:flutter_test/flutter_test.dart';

import 'package:anti_gravity_doodle_jump/main.dart';

void main() {
  testWidgets('App loads menu screen', (WidgetTester tester) async {
    await tester.pumpWidget(const AntiGravityApp());
    await tester.pumpAndSettle();
    expect(find.text('ZeroFlip'), findsWidgets);
  });
}
