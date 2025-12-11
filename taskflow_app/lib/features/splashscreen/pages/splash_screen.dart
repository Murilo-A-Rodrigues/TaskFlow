import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/storage/preferences_service.dart';
import '../../../shared/widgets/taskflow_icon.dart';
import '../../auth/application/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _navigateToNextScreen();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _controller.forward();
  }

  Future<void> _navigateToNextScreen() async {
    // Aguarda pelo menos 2.5 segundos para mostrar o splash
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    final prefsService = context.read<PreferencesService>();
    final authService = context.read<AuthService>();

    // Debug: mostra o estado atual das preferências
    print('🔍 SplashScreen - Debug de navegação:');
    print('   isFirstTimeUser: ${prefsService.isFirstTimeUser}');
    print('   isOnboardingCompleted: ${prefsService.isOnboardingCompleted}');
    print('   hasValidConsent: ${prefsService.hasValidConsent}');
    print('   isAuthenticated: ${authService.isAuthenticated}');
    print('   isGuest: ${authService.isGuest}');
    
    prefsService.debugPrintState();

    // Fluxo: Onboarding → Termos → Login → Home
    String nextRoute;

    // 1. Verifica se precisa ver onboarding (primeira vez)
    if (prefsService.isFirstTimeUser || !prefsService.isOnboardingCompleted) {
      nextRoute = '/onboarding';
      print('➡️ SplashScreen - Indo para: $nextRoute (onboarding necessário)');
    }
    // 2. Verifica se precisa aceitar termos
    else if (!prefsService.hasValidConsent ||
        prefsService.policiesVersionAccepted !=
            PreferencesService.currentPolicyVersion) {
      nextRoute = '/consent';
      print('➡️ SplashScreen - Indo para: $nextRoute (termos necessários)');
    }
    // 3. Verifica se está autenticado
    else if (!authService.isAuthenticated) {
      nextRoute = '/login';
      print('➡️ SplashScreen - Indo para: $nextRoute (não autenticado)');
    }
    // 4. Tudo ok, vai para home
    else {
      nextRoute = '/home';
      print('➡️ SplashScreen - Indo para: $nextRoute (tudo completo)');
    }

    Navigator.of(context).pushReplacementNamed(nextRoute);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo/Ícone do app
                    Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(60),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: const TaskFlowIcon(size: 220),
                    ),
                    const SizedBox(height: 24),

                    // Nome do app
                    const Text(
                      'TaskFlow',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Slogan
                    Text(
                      'Organize sua vida com simplicidade',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w300,
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Loading indicator
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
