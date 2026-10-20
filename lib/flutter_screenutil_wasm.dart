/*
 * Created by 李卓原 on 2018/9/29.
 * email: zhuoyuan93@gmail.com
 */

// Modified for flutter_screenutil_wasm: renamed public library and added docs.
/// Screen and font scaling based on flutter_screenutil 5.9.3, with stack-safe
/// Element traversal when the viewport changes in Flutter Web Wasm builds.
///
/// Initialize with [ScreenUtilInit] before using [ScreenUtil] or [SizeExtension].
/// Use this package consistently for initialization and size extensions.
library flutter_screenutil_wasm;

export 'src/r_padding.dart';
export 'src/r_sizedbox.dart';
export 'src/screen_util.dart';
export 'src/screenutil_init.dart';
export 'src/size_extension.dart';
export 'src/screenutil_mixin.dart';
