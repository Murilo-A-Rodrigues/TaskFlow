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
  bool _canScrollUp = false;
  bool _canScrollDown = false;

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
        _scrollProgress = maxScroll > 0
            ? (currentScroll / maxScroll).clamp(0.0, 1.0)
            : 0.0;
        _canScrollUp = currentScroll > 50; // Pode subir se desceu mais de 50px
        _canScrollDown =
            currentScroll <
            (maxScroll - 50); // Pode descer se não está quase no fim
      });

      // Considera que chegou ao fim quando scroll >= 95%
      if (_scrollProgress >= 0.95 && !_hasReachedEnd) {
        setState(() {
          _hasReachedEnd = true;
          _canMarkAsRead = true;
        });
      }
    });
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _markAsRead() {
    if (_canMarkAsRead && widget.onMarkAsRead != null) {
      widget.onMarkAsRead!();
      Navigator.of(context).pop(true); // Retorna true indicando que foi lido
    }
  }

  String get _title {
    return widget.policyType == 'privacy'
        ? 'Política de Privacidade'
        : 'Termos de Uso';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        elevation: 0,
        // Barra de progresso customizada no AppBar
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(
            height: 4.0,
            decoration: BoxDecoration(color: Colors.grey.shade300),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _scrollProgress,
              child: Container(
                decoration: BoxDecoration(
                  color: _hasReachedEnd
                      ? Colors.green
                      : Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Column(
                  children: [
                    // Indicador de progresso textual
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: Colors.grey.shade50,
                      child: Text(
                        _hasReachedEnd
                            ? '✓ Leitura completa - Você pode marcar como lido'
                            : 'Progresso da leitura: ${(_scrollProgress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 14,
                          color: _hasReachedEnd
                              ? Colors.green.shade700
                              : Colors.grey.shade600,
                          fontWeight: _hasReachedEnd
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    // Conteúdo do documento
                    Expanded(
                      child: Markdown(
                        controller: _scrollController,
                        data: _content,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet(
                          h1: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          h2: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          h3: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          p: const TextStyle(fontSize: 16, height: 1.6),
                          listBullet: TextStyle(
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),

                    // Botão "Marcar como lido"
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _canMarkAsRead ? _markAsRead : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: _canMarkAsRead
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade300,
                        ),
                        child: Text(
                          _canMarkAsRead
                              ? 'Marcar como Lido ✓'
                              : 'Leia até o final para continuar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _canMarkAsRead
                                ? Colors.white
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Seta para subir (canto superior direito)
                if (_canScrollUp)
                  Positioned(
                    top: 80,
                    right: 16,
                    child: FloatingActionButton.small(
                      onPressed: _scrollToTop,
                      backgroundColor: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.9),
                      foregroundColor: Colors.white,
                      child: const Icon(Icons.keyboard_arrow_up, size: 24),
                    ),
                  ),

                // Seta para descer (canto inferior direito)
                if (_canScrollDown)
                  Positioned(
                    bottom: 100,
                    right: 16,
                    child: FloatingActionButton.small(
                      onPressed: _scrollToBottom,
                      backgroundColor: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.9),
                      foregroundColor: Colors.white,
                      child: const Icon(Icons.keyboard_arrow_down, size: 24),
                    ),
                  ),
              ],
            ),
    );
  }
}
