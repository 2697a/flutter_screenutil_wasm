# Contributing and release checks

Use a Flutter SDK that supports the target you are testing. The verified
environment is Flutter 3.44.9 / Dart 3.12.2, Chrome 155. Node 20.10+ is needed only
for the browser regression; Python 3 can serve a built example. These are
developer tools, not package runtime dependencies.

## Package and example

From the package root:

```sh
flutter pub get
flutter test --concurrency=1
flutter analyze
cd example
flutter pub get
flutter test --concurrency=1
flutter analyze
flutter build web --release --wasm
```

Follow [example/README.md](example/README.md) for manual resize and input checks.
Run Flutter build/test commands serially on memory-constrained machines.

## Automated Release browser regression

From the package root:

```sh
cd test/web_resize/fixture
flutter pub get
flutter build web --release --wasm
cd ../../..
node --experimental-websocket test/web_resize/run.mjs
```

The script starts its own local server and an isolated headless Chrome profile;
it does not attach to a user's existing browser. It tests actual Wasm/Skwasm
and JS/CanvasKit artifacts at depths 20, 150 and 200, with eight resize operations
per case. It checks rendered width, height, font size, view bounds, retained leaf
State and uncaught exceptions, including the original stack overflow.

On macOS it defaults to the standard Google Chrome application path; on other
systems it invokes `google-chrome`. Set `CHROME_BIN` to your Chrome executable
when needed (including Windows). An optional positional argument selects a
custom Web build directory. Node 22+ provides WebSocket without an experimental
flag; the documented command also supports Node 20.10+.
See the [Node.js WebSocket history](https://nodejs.org/api/globals.html#class-websocket).

## Scope when changing the patch

Keep scaling formulas, synchronous traversal ordering and widget State identity
stable. Retain the upstream SDK constraints unless a separately documented
compatibility change is intended. Type-name-based filtering, experimental
registration APIs and other upstream limitations are not rewritten by this
patch. Avoid broad unrelated changes when updating the upstream base.

Keep LICENSE and original source attribution intact. Identify modified library
files and record functional changes in CHANGELOG.md and NOTICE. The historical
upstream changelog is kept separately under doc/.

## Publication preflight (does not publish)

From the package root:

```sh
flutter pub publish --dry-run
```

Inspect the complete file list and validation summary, not only the exit code.
The package must include its library, LICENSE, NOTICE, README, CHANGELOG and
runnable example. `.pubignore` excludes generated directories, lockfiles,
local overrides and host-only validation notes. The dry run validates package
contents; it does not upload the package, reserve the name, authenticate a
publisher or guarantee the server's eventual acceptance.

When exporting this directory from a larger application repository, preserve
the ignore files and omit host-only notes (`LOCAL_PATCHES.md` and
`PUBLISH_CHECK.md`), generated files and local overrides from the public source
repository as well.

Repository and issue links must point to this fork. Push the reviewed package
sources to the public repository before a real release so the links resolve to
the matching source. This guide intentionally performs preflight only.
