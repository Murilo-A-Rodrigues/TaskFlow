import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/core/supabase_service.dart';
import '../../../services/user/user_profile_service.dart';

/// AuthService - Gerencia autenticação e sessão do usuário
class AuthService extends ChangeNotifier {
  static const String _guestModeKey = 'is_guest_mode';
  static const String _hasLoggedInKey = 'has_logged_in';

  UserProfileService? _profileService;

  bool _isAuthenticated = false;
  bool _isGuest = false;
  String? _userId;
  String? _userEmail;

  bool get isAuthenticated => _isAuthenticated;
  bool get isGuest => _isGuest;
  String? get userId => _userId;
  String? get userEmail => _userEmail;

  /// Define o serviço de perfil (injetado do Provider)
  void setProfileService(UserProfileService service) {
    _profileService = service;
  }

  /// Inicializa o serviço verificando sessão existente
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Verifica se está em modo convidado
      _isGuest = prefs.getBool(_guestModeKey) ?? false;
      
      if (_isGuest) {
        _isAuthenticated = true;
        _userId = '00000000-0000-0000-0000-000000000000';
        _userEmail = null;
        if (kDebugMode) print('✅ AuthService: Modo convidado ativo');
        
        // Inicializa perfil em modo convidado
        await _profileService?.initialize(_userId!, isGuest: true);
        
        notifyListeners();
        return;
      }

