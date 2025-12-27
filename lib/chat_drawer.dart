import 'package:flutter/material.dart';
import 'profile.dart';
import 'library_page.dart';
import 'chat.dart';
import 'services/auth_service.dart';
import 'services/chat_service.dart';
import 'models/auth_models.dart';
import 'models/chat_models.dart';

class ChatDrawer extends StatefulWidget {
  const ChatDrawer({super.key});

  @override
  State<ChatDrawer> createState() => _ChatDrawerState();
}

class _ChatDrawerState extends State<ChatDrawer> {
  String _fullName = 'User';
  String _email = 'user@email.com';
  final _authService = AuthService();
  final _chatService = ChatService();
  List<SessionDto> _sessions = [];
  bool _isLoadingSessions = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadSessions();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getUser();
    if (user != null && mounted) {
      setState(() {
        _fullName = user.fullName ?? 'User';
        _email = user.email ?? 'user@email.com';
      });
    }
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoadingSessions = true);
    final sessions = await _chatService.getSessions();
    // Sort by LastActiveAt descending (newest first)
    sessions.sort((a, b) => b.lastActiveAt.compareTo(a.lastActiveAt));
    if (mounted) {
      setState(() {
        _sessions = sessions;
        _isLoadingSessions = false;
      });
    }
  }

  void _navigateToChat(BuildContext context, int? sessionId) {
    Navigator.pop(context); // Close drawer
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(existingSessionId: sessionId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.75, // Increased width slightly
      child: Drawer(
        backgroundColor: const Color(0xFF0D1117),
        child: SafeArea(
          child: Column(
            children: [
              // � NEW CHAT BUTTON & SEARCH
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => _navigateToChat(context, null),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                         padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                         decoration: BoxDecoration(
                           color: const Color(0xFF1F2933),
                           borderRadius: BorderRadius.circular(10),
                           border: Border.all(color: Colors.white10),
                         ),
                         child: Row(
                           children: const [
                             Icon(Icons.add, color: Colors.white),
                             SizedBox(width: 8),
                             Text(
                               "New Chat",
                               style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                             ),
                           ],
                         ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161B22),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const TextField(
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          icon: Icon(Icons.search, color: Colors.white54),
                          hintText: "Search chats",
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(color: Colors.white12),

              // � CHAT LIST
              Expanded(
                child: _isLoadingSessions
                    ? const Center(child: CircularProgressIndicator())
                    : _sessions.isEmpty
                        ? const Center(
                            child: Text(
                              "No chats yet",
                              style: TextStyle(color: Colors.white54),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _sessions.length,
                            itemBuilder: (context, index) {
                              final session = _sessions[index];
                              return _drawerItem(
                                Icons.chat_bubble_outline,
                                session.title,
                                onTap: (context) => _navigateToChat(context, session.id),
                              );
                            },
                          ),
              ),

              const Divider(color: Colors.white12),

              // 📂 MENU
              _drawerItem(
                Icons.folder,
                "Library",
                onTap: (context) {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LibraryPage(),
                    ),
                  );
                },
              ),
              _drawerItem(Icons.settings, "Settings"),

              // 👤 USER INFO
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfilePage(),
                    ),
                  ).then((_) => _loadUser());
                },
                child: Container(
                  color: const Color(0xFF161B22),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF00E676),
                        child: Text(
                          _fullName.isNotEmpty ? _fullName[0].toUpperCase() : 'U',
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _fullName,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _email,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= DRAWER ITEM =================
  static Widget _drawerItem(
    IconData icon,
    String title, {
    bool active = false,
    Function(BuildContext context)? onTap,
  }) {
    return Builder(
      builder: (context) {
        return InkWell(
          onTap: onTap != null ? () => onTap(context) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: active ? const Color(0xFF00E676) : Colors.white70, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: active ? const Color(0xFF00E676) : Colors.white70,
                      fontSize: 14,
                      fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}