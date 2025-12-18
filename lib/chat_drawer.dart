import 'package:flutter/material.dart';
import 'profile.dart';
import 'library_page.dart';


class ChatDrawer extends StatelessWidget {
  const ChatDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery
          .of(context)
          .size
          .width * 0.7, // 👈 NỬA MÀN HÌNH
      child: Drawer(
        backgroundColor: const Color(0xFF0D1117),
        child: SafeArea(
          child: Column(
            children: [
              // 🔍 SEARCH BAR
              Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2933),
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
              ),

              // 📂 MENU
              _drawerItem(Icons.chat_bubble, "ChatPDF", active: true),
              _drawerItem(
                Icons.folder,
                "Library",
                onTap: (context) {
                  Navigator.pop(context); // đóng drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LibraryPage(),
                    ),
                  );
                },
              ),
              _drawerItem(Icons.create_new_folder, "New project"),
              _drawerItem(Icons.add_comment, "New chat"),

              const Spacer(),

              // 👤 USER INFO
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfilePage(),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: const [
                      CircleAvatar(
                        backgroundColor: Color(0xFF00E676),
                        child: Icon(Icons.person, color: Colors.black),
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Gia Huy",
                            style: TextStyle(color: Colors.white),
                          ),
                          Text(
                            "gia.huy@email.com",
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
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
      ),
    );
  }

  // ================= DRAWER ITEM =================
  static Widget _drawerItem(IconData icon,
      String title, {
        bool active = false,
        Function(BuildContext context)? onTap,
      }) {
    return Builder(
      builder: (context) =>
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: active ? const Color(0xFF1F2933) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              leading: Icon(icon, color: Colors.white),
              title: Text(
                title,
                style: TextStyle(
                  color: active ? const Color(0xFF00E676) : Colors.white,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              onTap: onTap != null ? () => onTap(context) : null,
            ),
          ),
    );
  }
}