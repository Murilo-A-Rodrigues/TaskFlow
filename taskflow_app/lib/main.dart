import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/task_service.dart';
import 'services/preferences_service.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/consent_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/policy_viewer_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa o serviço de preferências
  final preferencesService = PreferencesService();
  await preferencesService.init();
  
  runApp(TaskFlowApp(preferencesService: preferencesService));
}

class TaskFlowApp extends StatelessWidget {
  final PreferencesService preferencesService;
  
  const TaskFlowApp({super.key, required this.preferencesService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => TaskService()),
        ChangeNotifierProvider.value(value: preferencesService),
      ],
      child: MaterialApp(
        title: 'TaskFlow',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4F46E5), // Indigo primário do PRD
            brightness: Brightness.light,
          ).copyWith(
            primary: const Color(0xFF4F46E5), // Indigo #4F46E5
            secondary: const Color(0xFF475569), // Gray #475569
            tertiary: const Color(0xFFF59E0B), // Amber #F59E0B
            surface: const Color(0xFFFFFFFF), // Branco
            onSurface: const Color(0xFF0F172A), // Texto escuro
          ),
          useMaterial3: true,
          textTheme: const TextTheme(
            headlineSmall: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            elevation: 2,
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFFF59E0B), // Amber acento
          ),
        ),
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/onboarding': (context) => const OnboardingScreen(),
          '/consent': (context) => const ConsentScreen(),
          '/home': (context) => const HomeScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
        onGenerateRoute: (settings) {
          // Para rotas com parâmetros como /policy-viewer/privacy
          if (settings.name?.startsWith('/policy-viewer/') == true) {
            final policyType = settings.name!.split('/').last;
            return MaterialPageRoute(
              builder: (context) => PolicyViewerScreen(policyType: policyType),
              settings: settings,
            );
          }
          return null;
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
