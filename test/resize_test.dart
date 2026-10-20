import 'package:flutter/material.dart';
import 'package:flutter_screenutil_wasm/flutter_screenutil_wasm.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('resize marks descendants once in parent-first sibling order', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1133, 744);
    addTearDown(tester.view.reset);
    final marks = <String>[];

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(1133, 744),
        responsiveWidgets: const ['_ObservedWidget'],
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: _ObservedWidget(
            name: 'parent',
            marks: marks,
            child: Column(
              children: [
                _ObservedWidget(
                  name: 'first',
                  marks: marks,
                  child: _ObservedWidget(name: 'grandchild', marks: marks),
                ),
                _ObservedWidget(name: 'second', marks: marks),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    marks.clear();

    tester.view.physicalSize = const Size(1512, 982);

    expect(marks, ['parent', 'first', 'grandchild', 'second']);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('repeated resize updates scale without replacing editor state', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1133, 744);
    addTearDown(tester.view.reset);
    final key = GlobalKey<ResizeEditorProbeState>();

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(1133, 744),
        child: MaterialApp(home: ResizeEditorProbe(key: key)),
      ),
    );
    await tester.pumpAndSettle();
    final originalState = key.currentState!;
    await tester.enterText(find.byType(TextField), 'keep this draft');
    originalState.text.selection = const TextSelection.collapsed(offset: 4);
    originalState.scroll.jumpTo(300);
    await tester.pump();

    for (final size in [
      const Size(1512, 982),
      const Size(700, 900),
      const Size(1133, 744),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byKey(const ValueKey('scaled'))).width,
          closeTo(100 * size.width / 1133, 0.000001));
      expect(key.currentState, same(originalState));
      expect(originalState.text.text, 'keep this draft');
      expect(originalState.text.selection.baseOffset, 4);
      expect(originalState.focus.hasFocus, isTrue);
      expect(originalState.scroll.offset, 300);
      expect(tester.takeException(), isNull);
    }

    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.physicalSize = const Size(1200, 800);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

// Records the actual Element marking boundary, before Flutter's build scheduler
// can reorder dirty elements. A reversed traversal or duplicate visit is visible.
class _ObservedWidget extends StatelessWidget {
  const _ObservedWidget({required this.name, required this.marks, this.child});

  final String name;
  final List<String> marks;
  final Widget? child;

  @override
  StatelessElement createElement() => _ObservedElement(this);

  @override
  Widget build(BuildContext context) => child ?? const SizedBox.shrink();
}

class _ObservedElement extends StatelessElement {
  _ObservedElement(_ObservedWidget super.widget);

  @override
  void markNeedsBuild() {
    final observed = widget as _ObservedWidget;
    observed.marks.add(observed.name);
    super.markNeedsBuild();
  }
}

class ResizeEditorProbe extends StatefulWidget {
  const ResizeEditorProbe({super.key});

  @override
  State<ResizeEditorProbe> createState() => ResizeEditorProbeState();
}

class ResizeEditorProbeState extends State<ResizeEditorProbe> {
  final text = TextEditingController();
  final focus = FocusNode();
  final scroll = ScrollController();

  @override
  void dispose() {
    text.dispose();
    focus.dispose();
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(
          children: [
            SizedBox(key: const ValueKey('scaled'), width: 100.w, height: 20),
            TextField(controller: text, focusNode: focus),
            Expanded(
              child: ListView.builder(
                controller: scroll,
                itemCount: 100,
                itemExtent: 40,
                itemBuilder: (_, index) => Text('row $index'),
              ),
            ),
          ],
        ),
      );
}
