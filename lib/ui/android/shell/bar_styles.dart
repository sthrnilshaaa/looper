/// Styles for the Android mini music bar.
enum MusicBarStyle {
  pill,
  sections,
  artglow,
  bare;

  static MusicBarStyle fromSetting(String? value) => switch (value) {
    'sections' => sections,
    'artglow' => artglow,
    'bare' => bare,
    _ => pill,
  };
}

/// Styles for the Android root navigation bar.
enum NavbarStyle {
  premium,
  classic,
  capsule,
  minimal;

  static NavbarStyle fromSetting(String? value) => switch (value) {
    'classic' => classic,
    'capsule' => capsule,
    'minimal' => minimal,
    _ => premium,
  };
}
