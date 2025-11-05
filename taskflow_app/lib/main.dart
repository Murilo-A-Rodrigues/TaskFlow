import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/core/task_service_v2.dart';
import 'services/storage/preferences_service.dart';
import 'features/app/domain/repositories/task_repository.dart';
import 'features/app/infrastructure/repositories/task_repository_impl.dart';
import 'features/splashscreen/pages/splash_screen.dart';
import 'features/onboarding/pages/onboarding_screen.dart';
import 'features/auth/pages/consent_screen.dart';
import 'features/home/pages/home_screen.dart';
import 'features/settings/pages/settings_screen.dart';
import 'features/settings/pages/policy_viewer_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Carrega variáveis de ambiente (.env)
  await dotenv.load(fileName: ".env");
  
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
  
  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw Exception('Faltam SUPABASE_URL/SUPABASE_ANON_KEY no .env');
  }
  
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  
  // Inicializa o serviço de preferências
  final preferencesService = PreferencesService();
  await preferencesService.init();
  
  runApp(TaskFlowApp(
    preferencesService: preferencesService,
  ));
}

class TaskFlowApp extends StatelessWidget {
  final PreferencesService preferencesService;
  
  const TaskFlowApp({
    super.key, 
    required this.preferencesService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: preferencesService),
        // Injeção de dependência: Repository → Service
        Provider<TaskRepository>(
          create: (_) => TaskRepositoryImpl(), // Implementação concreta
        ),
        ChangeNotifierProxyProvider<TaskRepository, TaskService>(
          create: (context) => TaskService(context.read<TaskRepository>()),
          update: (context, taskRepo, previous) => 
              previous ?? TaskService(taskRepo),
        ),
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
          tabBarTheme: const TabBarThemeData(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 14,
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFFF59E0B), // Amber acento
            foregroundColor: Colors.white,
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
