import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:full_wave_rectifier/main.dart';

void main() {
  testWidgets('app loads the rectifier lab home screen', (tester) async {
    await tester.pumpWidget(const RectifierLabApp());

    expect(find.text('BASIC ELECTRONICS LAB PROJECT'), findsOneWidget);
    expect(find.text('Topic : Full Wave Rectification'), findsOneWidget);
  });

  testWidgets('app fits a narrow mobile viewport without layout errors',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const RectifierLabApp());

    expect(tester.takeException(), isNull);
  });
}