      // Verifica sessão do Supabase
      final currentUser = SupabaseService.client.auth.currentUser;
      if (currentUser != null) {
        _isAuthenticated = true;
        _userId = currentUser.id;
        _userEmail = currentUser.email;
        
        // Cria/atualiza registro na tabela users
        await _ensureUserInDatabase();
        
        // Inicializa perfil do usuário
        await _profileService?.initialize(_userId!, isGuest: false);
        
        if (kDebugMode) {
          print('✅ AuthService: Sessão restaurada - ${currentUser.email}');
        }
        notifyListeners();
      } else {
        if (kDebugMode) print('⚠️ AuthService: Nenhuma sessão ativa');
      }
    } catch (e) {
      if (kDebugMode) print('❌ AuthService: Erro ao inicializar - $e');
    }
  }

  /// Login com email e senha
  Future<String?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await SupabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _isAuthenticated = true;
        _isGuest = false;
        _userId = response.user!.id;
        _userEmail = response.user!.email;

        // Salva que não é modo convidado
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_guestModeKey, false);
        await prefs.setBool(_hasLoggedInKey, true);

        // Cria/atualiza registro na tabela users
        await _ensureUserInDatabase();

        // Inicializa perfil do usuário
        await _profileService?.initialize(_userId!, isGuest: false);

        notifyListeners();
        if (kDebugMode) print('✅ Login bem-sucedido: $email');
        return null;
      }

      return 'Erro ao fazer login';
    } catch (e) {
      if (kDebugMode) print('❌ Erro no login: $e');
      return _getErrorMessage(e);
    }
  }

  /// Registro com email e senha
  Future<String?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      if (kDebugMode) print('🔐 Tentando registrar: $email');
      
      final response = await SupabaseService.client.auth.signUp(
        email: email,
        password: password,
      );

      if (kDebugMode) {
        print('📋 Resposta do signUp:');
        print('   user: ${response.user?.id}');
        print('   session: ${response.session?.accessToken != null}');
      }

      if (response.user != null) {
        _isAuthenticated = true;
        _isGuest = false;
        _userId = response.user!.id;
        _userEmail = response.user!.email;

        // Salva que não é modo convidado
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_guestModeKey, false);
        await prefs.setBool(_hasLoggedInKey, true);

        // Cria registro na tabela users
        await _ensureUserInDatabase();

        // Inicializa perfil do usuário
        await _profileService?.initialize(_userId!, isGuest: false);

        notifyListeners();
        if (kDebugMode) print('✅ Registro bem-sucedido: $email');
        return null;
      }

      return 'Erro ao criar conta';
    } catch (e) {
      if (kDebugMode) print('❌ Erro no registro: $e');
      return _getErrorMessage(e);
    }
  }

  /// Entrar como convidado (apenas armazenamento local)
  Future<String?> signInAsGuest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_guestModeKey, true);
      await prefs.setBool(_hasLoggedInKey, true);

      _isAuthenticated = true;
      _isGuest = true;
      _userId = '00000000-0000-0000-0000-000000000000';
      _userEmail = null;

      // Inicializa perfil em modo convidado
      await _profileService?.initialize(_userId!, isGuest: true);

      notifyListeners();
      if (kDebugMode) print('✅ Modo convidado ativado');
      return null;
    } catch (e) {
      if (kDebugMode) print('❌ Erro ao entrar como convidado: $e');
      return 'Erro ao entrar como convidado';
    }
  }

  /// Logout
  Future<void> signOut() async {
    try {
      // Limpa perfil antes do logout
      await _profileService?.clearProfile();
      
      if (!_isGuest) {
        await SupabaseService.client.auth.signOut();
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_guestModeKey);

      _isAuthenticated = false;
      _isGuest = false;
      _userId = null;
      _userEmail = null;

      notifyListeners();
      if (kDebugMode) print('✅ Logout realizado');
    } catch (e) {
      if (kDebugMode) print('❌ Erro no logout: $e');
    }
  }

  /// Garante que o usuário existe na tabela public.users
  Future<void> _ensureUserInDatabase() async {
    if (_userId == null || _isGuest) {
      if (kDebugMode) print('⏭️ Pulando criação de usuário (guest ou userId null)');
      return;
    }

    try {
      if (kDebugMode) {
        print('🔄 Verificando usuário na tabela public.users...');
        print('   id: $_userId');
        print('   email: $_userEmail');
      }

      // Primeiro verifica se o usuário já existe
      final existingUser = await SupabaseService.client
          .from('users')
          .select('id, name, avatar_url')
          .eq('id', _userId!)
          .maybeSingle();

      if (existingUser != null) {
        // Usuário já existe - não sobrescreve os dados
        if (kDebugMode) {
          print('✅ Usuário já existe no banco:');
          print('   Nome: ${existingUser['name']}');
          print('   Avatar: ${existingUser['avatar_url']}');
        }
        return;
      }

      // Usuário não existe - cria novo registro
      if (kDebugMode) print('📝 Criando novo usuário na tabela...');
      
      final response = await SupabaseService.client
          .from('users')
          .insert({
            'id': _userId,
            'name': _userEmail?.split('@')[0] ?? 'User',
            'email': _userEmail ?? 'unknown@taskflow.app',
            'is_active': true,
          })
          .select();
      
      if (kDebugMode) {
        print('✅ Novo usuário criado na tabela users');
        print('   Resposta: $response');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Erro ao criar usuário na tabela users: $e');
        print('   Tipo do erro: ${e.runtimeType}');
      }
    }
  }

  /// Converte erros do Supabase em mensagens amigáveis
  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    
    if (kDebugMode) print('🔍 Erro capturado: $errorStr');
    
    if (errorStr.contains('invalid login credentials') || 
        errorStr.contains('invalid_credentials')) {
      return 'Email ou senha incorretos';
    }
    if (errorStr.contains('user already registered') || 
        errorStr.contains('email already') ||
        errorStr.contains('already registered')) {
      return 'Este email já está registrado';
    }
    if (errorStr.contains('weak password') || 
        errorStr.contains('password is too short')) {
      return 'Senha muito fraca. Use no mínimo 6 caracteres';
    }
    if (errorStr.contains('invalid email') || 
        errorStr.contains('invalid_email')) {
      return 'Email inválido';
    }
    if (errorStr.contains('network') || 
        errorStr.contains('connection') ||
        errorStr.contains('timeout')) {
      return 'Erro de conexão. Verifique sua internet';
    }
    if (errorStr.contains('user not found')) {
      return 'Usuário não encontrado';
    }
    if (errorStr.contains('too many requests')) {
      return 'Muitas tentativas. Aguarde alguns minutos';
    }
    
    // Retorna mensagem genérica com o erro original em debug
    if (kDebugMode) print('❌ Erro não mapeado: $error');
    return 'Erro ao autenticar. Tente novamente';
  }

  /// Verifica se já fez login antes (para pular onboarding)
  static Future<bool> hasLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasLoggedInKey) ?? false;
  }
}
