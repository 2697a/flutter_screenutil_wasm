import 'package:flutter/material.dart';
import 'package:flutter_screenutil_wasm_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('resize updates the preview and retains the draft and counter',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1133, 744);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const ResizeExampleApp());
    await tester.pumpAndSettle();
    final preview = find.byKey(const ValueKey('scaled-box'));
    expect(tester.getSize(preview).width, closeTo(100 * 1133 / 360, 0.001));

    final draft = find.byKey(const ValueKey('draft-field'));
    await tester.enterText(draft, 'Keep this draft after resizing');
    final field = tester.widget<TextField>(draft);
    final controller = field.controller!;
    controller.selection = const TextSelection(baseOffset: 5, extentOffset: 9);
    await tester.ensureVisible(find.text('Count: 0'));
    await tester.tap(find.text('Count: 0'));
    await tester.pumpAndSettle();

    for (final size in [
      const Size(500, 900),
      const Size(320, 690),
      const Size(1512, 982),
      const Size(1133, 744),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.getSize(preview).width,
          closeTo(100 * size.width / 360, 0.001));
      expect(tester.widget<TextField>(draft).controller, same(controller));
      expect(controller.text, 'Keep this draft after resizing');
      expect(controller.selection,
          const TextSelection(baseOffset: 5, extentOffset: 9));
      expect(find.text('Count: 1'), findsOneWidget);
    }
  });
}
