import 'package:flutter/material.dart';

extension ThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
}

extension StringCapitalize on String {
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

extension HexColor on String {
  Color get toColor {
    final hex = replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
}
