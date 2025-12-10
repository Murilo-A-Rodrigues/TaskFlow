import 'package:flutter/material.dart';
import '../services/storage/preferences_service.dart';

/// Gerencia o ThemeMode atual e notifica ouvintes quando ele muda.
///
/// Suporta três modos:
/// - ThemeMode.system: Segue o tema do sistema operacional
/// - ThemeMode.light: Sempre claro
/// - ThemeMode.dark: Sempre escuro
///
/// Persiste a preferência via PreferencesService.
class ThemeController extends ChangeNotifier {
  final PreferencesService _preferencesService;
  ThemeMode _mode = ThemeMode.light;
  bool _isInitialized = false;

  ThemeController(this._preferencesService);

  /// Verifica se o tema já foi carregado
  bool get isInitialized => _isInitialized;

  /// Modo de tema atual
  ThemeMode get mode => _mode;

  /// Verifica se está em modo escuro
  bool get isDarkMode => _mode == ThemeMode.dark;

  /// Verifica se está seguindo o tema do sistema
  bool get isSystemMode => _mode == ThemeMode.system;

  /// Carrega o tema salvo das preferências
  Future<void> loadTheme() async {
    if (_isInitialized) return;

    final savedMode = _preferencesService.themeMode;
    _mode = _stringToThemeMode(savedMode);
    _isInitialized = true;
    notifyListeners();
  }

  /// Define um novo modo de tema e salva nas preferências
  Future<void> setThemeMode(ThemeMode newMode) async {
    if (_mode == newMode) return;

    _mode = newMode;
    await _preferencesService.setThemeMode(_themeModeToString(newMode));
    notifyListeners();
  }

  /// Alterna entre claro e escuro (quando não está em modo sistema)
  Future<void> toggleTheme() async {
    if (_mode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else {
      await setThemeMode(ThemeMode.light);
    }
  }

  /// Converte ThemeMode para String para persistência
  String _themeModeToString(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
  }

  /// Converte String para ThemeMode
  ThemeMode _stringToThemeMode(String mode) {
    return switch (mode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };
  }
}
