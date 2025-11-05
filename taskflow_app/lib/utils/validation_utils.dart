/// Utilitários para validação de dados
class ValidationUtils {
  /// Valida se o título da task é válido
  static String? validateTaskTitle(String? title) {
    if (title == null || title.trim().isEmpty) {
      return 'Título não pode estar vazio';
    }
    
    if (title.trim().length < 3) {
      return 'Título deve ter pelo menos 3 caracteres';
    }
    
    if (title.trim().length > 100) {
      return 'Título deve ter no máximo 100 caracteres';
    }
    
    return null;
  }
  
  /// Valida se a descrição da task é válida
  static String? validateTaskDescription(String? description) {
    if (description != null && description.trim().length > 500) {
      return 'Descrição deve ter no máximo 500 caracteres';
    }
    
    return null;
  }
  
  /// Valida se um email é válido (se implementar futuramente)
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }
  
  /// Valida se uma URL é válida (para futuras funcionalidades)
  static bool isValidUrl(String url) {
    try {
      Uri.parse(url);
      return true;
    } catch (e) {
      return false;
    }
  }
}