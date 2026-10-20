# flutter_screenutil_wasm

[English](README.md) · [可运行示例](example/README.md) · [贡献与回归说明](CONTRIBUTING.md)

基于 [flutter_screenutil 5.9.3](https://pub.dev/packages/flutter_screenutil/versions/5.9.3)
的独立 fork，针对 Flutter Web Release Wasm 的窗口缩放增加非递归遍历修复。
也可以用于普通 JS Web 构建和非 Web Flutter 应用。这不是上游官方版本。

![Release Wasm 桌面宽度示例](doc/example.png)

## 修复的问题和边界

已复现的 Chrome Release Wasm 场景中，窗口尺寸变化时，`ScreenUtilInit`
递归遍历 Element 树触发 `RangeError: Maximum call stack size exceeded`，
导致画面停留在原尺寸，刷新后才适应新窗口。Debug Wasm 或 Release JS
可能表现正常，因此不能仅用 debug 运行结果验收。

本包将这段遍历替换为显式栈，保留原有的父节点优先、同级从左到右顺序、
同步执行时机、组件身份和重建筛选规则。尺寸计算公式不变，也不通过更换
应用 key 重建整棵树。遍历仍是 O(N)，不会消除扫描或重建组件的开销。

## 安装

正式发布后的依赖写法：

```yaml
dependencies:
  flutter_screenutil_wasm: ^5.9.3
```

发布前，可使用本地源码：

```yaml
dependencies:
  flutter_screenutil_wasm:
    path: ../flutter_screenutil_wasm
```

首个 fork 版本号沿用 **5.9.3**，表示基于上游 5.9.3。保留上游 SDK 约束：
Dart `>=2.17.0 <4.0.0`、Flutter `>=3.10.0`。当前验证环境为 Flutter 3.44.9 /
Dart 3.12.2、Chrome 155；尚未单独验证最低 SDK 和全部原生设备平台。
能否构建、运行 Wasm 还取决于 Flutter SDK 和浏览器支持情况。

## 初始化

```dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_wasm/flutter_screenutil_wasm.dart';

void main() => runApp(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        fontSizeResolver: FontSizeResolvers.radius,
        builder: (context, child) => MaterialApp(home: child),
        child: const ExamplePage(),
      ),
    );

class ExamplePage extends StatelessWidget {
  const ExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 240.w,
          child: Text('调整窗口大小', style: TextStyle(fontSize: 16.sp)),
        ),
      ),
    );
  }
}
```

`designSize` 填设计稿的逻辑尺寸，而不是当前窗口尺寸。尺寸值应在初始化后的
组件 build 中读取，不要提前存入顶层变量或静态变量。

## 常用 API

| API | 含义 |
| --- | --- |
| `100.w` | 设计稿宽度乘以宽度比例 |
| `40.h` | 设计稿高度乘以高度比例 |
| `8.r` | 乘以宽高比例中的较小值 |
| `16.sp` | 由字体解析器计算字体大小 |
| `0.5.sw`、`0.5.sh` | 当前逻辑视图宽高的比例 |
| `16.horizontalSpace`、`16.verticalSpace` | 缩放后的间距组件 |
| `ScreenUtil().screenWidth`、`.screenHeight` | 当前逻辑视图宽高 |
| `RPadding`、`REdgeInsets`、`RSizedBox` | 保留的上游布局辅助组件 |

**字体规则：** 上游默认解析器为 `FontSizeResolvers.width`，即使设置
`minTextAdapt: true`，`ScreenUtilInit` 的默认解析器仍按宽度计算 `.sp`。
需要按宽高较小比例缩放时，请像示例一样显式指定 `FontSizeResolvers.radius`。
本包保留这一行为；Flutter 的系统文字缩放仍会作用于 `Text`，示例不会关闭
无障碍字体设置。

尺寸缩放不能代替布局结构调整。需要在宽屏、窄屏切换结构时，仍应结合
`LayoutBuilder`、约束和断点。上游基于组件类型名称的重建筛选逻辑保持不变。

## 从 flutter_screenutil 迁移

1. 将依赖改为 `flutter_screenutil_wasm`。
2. 将所有 `package:flutter_screenutil/flutter_screenutil.dart` 替换为
   `package:flutter_screenutil_wasm/flutter_screenutil_wasm.dart`。
3. 执行 `flutter pub get`，检查 `flutter pub deps`，确保初始化、尺寸扩展、
   本地依赖包中的引用都使用同一个 fork。

新旧包拥有各自独立的 Dart 类型和 `ScreenUtil` 单例，不要混用初始化和扩展。
第三方包若仍依赖原包，需要单独迁移或评估集成方式，不能通过改名自动替换。

本包保留 5.9.3 的公共 API，只修复缩放遍历中的递归问题，不承诺解决全部
Web/Wasm 或上游问题。其他递归路径，例如实验性的
`ScreenUtil.registerToBuild(context, true)`，没有改动。
旧 `textScaleFactor` getter 保留原有接口和行为。

## 示例与验证

[交互示例](example/README.md) 包含实时尺寸数值、缩放色块、草稿输入和计数器。
缩放窗口时应更新尺寸并保留已输入内容与计数。

在包根目录执行：

```sh
flutter pub get
flutter test --concurrency=1
cd example
flutter pub get
flutter run -d chrome --wasm
```

针对本问题，还必须验证 Release 构建。完整构建与静态服务命令见示例文档。
[贡献说明](CONTRIBUTING.md) 提供自动化 Release Wasm/JS 回归方法：
三个嵌套深度、共 48 次缩放，检查实际渲染尺寸、字体、视图边界、组件状态和异常。

## 来源与许可证

- 本包仓库：https://github.com/2697a/flutter_screenutil_wasm
- 上游仓库：https://github.com/OpenFlutter/flutter_screenutil
- [本包变更记录](CHANGELOG.md) · [保留的上游历史](doc/UPSTREAM_CHANGELOG.md)
- 保留 Apache-2.0 [LICENSE](LICENSE) 和原作者归属，变更说明见 [NOTICE](NOTICE)。
