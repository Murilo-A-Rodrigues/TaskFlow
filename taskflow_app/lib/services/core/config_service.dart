import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Serviço para gerenciar configurações do app através de variáveis de ambiente
class ConfigService {
  static bool _isInitialized = false;

  /// Inicializa as variáveis de ambiente
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await dotenv.load(fileName: '.env');
      _isInitialized = true;
      print('✅ ConfigService - Variáveis de ambiente carregadas');
    } catch (e) {
      print('⚠️ ConfigService - Erro ao carregar .env: $e');
      print('📝 ConfigService - Usando valores padrão');
    }
  }

  /// Supabase URL
  static String get supabaseUrl {
    return dotenv.env['SUPABASE_URL'] ?? '';
  }

  /// Supabase Anon Key (chave pública)
  static String get supabaseAnonKey {
    return dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  }

  /// Nome do app
  static String get appName {
    return dotenv.env['APP_NAME'] ?? 'TaskFlow';
  }

  /// Versão do app
  static String get appVersion {
    return dotenv.env['APP_VERSION'] ?? '1.0.0';
  }

  /// Ambiente atual (development/production)
  static String get environment {
    return dotenv.env['ENVIRONMENT'] ?? 'development';
  }

  /// Se está em modo debug
  static bool get isDebugMode {
    return dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true';
  }

  /// Se o logging está habilitado
  static bool get isLoggingEnabled {
    return dotenv.env['ENABLE_LOGGING']?.toLowerCase() == 'true';
  }

  /// Verifica se as configurações do Supabase estão válidas
  static bool get hasValidSupabaseConfig {
    return supabaseUrl.isNotEmpty && 
           supabaseAnonKey.isNotEmpty &&
           supabaseUrl.startsWith('https://') &&
           supabaseUrl.contains('.supabase.co');
  }

  /// Retorna informações de debug da configuração
  static Map<String, dynamic> getDebugInfo() {
    return {
      'isInitialized': _isInitialized,
      'appName': appName,
      'appVersion': appVersion,
      'environment': environment,
      'isDebugMode': isDebugMode,
      'isLoggingEnabled': isLoggingEnabled,
      'hasSupabaseUrl': supabaseUrl.isNotEmpty,
      'hasSupabaseKey': supabaseAnonKey.isNotEmpty,
      'hasValidSupabaseConfig': hasValidSupabaseConfig,
      'supabaseUrlPrefix': supabaseUrl.isNotEmpty 
          ? '${supabaseUrl.substring(0, 20)}...' 
          : 'não configurado',
    };
  }

  /// Método para validar configuração na inicialização
  static void validateConfiguration() {
    print('🔧 ConfigService - Validando configurações...');
    
    final debugInfo = getDebugInfo();
    debugInfo.forEach((key, value) {
      print('   $key: $value');
    });

    if (!hasValidSupabaseConfig) {
      print('⚠️ ConfigService - ATENÇÃO: Configuração do Supabase inválida!');
      print('   Por favor, configure SUPABASE_URL e SUPABASE_ANON_KEY no arquivo .env');
    } else {
      print('✅ ConfigService - Configurações válidas!');
    }
  }
}