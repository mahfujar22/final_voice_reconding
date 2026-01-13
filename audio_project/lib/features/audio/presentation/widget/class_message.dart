enum MessageType { text, audio }

class Message {
  final MessageType type;
  final String content;

  Message({required this.type, required this.content});
}
