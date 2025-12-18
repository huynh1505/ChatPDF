import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'chat_drawer.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_Message> _messages = [];
  final SpeechToText _speech = SpeechToText();

  File? _attachedFile;
  bool _hasText = false;
  bool _isBotTyping = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _hasText = _controller.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _speech.stop();
    super.dispose();
  }

  // ================= AUTO SCROLL =================
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent,
        );
      }
    });
  }

  // ================= VOICE INPUT =================
  Future<void> _listen() async {
    // If already listening, stop
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    // Request microphone permission
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      _showSnack("Microphone permission denied");
      return;
    }

    // Initialize speech recognition
    final available = await _speech.initialize(
      onStatus: (val) {
        if (val == 'done' || val == 'notListening') {
          if (mounted) {
            setState(() => _isListening = false);
          }
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() => _isListening = false);
          _showSnack("Error: ${error.errorMsg}");
        }
      },
    );

    if (!available) {
      _showSnack("Speech recognition not available");
      return;
    }

    // Start listening
    await _speech.listen(
      localeId: 'en_US',
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      onResult: (val) {
        if (mounted) {
          setState(() {
            _controller.text = val.recognizedWords;
            _controller.selection = TextSelection.fromPosition(
              TextPosition(offset: _controller.text.length),
            );
          });
        }
      },
    );

    // Set listening state only after successfully starting
    setState(() => _isListening = true);
  }

  // ================= PICK PDF =================
  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _attachedFile = File(result.files.single.path!);
      });
    }
  }

  void _removePdf() => setState(() => _attachedFile = null);

  // ================= SEND =================
  Future<void> _sendMessage() async {
    if (_isBotTyping) return;

    final hasText = _controller.text.trim().isNotEmpty;
    final hasFile = _attachedFile != null;
    if (!hasText && !hasFile) return;

    final userText =
    hasText ? _controller.text.trim() : "Analyze this PDF";

    setState(() {
      _messages.add(
        _Message(
          isUser: true,
          text: userText,
          fileName: hasFile ? _attachedFile!.path.split('/').last : null,
        ),
      );
      _isBotTyping = true;
    });
    _scrollToBottom();

    _controller.clear();
    _attachedFile = null;
    _hasText = false;



    setState(() {
      _messages.add(const _Message(isUser: false, isLoading: true));
    });

    _scrollToBottom();

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _messages.removeLast();
      _messages.add(
        const _Message(
          isUser: false,
          text:
          "I analyzed the uploaded PDF and extracted the key information related to your question.",
        ),
      );
      _isBotTyping = false;
    });

    _scrollToBottom();
  }

  // ================= 3 DOT MENU =================
  void _showMoreMenu(BuildContext context) async {
    final overlay =
    Overlay.of(context).context.findRenderObject() as RenderBox;

    final result = await showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(overlay.size.width - 40, 80, 0, 0),
        Offset.zero & overlay.size,
      ),
      color: const Color(0xFF1F2933),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      items: const [
        PopupMenuItem(
          value: 'move',
          child: _MenuItem(
            icon: Icons.drive_file_move,
            text: 'Move to folder',
          ),
        ),
        PopupMenuItem(
          value: 'archive',
          child: _MenuItem(
            icon: Icons.archive,
            text: 'Archive',
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: _MenuItem(
            icon: Icons.delete,
            text: 'Delete',
            isDanger: true,
          ),
        ),
      ],
    );

    switch (result) {
      case 'move':
        _showSnack("Move to folder");
        break;
      case 'archive':
        _showSnack("Archived");
        break;
      case 'delete':
        setState(() => _messages.clear());
        _showSnack("Chat deleted");
        break;
    }
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 1)),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const ChatDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D1117),
              Color(0xFF0D1117),
              Color(0xFF07271D),
              Color(0xFF0E3F2C),
              Color(0xFF00E676),
            ],
          ),
        ),
        child: Column(
          children: [
            // ===== APP BAR =====
            SafeArea(
              child: SizedBox(
                height: 56,
                child: Row(
                  children: [
                    Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          "ChatPDF",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_horiz, color: Colors.white),
                      onPressed: () => _showMoreMenu(context),
                    ),
                  ],
                ),
              ),
            ),

            // ===== CHAT BODY =====
            Expanded(
              child: _messages.isEmpty
                  ? const Center(
                child: Text(
                  "Ask about this PDF?",
                  style: TextStyle(color: Colors.white, fontSize: 22),
                ),
              )
                  : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return Align(
                    alignment: msg.isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      constraints: const BoxConstraints(maxWidth: 280),
                      decoration: BoxDecoration(
                        color: msg.isUser
                            ? const Color(0xFF1A1F24)
                            : const Color(0xFF1F2933),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: msg.isLoading
                          ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2),
                      )
                          : Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          if (msg.fileName != null)
                            Row(
                              children: [
                                const Icon(Icons.picture_as_pdf,
                                    size: 16, color: Colors.red),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    msg.fileName!,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          if (msg.text != null)
                            Padding(
                              padding:
                              const EdgeInsets.only(top: 6),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg.text!,
                                    style: const TextStyle(
                                        color: Colors.white),
                                  ),
                                  if (!msg.isUser)
                                    Align(
                                      alignment:
                                      Alignment.centerRight,
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.copy,
                                          size: 18,
                                          color: Colors.white54,
                                        ),
                                        onPressed: () {
                                          Clipboard.setData(
                                            ClipboardData(
                                                text: msg.text!),
                                          );
                                          _showSnack("Copied");
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // ===== INPUT BAR =====
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_attachedFile != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F2933),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.picture_as_pdf,
                                size: 16, color: Colors.red),
                            const SizedBox(width: 6),
                            Text(
                              _attachedFile!.path.split('/').last,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: _removePdf,
                              child: const Icon(Icons.close,
                                  size: 16, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.white),
                          onPressed: _pickPdf,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: "Ask anything",
                              hintStyle: TextStyle(color: Colors.white54),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 160),
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(
                              scale: animation,
                              child: child,
                            );
                          },
                          child: _hasText || _attachedFile != null
                              ? Padding(
                            key: const ValueKey("send"),
                            padding: const EdgeInsets.only(left: 6),
                            child: GestureDetector(
                              onTap: _sendMessage,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.arrow_upward,
                                    color: Colors.black),
                              ),
                            ),
                          )
                              : Padding(
                            key: ValueKey("mic_$_isListening"),
                            padding: const EdgeInsets.only(left: 6),
                            child: GestureDetector(
                              onTap: _listen,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _isListening
                                      ? Colors.redAccent.withOpacity(0.2)
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _isListening ? Icons.stop : Icons.mic,
                                  color: _isListening
                                      ? Colors.redAccent
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= MODEL =================
class _Message {
  final bool isUser;
  final String? text;
  final String? fileName;
  final bool isLoading;

  const _Message({
    required this.isUser,
    this.text,
    this.fileName,
    this.isLoading = false,
  });
}

// ================= MENU ITEM =================
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDanger;

  const _MenuItem({
    required this.icon,
    required this.text,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? Colors.redAccent : Colors.white;
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Text(text, style: TextStyle(color: color)),
      ],
    );
  }
}