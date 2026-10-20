import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil_wasm/flutter_screenutil_wasm.dart';

@JS('screenUtilResizeSnapshot')
external set _snapshot(JSFunction value);

final _leafKey = GlobalKey<ScaledLeafState>();
final _boxKey = GlobalKey();
final _textKey = GlobalKey();
var _created = 0;
var _disposed = 0;

void main() {
  _snapshot = (() {
    final leaf = _leafKey.currentState;
    final box = _boxKey.currentContext?.findRenderObject() as RenderBox?;
    final text = _textKey.currentWidget as Text?;
    return jsonEncode({
      'caseId': Uri.base.queryParameters['case'],
      'ready': box?.hasSize ?? false,
      'width': box?.hasSize == true ? box!.size.width : null,
      'height': box?.hasSize == true ? box!.size.height : null,
      'fontSize': text?.style?.fontSize,
      'builds': leaf?.builds,
      'created': _created,
      'disposed': _disposed,
    }).toJS;
  }).toJS;

  runApp(
    const ScreenUtilInit(
      designSize: Size(1133, 744),
      minTextAdapt: true,
      child: MaterialApp(home: ProbeBody()),
    ),
  );
}

class ProbeBody extends StatelessWidget {
  const ProbeBody({super.key});

  @override
  Widget build(BuildContext context) {
    Widget child = ScaledLeaf(key: _leafKey);
    final depth = int.parse(Uri.base.queryParameters['depth'] ?? '150');
    for (var i = 0; i < depth; i++) {
      child = Padding(padding: EdgeInsets.zero, child: child);
    }
    return Scaffold(
      body: Align(alignment: Alignment.topLeft, child: child),
    );
  }
}

class ScaledLeaf extends StatefulWidget {
  const ScaledLeaf({super.key});

  @override
  State<ScaledLeaf> createState() => ScaledLeafState();
}

class ScaledLeafState extends State<ScaledLeaf> {
  var builds = 0;

  @override
  void initState() {
    super.initState();
    _created++;
  }

  @override
  void dispose() {
    _disposed++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    builds++;
    return SizedBox(
      key: _boxKey,
      width: 100.w,
      height: 40.h,
      child: Text(
        'resize',
        key: _textKey,
        style: TextStyle(fontSize: 16.sp),
      ),
    );
  }
}
