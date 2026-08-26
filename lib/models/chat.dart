enum ChatRole { user, ai }

class ChatOutcome {
  final String label;
  final int prob;

  const ChatOutcome({required this.label, required this.prob});

  factory ChatOutcome.fromJson(Map<String, dynamic> json) => ChatOutcome(
        label: json['label'] as String,
        prob: json['prob'] as int,
      );
}

class ChatMessage {
  final ChatRole role;
  final String text;
  final String? title;
  final List<ChatOutcome> outcomes;
  final List<String> suggestions;

  const ChatMessage({
    required this.role,
    required this.text,
    this.title,
    this.outcomes = const [],
    this.suggestions = const [],
  });
}
