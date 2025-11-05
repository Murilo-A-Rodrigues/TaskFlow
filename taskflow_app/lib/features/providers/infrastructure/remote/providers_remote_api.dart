import 'package:supabase_flutter/supabase_flutter.dart';
import '../dtos/provider_dto.dart';

/// API remota para comunicação com Supabase - Provedores
class ProvidersRemoteApi {
  static const String _tableName = 'providers';
  final SupabaseClient _supabase = Supabase.instance.client;
  
  Future<List<ProviderDto>> getAllProviders() async {
    final response = await _supabase
        .from(_tableName)
        .select()
        .order('created_at', ascending: false);
    
    return (response as List)
        .map((json) => ProviderDto.fromMap(json))
        .toList();
  }
  
  Future<List<ProviderDto>> getActiveProviders() async {
    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('is_active', true)
        .order('name', ascending: true);
    
    return (response as List)
        .map((json) => ProviderDto.fromMap(json))
        .toList();
  }
  
  Future<ProviderDto> createProvider(ProviderDto dto) async {
    final response = await _supabase
        .from(_tableName)
        .insert(dto.toMap())
        .select()
        .single();
    
    return ProviderDto.fromMap(response);
  }
  
  Future<ProviderDto> updateProvider(ProviderDto dto) async {
    final response = await _supabase
        .from(_tableName)
        .update(dto.toMap())
        .eq('id', dto.id!)
        .select()
        .single();
    
    return ProviderDto.fromMap(response);
  }
  
  Future<void> deleteProvider(String providerId) async {
    await _supabase
        .from(_tableName)
        .delete()
        .eq('id', providerId);
  }
  
  Future<ProviderDto?> getProviderById(String providerId) async {
    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('id', providerId)
        .maybeSingle();
    
    if (response != null) {
      return ProviderDto.fromMap(response);
    }
    
    return null;
  }
}