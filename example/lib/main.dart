import 'package:flutter/material.dart';
import 'package:flutter_screenutil_wasm/flutter_screenutil_wasm.dart';

import 'example_theme.dart';

void main() => runApp(const ResizeExampleApp());

class ResizeExampleApp extends StatelessWidget {
  const ResizeExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      // Explicitly choose the smaller scale for fonts on wide displays.
      fontSizeResolver: FontSizeResolvers.radius,
      builder: (context, child) => MaterialApp(
        title: 'ScreenUtil Wasm resize example',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true),
        darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
        home: child,
      ),
      child: const ResponsiveExamplePage(),
    );
  }
}

/// Keep the same State, controller and widget identity when the view resizes.
class ResponsiveExamplePage extends StatefulWidget {
  const ResponsiveExamplePage({super.key});

  @override
  State<ResponsiveExamplePage> createState() => _ResponsiveExamplePageState();
}

class _ResponsiveExamplePageState extends State<ResponsiveExamplePage> {
  final _draft = TextEditingController();
  var _count = 0;

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.of(context).size;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('flutter_screenutil_wasm')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Resize the window', style: textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  const Text(
                    'Type a draft and increase the counter. Resize the browser '
                    'without refreshing: sizes should update and your input '
                    'should stay in place.',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Viewport: ${viewport.width.toStringAsFixed(0)} × '
                    '${viewport.height.toStringAsFixed(0)}',
                    key: const ValueKey('viewport-label'),
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Design: 360 × 690 · width scale: '
                    '${ScreenUtil().scaleWidth.toStringAsFixed(2)} · height '
                    'scale: ${ScreenUtil().scaleHeight.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Scaled preview', style: textTheme.titleMedium),
                          const SizedBox(height: 12),
                          Text(
                            '100.w = ${100.w.toStringAsFixed(1)} · '
                            '40.h = ${40.h.toStringAsFixed(1)} · '
                            '16.sp = ${16.sp.toStringAsFixed(1)}',
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            key: const ValueKey('scaled-box'),
                            width: 100.w,
                            height: 40.h,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: context.color.primaryContainer,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Text scaled with 16.sp',
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: 16.sp,
                              color: context.color.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const ValueKey('draft-field'),
                    controller: _draft,
                    decoration: const InputDecoration(
                      labelText: 'Draft to keep after resizing',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => setState(() => _count++),
                    child: Text('Count: $_count'),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'This example uses FontSizeResolvers.radius. The package '
                    'default is FontSizeResolvers.width. Use layout constraints '
                    'and breakpoints alongside scaling in real applications.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
