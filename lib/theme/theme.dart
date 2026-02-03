import 'package:flutter/material.dart';

// Helper function to convert Hex to Flutter Color
Color hexToColor(String hexString) {
  final hex = hexString.replaceAll('#', '');
  return Color(int.parse('FF$hex', radix: 16));
}

// --- Light Mode Colors ---
final Color lightPrimaryBlue = hexToColor('007AFF');
final Color lightSuccessGreen = hexToColor('4CD964');
final Color lightGrey100 =
    Colors.grey.shade100; // Text Field Fill (Default)
final Color lightGrey200 =
    Colors.grey.shade200; // Text Field Fill (Hover)
final Color lightGrey300 =
    Colors.grey.shade300; // Main Background
final Color lightGrey500 =
    Colors.grey.shade500; // Icons, Hint Text

// --- Dark Mode Colors ---
final Color darkPrimaryBlue = hexToColor('2D9CDB');
final Color darkSuccessGreen = hexToColor('34C759');
final Color darkNavyBackground = hexToColor(
  '1A1E27',
); // Main Background
final Color darkCharcoalSurface = const Color.fromARGB(
  34,
  99,
  98,
  98,
); //Field Background
final Color darkSubtleText = hexToColor(
  '8C8C8C',
); // Hint Text/Subtle elements

// ====================================================================
//                             1. LIGHT MODE THEME
// ====================================================================
ThemeData lightMode = ThemeData(
  brightness: Brightness.light,

  // MAIN BACKGROUND: Shade of Grey300
  scaffoldBackgroundColor: lightGrey300,

  colorScheme: ColorScheme.light(
    // Primary Action Color (Buttons)
    primary: lightPrimaryBlue,
    onPrimary: Colors.white,

    // Input Field / Surface Background (Default)
    surface: lightGrey100,
    onSurface: Colors.black, // Text on surfaces
    // Secondary/Success Indicator
    secondary: lightSuccessGreen,

    // Used for icons and subtle text
    inversePrimary: lightGrey500,
  ),

  // Icon Theme: Shade of Grey500
  iconTheme: IconThemeData(color: lightGrey500),

  // Text Field Styling
  inputDecorationTheme: InputDecorationTheme(
    fillColor: lightGrey100,
    filled: true,
    hoverColor: lightGrey200, // Hover state
    border: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8.0)),
      borderSide: BorderSide.none,
    ),
    // Icon and Hint Text Colors
    iconColor: lightGrey500,
    prefixIconColor: lightGrey500,
    suffixIconColor: lightGrey500,
    hintStyle: TextStyle(color: lightGrey500),
  ),

  // Button Styling
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: lightPrimaryBlue,
      foregroundColor: Colors.white,
    ),
  ),
);

// ====================================================================
//                             2. DARK MODE THEME
// ====================================================================
ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,

  // MAIN BACKGROUND: Deep Navy Blue
  scaffoldBackgroundColor: darkNavyBackground,

  colorScheme: ColorScheme.dark(
    // Primary Action Color (Buttons)
    primary: darkPrimaryBlue,
    onPrimary: Colors.white,

    // INPUT FIELD/SURFACE BACKGROUND: Dark Charcoal Grey
    surface: darkCharcoalSurface,
    onSurface: Colors.white, // Text on surfaces
    // Secondary/Success Indicator
    secondary: darkSuccessGreen,

    // Used for sub-text, hint text, etc.
    inversePrimary: darkSubtleText,
  ),

  // Icon Theme: Shade of Grey500 (As requested for both themes)
  iconTheme: IconThemeData(
    color:
        lightGrey500, // Using the lightGrey500 color for consistency
  ),

  // Text Field Styling
  inputDecorationTheme: InputDecorationTheme(
    fillColor: darkCharcoalSurface,
    filled: true,
    border: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8.0)),
      borderSide: BorderSide.none,
    ),
    // Icon and Hint Text Colors
    iconColor: lightGrey500,
    prefixIconColor: lightGrey500,
    suffixIconColor: lightGrey500,
    hintStyle: TextStyle(color: darkSubtleText),
  ),

  // Button Styling
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: darkPrimaryBlue,
      foregroundColor: Colors.white,
    ),
  ),

  // AppBar (for consistency with dark background)
  appBarTheme: AppBarTheme(
    backgroundColor: darkNavyBackground,
    foregroundColor: Colors.white,
    elevation: 0,
  ),
);
