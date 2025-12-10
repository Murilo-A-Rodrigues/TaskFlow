import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Clean Architecture - Application Layer
import 'features/tasks/application/task_service.dart';
import 'features/tasks/application/task_filter_service.dart';
import 'features/categories/application/category_service.dart';
import 'features/reminders/application/reminder_service.dart';
// Clean Architecture - Infrastructure Layer
import 'services/notifications/notification_helper.dart';
import 'services/storage/preferences_service.dart';
import 'services/core/supabase_service.dart';
import 'services/core/config_service.dart';
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
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carrega variáveis de ambiente (.env)
  await ConfigService.initialize();

  // Inicializa o SupabaseService
  await SupabaseService.initialize();

  // Inicializa o serviço de preferências
  final preferencesService = PreferencesService();
  await preferencesService.init();

  // Inicializa o NotificationHelper
  final notificationHelper = NotificationHelper();
  await notificationHelper.initialize();
  await notificationHelper.requestPermission();

  runApp(
    TaskFlowApp(
      preferencesService: preferencesService,
      notificationHelper: notificationHelper,
    ),
  );
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
        // ThemeController para gerenciar o tema
        ChangeNotifierProvider<ThemeController>(
          create: (context) => ThemeController(preferencesService),
        ),
        // TaskService com Repository atualizado
        ChangeNotifierProvider<TaskService>(
          create: (_) => TaskService(TaskRepositoryImpl()),
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
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) {
          // Carregar tema na primeira construção
          if (!themeController.isInitialized) {
            // Carregar de forma assíncrona mas não bloquear a UI
            WidgetsBinding.instance.addPostFrameCallback((_) {
              themeController.loadTheme();
            });
          }

          return MaterialApp(
            title: 'TaskFlow',
            themeMode: themeController.mode,
            theme: ThemeData(
              colorScheme:
                  ColorScheme.fromSeed(
                    seedColor: const Color(
                      0xFF4F46E5,
                    ), // Indigo primário do PRD
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
                headlineSmall: TextStyle(fontWeight: FontWeight.w600),
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
            darkTheme: ThemeData(
              colorScheme:
                  ColorScheme.fromSeed(
                    seedColor: const Color(0xFF4F46E5),
                    brightness: Brightness.dark,
                  ).copyWith(
                    primary: const Color(
                      0xFFFBBF24,
                    ), // AMBER vibrante para destaque
                    primaryContainer: const Color(
                      0xFFF59E0B,
                    ), // Amber mais escuro
                    onPrimary: const Color(0xFF000000), // Texto preto no amber
                    secondary: const Color(0xFF94A3B8), // Gray mais claro
                    tertiary: const Color(0xFF6366F1), // Indigo para acentos
                    surface: const Color(0xFF1E293B), // Surface escuro
                    surfaceContainerHighest: const Color(
                      0xFF334155,
                    ), // Diálogos e cards
                    onSurface: const Color(
                      0xFFF1F5F9,
                    ), // Texto claro com melhor contraste
                    onSurfaceVariant: const Color(
                      0xFFCBD5E1,
                    ), // Texto secundário
                    outline: const Color(0xFF475569), // Bordas sutis
                  ),
              useMaterial3: true,
              dialogTheme: const DialogThemeData(
                backgroundColor: Color(
                  0xFF334155,
                ), // Fundo dos diálogos mais claro
                surfaceTintColor: Colors.transparent,
              ),
              cardTheme: const CardThemeData(
                color: Color(0xFF334155), // Cards mais claros
                surfaceTintColor: Colors.transparent,
              ),
              timePickerTheme: TimePickerThemeData(
                backgroundColor: const Color(0xFF334155),
                hourMinuteColor: const Color(
                  0xFFFBBF24,
                ), // Amber para números selecionados (substitui azul)
                hourMinuteTextColor: const Color(
                  0xFF000000,
                ), // Texto preto no amber para contraste
                dialHandColor: const Color(
                  0xFFFBBF24,
                ), // Ponteiro amber (substitui azul)
                dialBackgroundColor: const Color(0xFF1E293B),
                dialTextColor: Colors
                    .white, // Números do relógio BRANCOS (não selecionados)
                dayPeriodColor: const Color(0xFFFBBF24), // AM/PM amber
                dayPeriodTextColor: const Color(0xFF000000),
                helpTextStyle: const TextStyle(color: Colors.white),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(
                    0xFFFBBF24,
                  ), // Botões de texto em amber
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFFFBBF24,
                  ), // Botões elevados em amber
                  foregroundColor: const Color(0xFF000000), // Texto preto
                ),
              ),

              inputDecorationTheme: InputDecorationTheme(
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Color(0xFFFBBF24),
                    width: 2,
                  ), // Borda amber ao focar
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Color(0xFF475569),
                  ), // Borda cinza normal
                  borderRadius: BorderRadius.circular(12),
                ),
                labelStyle: const TextStyle(
                  color: Color(0xFFCBD5E1),
                ), // Labels em cinza claro
                hintStyle: const TextStyle(
                  color: Color(0xFF94A3B8),
                ), // Hints em cinza médio
                prefixIconColor: const Color(
                  0xFFFBBF24,
                ), // Ícones dos campos em amber
                suffixIconColor: const Color(0xFFFBBF24),
              ),
              textTheme: const TextTheme(
                headlineSmall: TextStyle(fontWeight: FontWeight.w600),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF1E293B),
                foregroundColor: Colors.white,
                elevation: 2,
                iconTheme: IconThemeData(
                  color: Colors.white,
                ), // Ícones brancos (menu, etc)
                actionsIconTheme: IconThemeData(
                  color: Colors.white,
                ), // Avatar e ações brancos
              ),
              tabBarTheme: const TabBarThemeData(
                labelColor: Color(
                  0xFFFBBF24,
                ), // Abas selecionadas em amber (substitui azul)
                unselectedLabelColor:
                    Colors.white70, // Abas não selecionadas brancas
                indicatorColor: Color(
                  0xFFFBBF24,
                ), // Indicador amber (substitui azul)
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
                backgroundColor: Color(
                  0xFFFBBF24,
                ), // Amber vibrante (substitui azul)
                foregroundColor: Color(
                  0xFF000000,
                ), // Ícone preto para contraste
              ),
              bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                backgroundColor: Color(0xFF1E293B),
                selectedItemColor: Color(
                  0xFFFBBF24,
                ), // Item selecionado em amber (substitui azul)
                unselectedItemColor:
                    Colors.white70, // Itens não selecionados brancos
                selectedIconTheme: IconThemeData(color: Color(0xFFFBBF24)),
                unselectedIconTheme: IconThemeData(color: Colors.white70),
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
                  builder: (context) =>
                      PolicyViewerScreen(policyType: policyType),
                  settings: settings,
                );
              }
              return null;
            },
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
