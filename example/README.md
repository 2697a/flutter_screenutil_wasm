# Interactive resize example / 窗口缩放示例

A standalone Flutter Web application using a path dependency on the package.
No host application imports, services, assets, or configuration are needed.
The UI uses the active theme and supports light/dark system preferences.

这个示例可以脱离主应用单独运行，包含实时缩放数值、尺寸色块、草稿输入框
和计数器。颜色来自当前主题，通过 `context.color` 读取。

## Run / 运行

From this `example` directory, using a Flutter SDK with Web/Wasm support:

```sh
flutter pub get
flutter run -d chrome --wasm
```

For the ordinary JS development build, use `flutter run -d chrome`.

## Verify Release Wasm / 验证 Release Wasm

```sh
flutter build web --release --wasm
python3 -m http.server 8000 --bind 127.0.0.1 --directory build/web
```

Open http://127.0.0.1:8000 in Chrome. Keep the server running while testing.
Use HTTP; opening `index.html` directly as a file does not serve Wasm correctly.
The default loader chooses a supported rendering path. In a compatible browser,
`?renderer=skwasm` requests the Wasm path and `?renderer=canvaskit` requests the
JS fallback included in the Wasm build. Check browser Network resources for
`main.dart.wasm` or `main.dart.js` to confirm the actual target.

也可单独构建普通 JS Release 作为对照：

```sh
flutter build web --release --output build/web_js
python3 -m http.server 8001 --bind 127.0.0.1 --directory build/web_js
```

Open http://127.0.0.1:8001. Do not use `?renderer=skwasm` with this JS-only build.

## What to check / 检查内容

1. Type a draft and increase the counter.
2. Shrink the window to a phone width, enlarge it, and restore its original size.
3. Confirm that viewport metrics, the preview box and font size change without
   refreshing; the draft, selection and count should remain intact.
4. Repeat in the Release Wasm and JS rendering paths; inspect the console for
   uncaught exceptions.

设计尺寸为 `360 × 690`，字体显式使用 `FontSizeResolvers.radius`。
示例不会在缩放时更换应用 key，也不会销毁、重建输入控制器。

## Tests / 测试

```sh
flutter test --concurrency=1
flutter analyze
```

The widget regression checks actual preview width plus draft, selection,
controller identity and counter retention across narrow/wide/restore sizes.
For deep-tree browser regressions, see the package [contributor guide](../CONTRIBUTING.md).

Only Web platform scaffolding is included. To try other platforms, add their
platform directories in a separate working copy with your Flutter SDK.
