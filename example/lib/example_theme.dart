import 'package:flutter/material.dart';

/// Read colors from the active light or dark theme.
extension ExampleTheme on BuildContext {
  ColorScheme get color => Theme.of(this).colorScheme;
}
