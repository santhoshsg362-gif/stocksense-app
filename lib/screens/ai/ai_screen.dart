import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../config/app_theme.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  ApiService get _api {
    final token = context.read<AuthProvider>().token;
    return ApiService(token: token);
  }

  void _scrollToBottom() {
    Future.delayed(
      const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(
            milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(
      String text,
      String type, {
      String? symbol,
    }) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(
        text: text,
        isUser: true,
      ));
      _isLoading = true;
      _messageCtrl.clear();
    });

    _scrollToBottom();

    try {
      Map<String, dynamic> response;

      if (type == 'STOCK_ANALYSIS' &&
          symbol != null) {
        response = await _api.analyseStock(
          symbol, text);
      } else if (type == 'PORTFOLIO_ANALYSIS') {
        response = await _api.analysePortfolio(text);
      } else {
        response = await _api.askGeneral(text);
      }

      setState(() {
        _messages.add(_ChatMessage(
          text: response['analysis'] ??
            'No response received',
          isUser: false,
          disclaimer: response['disclaimer'],
        ));
        _isLoading = false;
      });

      _scrollToBottom();

    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(
          text: 'Sorry, AI service is unavailable. '
            'Please check your connection and try again.',
          isUser: false,
          isError: true,
        ));
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius:
                  BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.psychology,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment:
                CrossAxisAlignment.start,
              children: [
                Text(
                  'StockSense AI',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  'Powered by Groq LLaMA 3.3',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => setState(
              () => _messages.clear()),
            tooltip: 'Clear chat',
          ),
        ],
      ),
      body: Column(
        children: [

          // ── Chat area ──────────────────────────
          Expanded(
            child: _messages.isEmpty
              ? _buildWelcome()
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length +
                    (_isLoading ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == _messages.length) {
                      return _buildTypingIndicator();
                    }
                    return _buildMessage(
                      _messages[i]);
                  },
                ),
          ),

          // ── Quick actions ──────────────────────
          if (_messages.isEmpty)
            _buildQuickActions(),

          // ── Input area ─────────────────────────
          _buildInputArea(),
        ],
      ),
    );
  }

  // ── Welcome Screen ───────────────────────────────
  Widget _buildWelcome() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue
                  .withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.psychology,
                size: 44,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'StockSense AI',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask me anything about stocks, '
              'your portfolio, or investing concepts.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Quick Actions ────────────────────────────────
  Widget _buildQuickActions() {
    final actions = [
      (
        'Analyse my portfolio',
        Icons.pie_chart_outline,
        'PORTFOLIO_ANALYSIS',
        null,
      ),
      (
        'What is P/E ratio?',
        Icons.help_outline,
        'GENERAL',
        null,
      ),
      (
        'Analyse RELIANCE',
        Icons.candlestick_chart,
        'STOCK_ANALYSIS',
        'RELIANCE',
      ),
      (
        'Explain RSI indicator',
        Icons.show_chart,
        'GENERAL',
        null,
      ),
    ];

    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: 16),
        itemCount: actions.length,
        separatorBuilder: (_, __) =>
          const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final action = actions[i];
          return ActionChip(
            avatar: Icon(
              action.$2,
              size: 16,
              color: AppTheme.primaryBlue,
            ),
            label: Text(
              action.$1,
              style: const TextStyle(fontSize: 12),
            ),
            onPressed: () => _sendMessage(
              action.$1,
              action.$3,
              symbol: action.$4,
            ),
          );
        },
      ),
    );
  }

  // ── Message Bubble ───────────────────────────────
  Widget _buildMessage(_ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.psychology,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: message.isUser
                      ? AppTheme.primaryBlue
                      : message.isError
                        ? AppTheme.red
                            .withOpacity(0.1)
                        : Theme.of(context)
                            .cardTheme.color,
                    borderRadius:
                      BorderRadius.circular(16)
                        .copyWith(
                      bottomRight: message.isUser
                        ? const Radius.circular(4)
                        : null,
                      bottomLeft: !message.isUser
                        ? const Radius.circular(4)
                        : null,
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser
                        ? Colors.white
                        : null,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
                if (message.disclaimer != null &&
                    message.disclaimer!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 4, left: 4),
                    child: Text(
                      message.disclaimer!,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.accentBlue,
              child: const Icon(
                Icons.person,
                size: 18,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Typing Indicator ─────────────────────────────
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppTheme.primaryBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.psychology,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context)
                .cardTheme.color,
              borderRadius: BorderRadius.circular(16)
                .copyWith(
                bottomLeft: const Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dot(0),
                const SizedBox(width: 4),
                _dot(150),
                const SizedBox(width: 4),
                _dot(300),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(
        milliseconds: 600 + delayMs),
      builder: (_, value, __) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(
            0.3 + value * 0.7),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  // ── Input Area ───────────────────────────────────
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Stock analysis button
            IconButton(
              icon: const Icon(
                Icons.candlestick_chart,
                color: AppTheme.primaryBlue,
              ),
              onPressed: () =>
                _showStockAnalysisDialog(),
              tooltip: 'Analyse a stock',
            ),

            // Portfolio analysis button
            IconButton(
              icon: const Icon(
                Icons.pie_chart_outline,
                color: AppTheme.accentBlue,
              ),
              onPressed: () => _sendMessage(
                'Analyse my portfolio and give me '
                'a health report',
                'PORTFOLIO_ANALYSIS',
              ),
              tooltip: 'Analyse my portfolio',
            ),

            // Text input
            Expanded(
              child: TextField(
                controller: _messageCtrl,
                decoration: InputDecoration(
                  hintText: 'Ask anything...',
                  border: OutlineInputBorder(
                    borderRadius:
                      BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  contentPadding:
                    const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                ),
                maxLines: null,
                textInputAction:
                  TextInputAction.send,
                onSubmitted: (text) =>
                  _sendMessage(text, 'GENERAL'),
              ),
            ),

            const SizedBox(width: 8),

            // Send button
            GestureDetector(
              onTap: _isLoading
                ? null
                : () => _sendMessage(
                    _messageCtrl.text, 'GENERAL'),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _isLoading
                    ? Colors.grey
                    : AppTheme.primaryBlue,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isLoading
                    ? Icons.hourglass_empty
                    : Icons.send,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Stock Analysis Dialog ────────────────────────
  void _showStockAnalysisDialog() {
    final symbolCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Analyse a Stock'),
        content: TextField(
          controller: symbolCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. RELIANCE, TCS, INFY',
            labelText: 'Stock Symbol',
          ),
          textCapitalization:
            TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () =>
              Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (symbolCtrl.text.isEmpty) return;
              Navigator.pop(ctx);
              _sendMessage(
                'Give me a complete analysis of '
                '${symbolCtrl.text.toUpperCase()} stock',
                'STOCK_ANALYSIS',
                symbol: symbolCtrl.text
                  .toUpperCase(),
              );
            },
            child: const Text('Analyse'),
          ),
        ],
      ),
    );
  }
}

// ── Message model ────────────────────────────────────
class _ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;
  final String? disclaimer;

  _ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
    this.disclaimer,
  });
}