import 'package:flutter_test/flutter_test.dart';

import 'package:full_wave_rectifier/main.dart';

void main() {
  testWidgets('app loads the rectifier lab home screen', (tester) async {
    await tester.pumpWidget(const RectifierLabApp());

    expect(find.text('BASIC ELECTRONICS LAB PROJECT'), findsOneWidget);
    expect(find.text('Topic : Full Wave Rectification'), findsOneWidget);
  });
}
