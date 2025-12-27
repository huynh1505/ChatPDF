import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'chat_drawer.dart';
import 'services/chat_service.dart';
import 'models/chat_models.dart';

class ChatPage extends StatefulWidget {
  final int? existingSessionId; // Accept optional session ID

  const ChatPage({super.key, this.existingSessionId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_Message> _messages = [];
  final SpeechToText _speech = SpeechToText();
  final ChatService _chatService = ChatService();

  int? _currentSessionId;
  bool _isInitLoading = false;

  // File? _attachedFile;
  bool _hasText = false;
  bool _isBotTyping = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _currentSessionId = widget.existingSessionId;

    if (_currentSessionId != null) {
      _loadHistory();
    }

    _controller.addListener(() {
      setState(() {
        _hasText = _controller.text.trim().isNotEmpty;
      });
    });
  }

  Future<void> _loadHistory() async {
    if (_currentSessionId == null) return;

    setState(() => _isInitLoading = true);

    try {
      // Fetch session details (mainly for documents)
      final session = await _chatService.getSession(_currentSessionId!);
      // Fetch messages explicitly as requested
      final messages = await _chatService.getMessages(_currentSessionId!);

      if (mounted) {
        setState(() {
          _messages.clear();

          // 1. Create a temporary list to merge items
          final List<dynamic> combinedItems = [];
          
          // Add All Messages
          combinedItems.addAll(messages);
          
          // Add All Documents (mapped to preserve timestamp)
          if (session != null) {
            combinedItems.addAll(session.documents);
          }

          // 2. Sort by timestamp
          combinedItems.sort((a, b) {
            DateTime timeA;
            DateTime timeB;

            if (a is MessageDto) timeA = a.timestamp;
            else if (a is DocumentItemDto) timeA = a.createdAt;
            else timeA = DateTime.now(); // Fallback

            if (b is MessageDto) timeB = b.timestamp;
            else if (b is DocumentItemDto) timeB = b.createdAt;
            else timeB = DateTime.now();

            return timeA.compareTo(timeB);
          });

          // 3. Convert to UI Models
          for (var item in combinedItems) {
            if (item is MessageDto) {
              print("Loading Message: isUser=${item.isUser}, Content=${item.content}"); // DEBUG
              _messages.add(_Message(
                isUser: item.isUser,
                text: item.content,
              ));
            } else if (item is DocumentItemDto) {
              print("Loading Document: ${item.fileName}"); // DEBUG
              _messages.add(_Message(
                isUser: true, // Files are uploaded by user
                text: "Uploaded PDF",
                fileName: item.fileName,
              ));
            }
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      print("Error loading history: $e");
    } finally {
      if (mounted) setState(() => _isInitLoading = false);
    }
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
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ================= VOICE INPUT =================
  Future<void> _listen() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      _showSnack("Microphone permission denied");
      return;
    }

    final available = await _speech.initialize(
      onStatus: (val) {
        if (val == 'done' || val == 'notListening') {
          if (mounted) setState(() => _isListening = false);
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

    setState(() => _isListening = true);
  }

  // PlatformFile supports both path (mobile) and bytes (web)
  PlatformFile? _attachedFile;

  // ...

  // ================= PICK PDF =================
  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true, // Important for Web to get bytes
    );

    if (result != null) {
      setState(() {
        _attachedFile = result.files.first;
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

    final userText = _controller.text.trim();

    // 1. Display User Message immediately
    setState(() {
      _messages.add(_Message(
        isUser: true,
        text: userText.isNotEmpty ? userText : (hasFile ? "Uploaded PDF" : ""),
        fileName: hasFile ? _attachedFile!.name : null,
      ));
      _isBotTyping = true;
    });
    _scrollToBottom();
    _controller.clear();

    // 2. Create Session if needed
    if (_currentSessionId == null) {
      final session = await _chatService.createChat(
          userText.isNotEmpty ? (userText.length > 20 ? '${userText.substring(0,20)}...' : userText) : "New Chat"
      );
      if (session != null) {
        _currentSessionId = session.id;
      } else {
        setState(() {
          _isBotTyping = false;
          _showSnack("Failed to create chat session");
        });
        return;
      }
    }

    // 3. (Removed redundant loading state)

    // 4. Send API Request (Upload first)
    if (_attachedFile != null) {
        // Show "Uploading..." system message
        setState(() {
          _messages.add(_Message(
            isUser: false,
            text: "Uploading ${_attachedFile!.name}...",
            isLoading: true,
            isSystem: true,
          ));
        });
        _scrollToBottom();

        // Use bytes if available (Web), otherwise fallback to reading file from path (Mobile)
        List<int>? fileBytes = _attachedFile!.bytes;
        if (fileBytes == null && _attachedFile!.path != null) {
          fileBytes = await File(_attachedFile!.path!).readAsBytes();
        }

        if (fileBytes != null) {
          final uploadResult = await _chatService.uploadDocument(_currentSessionId!, fileBytes, _attachedFile!.name);
          
          if (!uploadResult['success']) {
              // Upload Failed
              setState(() {
                _messages.removeLast(); // Remove "Uploading..."
                _showSnack("Upload Failed: ${uploadResult['message']}");
                _isBotTyping = false;
              });
              return; 
          }

          // Upload Success: Now Poll for Status
          final documentId = uploadResult['documentId'] as int?;
          if (documentId != null) {
              // Update status to "Processing..."
              setState(() {
                 _messages.removeLast();
                 _messages.add(_Message(
                   isUser: false,
                   text: "Processing file...",
                   isLoading: true,
                   isSystem: true,
                 ));
              });

              // Polling Loop
              bool isProcessed = false;
              int attempts = 0;
              while (!isProcessed && attempts < 30) { // Timeout ~60s
                 await Future.delayed(const Duration(seconds: 2));
                 final status = await _chatService.getDocumentStatus(documentId);
                 
                 print("Document ID $documentId Status: $status");

                 if (status == 'Processed') {
                   isProcessed = true;
                 } else if (status == 'Error' || status == 'Failed') {
                   break;
                 }
                 attempts++;
              }

              setState(() {
                 _messages.removeLast(); // Remove "Processing..."
              });
              
              if (isProcessed) {
                 // Success: Show "Processed" message
                 setState(() {
                   _messages.add(_Message(
                     isUser: false,
                     text: "File processed and ready for chat.",
                     isSystem: true,
                   ));
                 });
              } else {
                 // Timeout or Error
                 setState(() {
                    _showSnack("File processing failed or timed out.");
                    _isBotTyping = false;
                 });
                 return;
              }

          } else {
             // Should not happen if success is true
             setState(() {
                _messages.removeLast();
                _showSnack("Upload Error: No Document ID returned");
                _isBotTyping = false;
             });
             return;
          }

       } else {
          setState(() {
             _messages.removeLast();
             _showSnack("Error: Could not read file data");
             _isBotTyping = false;
          });
          return;
       }
    }

      final contentToSend = userText.isNotEmpty ? userText : "Please analyze the uploaded document.";

      // Show User's actual question loading state
      setState(() {
        _messages.add(const _Message(isUser: false, isLoading: true));
      });
      _scrollToBottom();

      final response = await _chatService.sendMessage(_currentSessionId!, contentToSend);

      // 5. Update UI with Response
      setState(() {
        _messages.removeLast(); // Remove loading
        if (response != null) {
          _messages.add(_Message(
            isUser: false,
            text: response.botMessage.content,
          ));
        } else {
          _messages.add(const _Message(
            isUser: false,
            text: "Error: Could not get response from server.",
          ));
        }
        _isBotTyping = false;
      });

      _hasText = false;
      _attachedFile = null;
      _scrollToBottom();
    }

        // ================= 3 DOT MENU =================
        void _showMoreMenu(BuildContext context) async {
      final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

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
            value: 'create_new',
            child: _MenuItem(
              icon: Icons.add,
              text: 'New Chat',
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: _MenuItem(
              icon: Icons.delete,
              text: 'Clear Chat',
              isDanger: true,
            ),
          ),
        ],
      );

      switch (result) {
        case 'create_new':
        // Reset state for new chat
          setState(() {
            _currentSessionId = null;
            _messages.clear();
          });
          break;
        case 'delete':
          setState(() => _messages.clear());
          _showSnack("Chat cleared");
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
                child: _isInitLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _messages.isEmpty
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

                    // RENDER SYSTEM MESSAGE
                    if (msg.isSystem) {
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (msg.isLoading)
                              const SizedBox(
                                width: 12, height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
                              ),
                            if (msg.isLoading) const SizedBox(width: 8),
                            Text(
                              msg.text ?? "",
                              style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic
                              ),
                            ),
                            if (!msg.isLoading)
                              const Padding(
                                padding: EdgeInsets.only(left: 6),
                                child: Icon(Icons.check_circle, size: 14, color: Colors.greenAccent),
                              )
                          ],
                        ),
                      );
                    }

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
              // ... (keeping input bar logic)
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
                                _attachedFile!.path!.split('/').last,
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
  final bool isSystem;

  const _Message({
  required this.isUser,
  this.text,
  this.fileName,
  this.isLoading = false,
  this.isSystem = false,
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