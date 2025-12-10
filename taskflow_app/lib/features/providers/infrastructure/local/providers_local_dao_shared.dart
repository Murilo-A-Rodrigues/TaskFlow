import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../dtos/provider_dto.dart';

/// DAO compartilhado para provedores
class ProvidersLocalDaoShared {
  static const String _sharedCacheKey = 'shared_providers_cache';
  static const String _syncKey = 'providers_last_sync';

  Future<List<ProviderDto>> getSharedProviders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_sharedCacheKey);

      if (jsonString == null) return [];

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => ProviderDto.fromMap(json)).toList();
    } catch (e) {
      print('❌ Erro ao carregar cache compartilhado de providers: $e');
      return [];
    }
  }

  Future<void> saveSharedProviders(List<ProviderDto> providers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = providers.map((provider) => provider.toMap()).toList();
      await prefs.setString(_sharedCacheKey, json.encode(jsonList));
      await _updateLastSync();
      print(
        '✅ Cache compartilhado de providers salvo: ${providers.length} provedores',
      );
    } catch (e) {
      print('❌ Erro ao salvar cache compartilhado de providers: $e');
    }
  }

  Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncTime = prefs.getString(_syncKey);
      return syncTime != null ? DateTime.parse(syncTime) : null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _updateLastSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_syncKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('❌ Erro ao atualizar timestamp de sync dos providers: $e');
    }
  }
}
