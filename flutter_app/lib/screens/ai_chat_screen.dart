import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ai_provider.dart';
import '../providers/kundali_provider.dart';
import '../models/models.dart';
import '../theme/cosmic_theme.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});
  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  final _quickQuestions = [
    'Analyze my personality based on the ascendant',
    'What are my career prospects?',
    'Tell me about my current dasha period',
    'What yogas are active in my chart?',
    'Analyze my marriage and relationships',
    'What are my financial strengths?',
  ];

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    context.read<AIProvider>().sendMessage(text);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AIProvider>();
    final kundali = context.watch<KundaliProvider>().currentKundali;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('AI Jyotish Consult'),
        actions: [
          // Tradition picker
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, size: 20),
            tooltip: 'Select Tradition',
            onSelected: (v) => ai.setTradition(v == 'all' ? null : v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'all', child: Text('All Traditions')),
              const PopupMenuItem(value: 'parashara', child: Text('Parashara')),
              const PopupMenuItem(value: 'classical_hora', child: Text('Classical Hora')),
              const PopupMenuItem(value: 'jaimini', child: Text('Jaimini')),
              const PopupMenuItem(value: 'prasna', child: Text('Prasna (Horary)')),
              const PopupMenuItem(value: 'krishnamurti', child: Text('Krishnamurti Paddhati')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'New Conversation',
            onPressed: () => ai.clearConversation(),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: CosmicTheme.cosmicGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Kundali context indicator
              if (kundali != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: CosmicTheme.starGold.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: CosmicTheme.starGold.withOpacity(0.2)),
                  ),
                  child: Row(children: [
                    Icon(Icons.auto_awesome, size: 14, color: CosmicTheme.starGold),
                    const SizedBox(width: 8),
                    Text('Analyzing: ${kundali.name ?? kundali.ascendantRashi} Asc',
                      style: TextStyle(color: CosmicTheme.starGold, fontSize: 12)),
                    if (ai.selectedTradition != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: CosmicTheme.celestialBlue.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                        child: Text(ai.selectedTradition!, style: const TextStyle(color: CosmicTheme.celestialBlue, fontSize: 10)),
                      ),
                    ],
                  ]),
                ),

              // Messages
              Expanded(
                child: ai.messages.isEmpty
                    ? _WelcomeView(quickQuestions: _quickQuestions, onQuestionTap: (q) {
                        _controller.text = q;
                        _send();
                      })
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: ai.messages.length + (ai.isLoading ? 1 : 0),
                        itemBuilder: (context, i) {
                          if (i == ai.messages.length && ai.isLoading) return _TypingIndicator();
                          return _MessageBubble(message: ai.messages[i]);
                        },
                      ),
              ),

              // Input
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
                decoration: BoxDecoration(
                  color: CosmicTheme.cosmicNavy,
                  border: Border(top: BorderSide(color: CosmicTheme.borderGlow.withOpacity(0.5))),
                ),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: 'Ask about your chart...',
                        filled: true,
                        fillColor: CosmicTheme.surfaceDark,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      ),
                      style: const TextStyle(fontSize: 14),
                      maxLines: 3,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: ai.isLoading ? null : CosmicTheme.goldGradient,
                      color: ai.isLoading ? CosmicTheme.rahuSmoke : null,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.send_rounded, color: ai.isLoading ? Colors.white38 : CosmicTheme.deepSpace, size: 20),
                      onPressed: ai.isLoading ? null : _send,
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeView extends StatelessWidget {
  final List<String> quickQuestions;
  final Function(String) onQuestionTap;
  const _WelcomeView({required this.quickQuestions, required this.onQuestionTap});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const SizedBox(height: 20),
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: CosmicTheme.goldGradient,
            boxShadow: [BoxShadow(color: CosmicTheme.starGold.withOpacity(0.3), blurRadius: 20)],
          ),
          child: const Icon(Icons.auto_awesome, color: CosmicTheme.deepSpace, size: 30),
        ),
        const SizedBox(height: 20),
        Text('Jyotish AI', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: CosmicTheme.starGold)),
        const SizedBox(height: 8),
        Text(
          'Ask me anything about your kundali.\nI draw knowledge from classical Vedic texts.',
          textAlign: TextAlign.center,
          style: TextStyle(color: CosmicTheme.moonSilver.withOpacity(0.6), fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 28),
        Text('Suggested Questions', style: TextStyle(color: CosmicTheme.rahuSmoke, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ...quickQuestions.map((q) => GestureDetector(
          onTap: () => onQuestionTap(q),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: CosmicTheme.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CosmicTheme.borderGlow),
            ),
            child: Row(children: [
              Icon(Icons.chat_bubble_outline, size: 16, color: CosmicTheme.starGold.withOpacity(0.5)),
              const SizedBox(width: 12),
              Expanded(child: Text(q, style: TextStyle(color: CosmicTheme.moonSilver.withOpacity(0.8), fontSize: 13))),
              Icon(Icons.chevron_right, size: 16, color: CosmicTheme.rahuSmoke),
            ]),
          ),
        )),
      ]),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final AIMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Container(
      margin: EdgeInsets.only(
        bottom: 12,
        left: isUser ? 40 : 0,
        right: isUser ? 0 : 40,
      ),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Role label
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
            child: Text(
              isUser ? 'You' : 'Jyotish AI',
              style: TextStyle(
                color: isUser ? CosmicTheme.celestialBlue : CosmicTheme.starGold,
                fontSize: 11, fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Bubble
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isUser ? CosmicTheme.celestialBlue.withOpacity(0.12) : CosmicTheme.cardBg,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
              border: Border.all(color: isUser ? CosmicTheme.celestialBlue.withOpacity(0.2) : CosmicTheme.borderGlow),
            ),
            child: SelectableText(
              message.content,
              style: TextStyle(color: CosmicTheme.moonSilver, fontSize: 13.5, height: 1.5),
            ),
          ),
          // Sources
          if (!isUser && message.sources.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Wrap(spacing: 6, children: message.sources.take(3).map((s) {
                final source = s is Map ? s['source'] ?? '' : '';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: CosmicTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: CosmicTheme.borderGlow),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.menu_book, size: 10, color: CosmicTheme.rahuSmoke),
                    const SizedBox(width: 4),
                    Text(source.toString(), style: TextStyle(color: CosmicTheme.rahuSmoke, fontSize: 10)),
                  ]),
                );
              }).toList()),
            ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 80, bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CosmicTheme.cardBg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16), topRight: Radius.circular(16),
          bottomLeft: Radius.circular(4), bottomRight: Radius.circular(16),
        ),
        border: Border.all(color: CosmicTheme.borderGlow),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _Dot(delay: 0), _Dot(delay: 200), _Dot(delay: 400),
        const SizedBox(width: 8),
        Text('Consulting the stars...', style: TextStyle(color: CosmicTheme.rahuSmoke, fontSize: 12, fontStyle: FontStyle.italic)),
      ]),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _anim = Tween(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 7, height: 7,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: CosmicTheme.starGold.withOpacity(_anim.value),
        ),
      ),
    );
  }
}
