import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../dtos/provider_dto.dart';

/// DAO local para cache de provedores
class ProvidersLocalDao {
  static const String _cacheKey = 'providers_cache';
  
  Future<List<ProviderDto>> getCachedProviders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheKey);
      
      if (jsonString == null) return [];
      
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => ProviderDto.fromMap(json)).toList();
    } catch (e) {
      print('❌ Erro ao carregar cache de providers: $e');
      return [];
    }
  }
  
  Future<void> saveCachedProviders(List<ProviderDto> providers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = providers.map((provider) => provider.toMap()).toList();
      await prefs.setString(_cacheKey, json.encode(jsonList));
      print('✅ Cache de providers salvo: ${providers.length} provedores');
    } catch (e) {
      print('❌ Erro ao salvar cache de providers: $e');
    }
  }
  
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    print('🗑️ Cache de providers limpo');
  }
}
