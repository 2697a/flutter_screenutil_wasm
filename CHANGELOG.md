## 5.9.3

Initial independent fork, based on flutter_screenutil 5.9.3.

- Replace recursive Element traversal in `ScreenUtilInit` resize handling with
  an explicit stack to avoid the reproduced Release Wasm stack overflow.
- Preserve traversal order, synchronous execution, rebuild filtering, public
  API symbols and upstream scaling formulas.
- Rename the package and public entry point to `flutter_screenutil_wasm`.
  Consumers must migrate imports consistently; the old package is a separate
  Dart library with a separate singleton.
- Add an interactive, theme-aware Web example, state-retention tests and
  automated Release Wasm/JS resize regressions.
- Add independent English/Chinese documentation, source attribution and
  publication file exclusions.
- Retain the legacy `textScaleFactor` getter unchanged, with a local diagnostic
  acknowledgement for its deprecated Flutter API call.

The upstream history is preserved in [doc/UPSTREAM_CHANGELOG.md](doc/UPSTREAM_CHANGELOG.md).
