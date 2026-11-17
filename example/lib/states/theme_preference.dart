class ThemePreference {
  const ThemePreference({this.isDark = false});

  final bool isDark;

  ThemePreference copyWith({bool? isDark}) =>
      ThemePreference(isDark: isDark ?? this.isDark);
}