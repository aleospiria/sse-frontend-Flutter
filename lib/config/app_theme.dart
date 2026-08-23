import 'package:flutter/material.dart';
import 'package:sse_frontend_mobil/models/user.dart';

class AppTheme {
  AppTheme._();

  static const Color _primaryDark = Color(0xFF1E293B);
  static const Color _accentOrange = Color(0xFFF97316);
  static const Color _bgLight = Color(0xFFF1F5F9);
  static const Color _textDark = Color(0xFF1E293B);
  static const Color _textMuted = Color(0xFF64748B);
  static const Color _textLight = Color(0xFF94A3B8);
  static const Color _border = Color(0xFFE2E8F0);

  // Role color palettes
  static const Map<UserRole, RoleColors> roleColors = {
    UserRole.admin: RoleColors(
      primary: Color(0xFF1E293B),
      accent: Color(0xFFF97316),
      badge: Color(0xFFF97316),
      badgeBg: Color(0x1AF97316),
      label: 'ADMIN',
    ),
    UserRole.coordinador: RoleColors(
      primary: Color(0xFF1E40AF),
      accent: Color(0xFF3B82F6),
      badge: Color(0xFF3B82F6),
      badgeBg: Color(0x1A3B82F6),
      label: 'COORDINADOR',
    ),
    UserRole.operario: RoleColors(
      primary: Color(0xFF047857),
      accent: Color(0xFF10B981),
      badge: Color(0xFF10B981),
      badgeBg: Color(0x1A10B981),
      label: 'OPERARIO',
    ),
    UserRole.auditor: RoleColors(
      primary: Color(0xFF6D28D9),
      accent: Color(0xFF8B5CF6),
      badge: Color(0xFF8B5CF6),
      badgeBg: Color(0x1A8B5CF6),
      label: 'AUDITOR',
    ),
  };

  static Color get primaryDark => _primaryDark;
  static Color get accentOrange => _accentOrange;
  static Color get bgLight => _bgLight;
  static Color get textDark => _textDark;
  static Color get textMuted => _textMuted;
  static Color get textLight => _textLight;
  static Color get border => _border;

  static ThemeData get themeData => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryDark,
          primary: _primaryDark,
          secondary: _accentOrange,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: _bgLight,
        appBarTheme: const AppBarTheme(
          backgroundColor: _primaryDark,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _primaryDark, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEF4444)),
          ),
          labelStyle: const TextStyle(color: _textMuted, fontSize: 14),
          hintStyle: const TextStyle(color: _textLight, fontSize: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryDark,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _primaryDark,
            side: const BorderSide(color: _border),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: _border),
          ),
          margin: const EdgeInsets.only(bottom: 10),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          backgroundColor: Colors.white,
        ),
      );
}

class RoleColors {
  final Color primary;
  final Color accent;
  final Color badge;
  final Color badgeBg;
  final String label;

  const RoleColors({
    required this.primary,
    required this.accent,
    required this.badge,
    required this.badgeBg,
    required this.label,
  });
}
