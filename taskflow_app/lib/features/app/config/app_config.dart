/// Configurações centralizadas da aplicação
class AppConfig {
  // Layout Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  
  static const double defaultBorderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 16.0;
  
  // Animation Constants
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration quickAnimationDuration = Duration(milliseconds: 150);
  
  // Image Handling Constants
  static const int maxImageSize = 800;
  static const int imageQuality = 80;
  
  // Drawer Constants
  static const double drawerHeaderHeight = 200.0;
  static const double appBarHeight = 120.0;
  
  // Performance Constants
  static const int taskListMaxItems = 100;
  static const Duration debounceDelay = Duration(milliseconds: 500);
}