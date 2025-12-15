import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'chat_drawer.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final List<_Message> _messages = [];

  File? _attachedFile;
  bool _hasText = false;
  bool _isBotTyping = false;

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
    super.dispose();
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

    _controller.clear();
    _attachedFile = null;
    _hasText = false;

    setState(() {
      _messages.add(const _Message(isUser: false, isLoading: true));
    });

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
                        onPressed: () =>
                            Scaffold.of(context).openDrawer(),
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
                      icon: const Icon(Icons.more_horiz,
                          color: Colors.white),
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
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return Align(
                    alignment: msg.isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin:
                      const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      constraints:
                      const BoxConstraints(maxWidth: 280),
                      decoration: BoxDecoration(
                        color: msg.isUser
                            ? const Color(0xFF1A1F24)
                            : const Color(0xFF1F2933),
                        borderRadius:
                        BorderRadius.circular(14),
                      ),
                      child: msg.isLoading
                          ? const SizedBox(
                        height: 18,
                        width: 18,
                        child:
                        CircularProgressIndicator(
                            strokeWidth: 2),
                      )
                          : Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          if (msg.fileName != null)
                            Row(
                              children: [
                                const Icon(
                                    Icons.picture_as_pdf,
                                    size: 16,
                                    color: Colors.red),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    msg.fileName!,
                                    style:
                                    const TextStyle(
                                        color:
                                        Colors.white,
                                        fontSize: 12),
                                    overflow:
                                    TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          if (msg.text != null)
                            Padding(
                              padding:
                              const EdgeInsets.only(
                                  top: 6),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg.text!,
                                    style:
                                    const TextStyle(
                                        color:
                                        Colors.white),
                                  ),
                                  if (!msg.isUser)
                                    Align(
                                      alignment:
                                      Alignment.centerRight,
                                      child: IconButton(
                                        icon:
                                        const Icon(
                                          Icons.copy,
                                          size: 18,
                                          color:
                                          Colors.white54,
                                        ),
                                        onPressed: () {
                                          Clipboard.setData(
                                            ClipboardData(
                                                text: msg
                                                    .text!),
                                          );
                                          _showSnack(
                                              "Copied");
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
              padding:
              const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
                          borderRadius:
                          BorderRadius.circular(20),
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
                                  color: Colors.white,
                                  fontSize: 12),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: _removePdf,
                              child: const Icon(Icons.close,
                                  size: 16,
                                  color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add,
                              color: Colors.white),
                          onPressed: _pickPdf,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            style: const TextStyle(
                                color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: "Ask anything",
                              hintStyle:
                              TextStyle(color: Colors.white54),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        AnimatedSwitcher(
                          duration:
                          const Duration(milliseconds: 160),
                          child: _hasText
                              ? Padding(
                            key:
                            const ValueKey("send"),
                            padding:
                            const EdgeInsets.only(left: 6),
                            child: GestureDetector(
                              onTap: _sendMessage,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration:
                                const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                    Icons.arrow_upward,
                                    color: Colors.black),
                              ),
                            ),
                          )
                              : Padding(
                            key:
                            const ValueKey("mic"),
                            padding:
                            const EdgeInsets.only(left: 6),
                            child: IconButton(
                              icon: const Icon(Icons.mic,
                                  color: Colors.white),
                              onPressed: () {},
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
