import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../infrastructure/local/providers_local_dao_shared.dart';
import '../infrastructure/dtos/provider_dto.dart';

/// Diálogo de formulário para criar/editar fornecedores
/// Implementa padrão do Prompt 10 (edição)
Future<bool?> showProviderFormDialog({
  required BuildContext context,
  required ProvidersLocalDaoShared dao,
  ProviderDto? provider,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false, // Conforme especificação dos prompts
    builder: (context) => _ProviderFormDialog(
      dao: dao,
      provider: provider,
    ),
  );
}

class _ProviderFormDialog extends StatefulWidget {
  final ProvidersLocalDaoShared dao;
  final ProviderDto? provider;

  const _ProviderFormDialog({
    required this.dao,
    this.provider,
  });

  @override
  State<_ProviderFormDialog> createState() => _ProviderFormDialogState();
}

class _ProviderFormDialogState extends State<_ProviderFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late bool _isActive;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.provider?.name ?? '');
    _emailController = TextEditingController(text: widget.provider?.email ?? '');
    _phoneController = TextEditingController(text: widget.provider?.phone ?? '');
    _addressController = TextEditingController(text: widget.provider?.address ?? '');
    _isActive = widget.provider?.is_active ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.provider != null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Carrega lista atual
      final providers = await widget.dao.getSharedProviders();

      final newProvider = ProviderDto(
        id: widget.provider?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty 
            ? null 
            : _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty 
            ? null 
            : _addressController.text.trim(),
        is_active: _isActive,
        created_at: widget.provider?.created_at ?? DateTime.now(),
        updated_at: DateTime.now(),
      );

      if (_isEditing) {
        // Atualiza existente
        final index = providers.indexWhere((p) => p.id == newProvider.id);
        if (index != -1) {
          providers[index] = newProvider;
        }
      } else {
        // Adiciona novo
        providers.add(newProvider);
      }

      await widget.dao.saveSharedProviders(providers);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing 
                  ? '✅ Fornecedor atualizado com sucesso' 
                  : '✅ Fornecedor cadastrado com sucesso',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erro ao salvar fornecedor: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Editar Fornecedor' : 'Novo Fornecedor'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nome é obrigatório';
                  }
                  if (value.trim().length < 3) {
                    return 'Nome deve ter no mínimo 3 caracteres';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-mail *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'E-mail é obrigatório';
                  }
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value.trim())) {
                    return 'E-mail inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefone',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                  hintText: '(00) 00000-0000',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Endereço',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Fornecedor Ativo'),
                subtitle: Text(_isActive ? 'Ativo' : 'Inativo'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEditing ? 'Atualizar' : 'Salvar'),
        ),
      ],
    );
  }
}
