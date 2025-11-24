import 'package:flutter/material.dart';
import '../infrastructure/local/providers_local_dao_shared.dart';
import '../infrastructure/dtos/provider_dto.dart';
import '../widgets/provider_form_dialog.dart';

/// Página de listagem de provedores
/// Implementa o padrão especificado nos Prompts 08-11:
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
  final ProvidersLocalDaoShared _dao = ProvidersLocalDaoShared();
  List<ProviderDto> _providers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final providers = await _dao.getSharedProviders();
      setState(() {
        _providers = providers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erro ao carregar fornecedores: $e')),
        );
      }
    }
  }

  Future<void> _addProvider() async {
    final result = await showProviderFormDialog(
      context: context,
      dao: _dao,
    );

    if (result == true) {
      await _loadProviders();
    }
  }

  Future<void> _editProvider(ProviderDto provider) async {
    final result = await showProviderFormDialog(
      context: context,
      dao: _dao,
      provider: provider,
    );

    if (result == true) {
      await _loadProviders();
    }
  }

  Future<void> _deleteProvider(ProviderDto provider) async {
    try {
      // Remove da lista
      final updatedProviders = _providers.where((p) => p.id != provider.id).toList();
      await _dao.saveSharedProviders(updatedProviders);
      
      setState(() {
        _providers = updatedProviders;
      });

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

  void _showProviderActions(ProviderDto provider) {
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
              _editProvider(provider);
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

  void _confirmDelete(ProviderDto provider) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fornecedores'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProviders,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _providers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.business_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum fornecedor cadastrado ainda.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _addProvider,
                        icon: const Icon(Icons.add),
                        label: const Text('Adicionar Fornecedor'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProviders,
                  child: ListView.builder(
                    itemCount: _providers.length,
                    itemBuilder: (context, index) {
                      final provider = _providers[index];
                      
                      // Prompt 11: Dismissible para remoção por swipe
                      return Dismissible(
                        key: Key(provider.id ?? provider.email),
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
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: provider.is_active 
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
                              if (provider.phone != null)
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
                            onPressed: () => _editProvider(provider),
                          ),
                          // Prompt 09: Tap para diálogo de ações
                          onTap: () => _showProviderActions(provider),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addProvider,
        tooltip: 'Adicionar Fornecedor',
        child: const Icon(Icons.add),
      ),
    );
  }
}
