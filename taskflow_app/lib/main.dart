import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Clean Architecture - Application Layer
import 'features/tasks/application/task_service.dart';
import 'features/categories/application/category_service.dart';
import 'features/reminders/application/reminder_service.dart';
// Clean Architecture - Infrastructure Layer
import 'services/core/task_filter_service.dart';
import 'services/notifications/notification_helper.dart';
import 'services/storage/preferences_service.dart';
import 'features/app/domain/repositories/task_repository.dart';
import 'features/app/infrastructure/repositories/task_repository_impl.dart';
import 'features/app/infrastructure/local/category_local_dto_shared_prefs.dart';
import 'features/splashscreen/pages/splash_screen.dart';
import 'features/onboarding/pages/onboarding_screen.dart';
import 'features/auth/pages/consent_screen.dart';
import 'features/app/presentation/main_navigation_scaffold.dart';
import 'features/settings/pages/settings_screen.dart';
import 'features/settings/pages/policy_viewer_screen.dart';
import 'features/categories/pages/category_management_page.dart';
import 'features/reminders/pages/reminder_list_page.dart';

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
  
  // Inicializa o NotificationHelper
  final notificationHelper = NotificationHelper();
  await notificationHelper.initialize();
  await notificationHelper.requestPermission();
  
  runApp(TaskFlowApp(
    preferencesService: preferencesService,
    notificationHelper: notificationHelper,
  ));
}

class TaskFlowApp extends StatelessWidget {
  final PreferencesService preferencesService;
  final NotificationHelper notificationHelper;
  
  const TaskFlowApp({
    super.key, 
    required this.preferencesService,
    required this.notificationHelper,
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
        // CategoryService com DAO local
        ChangeNotifierProvider<CategoryService>(
          create: (_) => CategoryService(CategoryLocalDtoSharedPrefs()),
        ),
        // TaskFilterService para filtros de tarefas
        ChangeNotifierProvider<TaskFilterService>(
          create: (_) => TaskFilterService(),
        ),
        // ReminderService com NotificationHelper já inicializado
        ChangeNotifierProvider<ReminderService>(
          create: (_) => ReminderService(notificationHelper),
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
          '/home': (context) => const MainNavigationScaffold(),
          '/settings': (context) => const SettingsScreen(),
          '/categories': (context) => const CategoryManagementPage(),
          '/reminders': (context) => const ReminderListPage(),
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
