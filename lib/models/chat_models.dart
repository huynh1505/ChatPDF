class CreateSessionDto {
  final String? title;

  CreateSessionDto({this.title});

  Map<String, dynamic> toJson() => {'title': title};
}

class SendMessageDto {
  final String content;

  SendMessageDto({required this.content});

  Map<String, dynamic> toJson() => {'content': content};
}

class MessageDto {
  final int id;
  final String content;
  final bool isUser;
  final DateTime timestamp;

  MessageDto({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
  });

  factory MessageDto.fromJson(Map<String, dynamic> json) {
    return MessageDto(
      id: json['id'],
      content: json['content'],
      isUser: json['isUser'] ?? json['IsUser'] ?? false, // Handle PascalCase and default
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class DocumentItemDto {
  final int id;
  final String fileName;
  final int fileSize;
  final String status;
  final DateTime createdAt;

  DocumentItemDto({
    required this.id,
    required this.fileName,
    required this.fileSize,
    required this.status,
    required this.createdAt,
  });

  factory DocumentItemDto.fromJson(Map<String, dynamic> json) {
    return DocumentItemDto(
      id: json['id'],
      fileName: json['fileName'] ?? '',
      fileSize: json['fileSize'] ?? 0,
      status: json['statusDisplay'] ?? 'Pending', // StatusDisplay from backend
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class SessionDto {
  final int id;
  final String title;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final int messageCount;
  final List<DocumentItemDto> documents;
  final List<MessageDto> messages;

  SessionDto({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.lastActiveAt,
    required this.messageCount,
    required this.documents,
    required this.messages,
  });

  factory SessionDto.fromJson(Map<String, dynamic> json) {
    return SessionDto(
      id: json['id'],
      title: json['title'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      lastActiveAt: DateTime.parse(json['lastActiveAt']),
      messageCount: json['messageCount'] ?? 0,
      documents: (json['documents'] as List<dynamic>?)
          ?.map((e) => DocumentItemDto.fromJson(e))
          .toList() ?? [],
      messages: (json['messages'] as List<dynamic>?)
          ?.map((e) => MessageDto.fromJson(e))
          .toList() ?? [],
    );
  }
}

class ChatResponseDto {
  final MessageDto userMessage;
  final MessageDto botMessage;
  final int processingTimeMs;

  ChatResponseDto({
    required this.userMessage,
    required this.botMessage,
    required this.processingTimeMs,
  });

  factory ChatResponseDto.fromJson(Map<String, dynamic> json) {
    return ChatResponseDto(
      userMessage: MessageDto.fromJson(json['userMessage']),
      botMessage: MessageDto.fromJson(json['botMessage']),
      processingTimeMs: json['processingTimeMs'] ?? 0,
    );
  }
}
