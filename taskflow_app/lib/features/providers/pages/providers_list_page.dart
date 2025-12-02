import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../domain/entities/provider.dart';
import '../widgets/provider_form_dialog.dart';
import '../infrastructure/local/providers_local_dao.dart';
import '../infrastructure/remote/supabase_providers_remote_datasource.dart';
import '../infrastructure/repositories/providers_repository_impl.dart';
import '../../../services/core/supabase_service.dart';

/// Página de listagem de provedores
/// 
/// Implementa os Prompts 16, 17 e 18:
/// - Sincronização offline-first com Supabase
/// - Push-then-Pull sync automático
/// - Uso de Entity (domínio) ao invés de DTO na UI
/// - Indicador visual durante sincronização
/// 
/// Também implementa:
/// - Prompt 08: Listagem de provedores
/// - Prompt 09: Diálogo de ações (Editar/Remover/Fechar)
/// - Prompt 10: Edição via ícone de lápis
/// - Prompt 11: Remoção por swipe (Dismissible)
class ProvidersListPage extends StatefulWidget {
  const ProvidersListPage({super.key});

  @override
  State<ProvidersListPage> createState() => _ProvidersListPageState();
}

class _ProvidersListPageState extends State<ProvidersListPage> {
  late final ProvidersRepositoryImpl _repository;
  List<Provider> _providers = [];
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    
    // Inicializa repositório com padrão offline-first
    _repository = ProvidersRepositoryImpl(
      remoteApi: SupabaseProvidersRemoteDatasource(client: SupabaseService.client),
      localDao: ProvidersLocalDao(),
    );
    
    // Carrega dados e sincroniza (Prompt 18: two-way sync)
    _loadAndSync();
  }

  Future<void> _loadAndSync() async {
    if (!mounted) return;

    try {
      setState(() => _isSyncing = true);

      // 1. Carrega do cache primeiro (render rápido)
      await _repository.loadFromCache();
      final cachedProviders = await _repository.listAll();
      
      if (mounted) {
        setState(() => _providers = cachedProviders);
      }

      // 2. Sincroniza com servidor em background (Prompt 18)
      final syncedCount = await _repository.syncFromServer();

      // 3. Recarrega após sync
      final updatedProviders = await _repository.listAll();
      
      if (mounted) {
        setState(() => _providers = updatedProviders);
      }

      if (kDebugMode) {
        print('[ProvidersListPage] Sincronização concluída: $syncedCount items');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('[ProvidersListPage] Erro na sincronização: $e');
        print(stack);
      }
      
      // Em caso de erro, tenta carregar do cache
      if (mounted) {
        try {
          final cachedProviders = await _repository.listAll();
          setState(() => _providers = cachedProviders);
        } catch (_) {}
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<void> _addProvider(Provider provider) async {
    try {
      await _repository.createProvider(provider);
      await _loadAndSync();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Fornecedor adicionado com sucesso')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erro ao adicionar fornecedor: $e')),
        );
      }
    }
  }

  Future<void> _editProvider(Provider provider) async {
    try {
      await _repository.updateProvider(provider);
      await _loadAndSync();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Fornecedor atualizado com sucesso')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erro ao atualizar fornecedor: $e')),
        );
      }
    }
  }

  Future<void> _deleteProvider(Provider provider) async {
    try {
      await _repository.deleteProvider(provider.id);

      await _loadAndSync();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Fornecedor removido com sucesso')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erro ao remover fornecedor: $e')),
        );
      }
    }
  }

  void _showProviderActions(Provider provider) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prompt 09: não dismissable
      builder: (context) => AlertDialog(
        title: Text(provider.name),
        content: const Text('Escolha uma ação'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showEditDialog(provider);
            },
            child: const Text('Editar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _confirmDelete(provider);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remover'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Provider provider) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prompt 11: confirmação não dismissable
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Remoção'),
        content: Text('Deseja realmente remover ${provider.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteProvider(provider);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sim'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddDialog() async {
    await showProviderFormDialog(
      context: context,
      onSave: _addProvider,
    );
  }

  Future<void> _showEditDialog(Provider provider) async {
    await showProviderFormDialog(
      context: context,
      provider: provider,
      onSave: _editProvider,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fornecedores'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        bottom: _isSyncing
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: _loadAndSync,
        child: _providers.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.business_outlined,
                            size: 80,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhum fornecedor cadastrado',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Adicione seu primeiro fornecedor',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _providers.length,
                itemBuilder: (context, index) {
                  final provider = _providers[index];
                  
                  // Prompt 11: Dismissible para remoção por swipe
                  return Dismissible(
                    key: Key(provider.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          return await showDialog<bool>(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => AlertDialog(
                              title: const Text('Remover fornecedor?'),
                              content: Text('Deseja remover ${provider.name}?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Não'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('Sim'),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (direction) {
                          _deleteProvider(provider);
                        },
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                    child: Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: provider.isActive 
                              ? Colors.blue 
                              : Colors.grey,
                          child: Text(
                            provider.name.isNotEmpty 
                                ? provider.name[0].toUpperCase() 
                                : 'F',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(provider.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(provider.email),
                            if (provider.phone != null && provider.phone!.isNotEmpty)
                              Text(
                                provider.phone!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        // Prompt 10: Ícone de edição
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          tooltip: 'Editar fornecedor',
                          onPressed: () => _showEditDialog(provider),
                        ),
                        // Prompt 09: Tap para diálogo de ações
                        onTap: () => _showProviderActions(provider),
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Novo Fornecedor'),
      ),
    );
  }
}
