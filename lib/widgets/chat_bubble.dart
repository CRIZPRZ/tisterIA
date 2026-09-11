import 'package:flutter/material.dart';

import '../models/chat.dart';
import '../theme/app_theme.dart';

/// Convierte **negritas** dentro de una línea en spans con estilo bold,
/// sin depender de un paquete de markdown completo.
List<InlineSpan> _inlineBoldSpans(String text, TextStyle base) {
  final boldStyle = base.copyWith(fontWeight: FontWeight.w700, color: Colors.white);
  final regex = RegExp(r'\*\*(.+?)\*\*');
  final spans = <InlineSpan>[];
  var cursor = 0;
  for (final match in regex.allMatches(text)) {
    if (match.start > cursor) {
      spans.add(TextSpan(text: text.substring(cursor, match.start), style: base));
    }
    spans.add(TextSpan(text: match.group(1), style: boldStyle));
    cursor = match.end;
  }
  if (cursor < text.length) {
    spans.add(TextSpan(text: text.substring(cursor), style: base));
  }
  return spans;
}

/// Renderiza el texto de un mensaje de IA con soporte ligero para
/// **negritas** y líneas "- " como viñetas, en vez de texto plano crudo.
class _FormattedMessageText extends StatelessWidget {
  final String text;
  final TextStyle baseStyle;
  const _FormattedMessageText({required this.text, required this.baseStyle});

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final widgets = <Widget>[];

    for (final rawLine in lines) {
      final line = rawLine.trimRight();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }
      if (line.trimLeft().startsWith('- ')) {
        final content = line.trimLeft().substring(2);
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6, right: 8),
                child: Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle)),
              ),
              Expanded(child: RichText(text: TextSpan(children: _inlineBoldSpans(content, baseStyle)))),
            ],
          ),
        ));
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: RichText(text: TextSpan(children: _inlineBoldSpans(line, baseStyle))),
        ));
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }
}

class _OutcomeRow extends StatelessWidget {
  final ChatOutcome outcome;
  final bool isFavorite;
  const _OutcomeRow({required this.outcome, required this.isFavorite});

  @override
  Widget build(BuildContext context) {
    final color = isFavorite ? AppColors.green : AppColors.red;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(isFavorite ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(outcome.label, style: AppText.style(12.5, weight: FontWeight.w600, color: Colors.white)),
          ),
          Text('${outcome.prob}%', style: AppText.style(13, weight: FontWeight.w700, color: AppColors.green)),
        ],
      ),
    );
  }
}

class _OutcomesCard extends StatelessWidget {
  final List<ChatOutcome> outcomes;
  const _OutcomesCard({required this.outcomes});

  @override
  Widget build(BuildContext context) {
    final maxProb = outcomes.map((o) => o.prob).reduce((a, b) => a > b ? a : b);
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.screenBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: outcomes.map((o) => _OutcomeRow(outcome: o, isFavorite: o.prob == maxProb)).toList(),
      ),
    );
  }
}

class _SuggestionChips extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onTap;
  const _SuggestionChips({required this.suggestions, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: suggestions
            .map((s) => GestureDetector(
                  onTap: () => onTap(s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.greenTint,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.green.withValues(alpha: 0.4)),
                    ),
                    child: Text(s, style: AppText.style(11.5, weight: FontWeight.w600, color: AppColors.green)),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final ValueChanged<String>? onSuggestionTap;
  const ChatBubble({super.key, required this.message, this.onSuggestionTap});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    final baseStyle = AppText.style(13, color: isUser ? Colors.white : AppColors.textBody, height: 1.5);
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? AppColors.greenTint : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isUser ? AppColors.green.withValues(alpha: 0.35) : AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.title != null) ...[
              Text(message.title!, style: AppText.style(13, weight: FontWeight.w700)),
              const SizedBox(height: 6),
            ],
            isUser
                ? Text(message.text, style: baseStyle)
                : _FormattedMessageText(text: message.text, baseStyle: baseStyle),
            if (!isUser && message.outcomes.isNotEmpty) _OutcomesCard(outcomes: message.outcomes),
            if (!isUser && message.suggestions.isNotEmpty && onSuggestionTap != null)
              _SuggestionChips(suggestions: message.suggestions, onTap: onSuggestionTap!),
          ],
        ),
      ),
    );
  }
}

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final String hint;
  final bool enabled;
  const ChatInputBar({super.key, required this.controller, required this.onSend, required this.hint, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 16),
      decoration: const BoxDecoration(
        color: AppColors.screenBg,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              style: AppText.style(13),
              cursorColor: Colors.white,
              onSubmitted: enabled ? (_) => onSend() : null,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppText.style(12, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.card,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: AppColors.green),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: enabled ? onSend : null,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: enabled ? AppColors.green : AppColors.cardBorder, shape: BoxShape.circle),
              child: Icon(Icons.arrow_upward_rounded, size: 20, color: enabled ? const Color(0xFF0A0A0B) : AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
