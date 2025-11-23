import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class PolicyViewerScreen extends StatefulWidget {
  final String policyType; // 'privacy' ou 'terms'
  final VoidCallback? onMarkAsRead;

  const PolicyViewerScreen({
    super.key,
    required this.policyType,
    this.onMarkAsRead,
  });

  @override
  State<PolicyViewerScreen> createState() => _PolicyViewerScreenState();
}

class _PolicyViewerScreenState extends State<PolicyViewerScreen> {
  final ScrollController _scrollController = ScrollController();
  String _content = '';
  bool _isLoading = true;
  double _scrollProgress = 0.0;
  bool _hasReachedEnd = false;
  bool _canMarkAsRead = false;

  @override
  void initState() {
    super.initState();
    _loadContent();
    _setupScrollListener();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    try {
      final fileName = widget.policyType == 'privacy' 
          ? 'assets/docs/privacy_policy.md'
          : 'assets/docs/terms_of_service.md';
      
      final content = await rootBundle.loadString(fileName);
      setState(() {
        _content = content;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _content = 'Erro ao carregar o documento.';
        _isLoading = false;
      });
    }
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      
      setState(() {
        _scrollProgress = maxScroll > 0 ? (currentScroll / maxScroll).clamp(0.0, 1.0) : 0.0;
      });

      if (_scrollProgress >= 0.95 && !_hasReachedEnd) {
        setState(() {
          _hasReachedEnd = true;
          _canMarkAsRead = true;
        });
      }
    });
  }

  void _markAsRead() {
    if (_canMarkAsRead && widget.onMarkAsRead != null) {
      widget.onMarkAsRead!();
      Navigator.of(context).pop(true);
    }
  }

  String get _title {
    return widget.policyType == 'privacy' 
        ? 'Política de Privacidade' 
        : 'Termos de Uso';
  }

  void _scrollUp() {
    final double newPosition = (_scrollController.offset - 300).clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      newPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollDown() {
    final double newPosition = (_scrollController.offset + 300).clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      newPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: Colors.grey.shade50,
                      child: Text(
                        _hasReachedEnd 
                            ? '✓ Leitura completa - Você pode marcar como lido'
                            : 'Progresso da leitura: ${(_scrollProgress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 14,
                          color: _hasReachedEnd ? Colors.green.shade700 : Colors.grey.shade600,
                          fontWeight: _hasReachedEnd ? FontWeight.w600 : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Markdown(
                        controller: _scrollController,
                        data: _content,
                        selectable: true,
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton(
                        onPressed: _canMarkAsRead ? _markAsRead : null,
                        child: Text(
                          _canMarkAsRead 
                              ? 'Marcar como Lido ✓' 
                              : 'Leia até o final para continuar',
                        ),
                      ),
                    ),
                  ],
                ),
                // Botão para subir (só aparece se não estiver no topo)
                if (_scrollProgress > 0.1)
                  Positioned(
                    right: 16,
                    top: 80,
                    child: FloatingActionButton.small(
                      heroTag: "scroll_up",
                      onPressed: _scrollUp,
                      backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.9),
                      foregroundColor: Colors.white,
                      child: const Icon(Icons.keyboard_arrow_up),
                    ),
                  ),
                // Botão para descer (só aparece se não estiver no final)
                if (!_hasReachedEnd)
                  Positioned(
                    right: 16,
                    bottom: 100,
                    child: FloatingActionButton.small(
                      heroTag: "scroll_down",
                      onPressed: _scrollDown,
                      backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.9),
                      foregroundColor: Colors.white,
                      child: const Icon(Icons.keyboard_arrow_down),
                    ),
                  ),
              ],
            ),
    );
  }
}
