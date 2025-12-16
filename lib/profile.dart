import 'dart:ui';
import 'package:flutter/material.dart';
import 'main.dart'; // Assume this is your HomePage

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _openEdit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _EditProfileSheet(),
    );
  }

  void _signOut(BuildContext context) {
    // Điều hướng về HomePage khi Sign Out
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF00E676), // xanh ít
              Color(0xFF0D1117),
              Color(0xFF0D1117),
              Color(0xFF0D1117), // đen nhiều
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 5),
              // BACK BUTTON
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white), // Dấu "<" với màu trắng
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(height: 40),

              // AVATAR
              const CircleAvatar(
                radius: 46,
                backgroundColor: Colors.black,
                child: Text(
                  "Anh",
                  style: TextStyle(
                    color: Color(0xFF00E676),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                "Nguyễn Anh Nhật Huy",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 15),

              // EDIT BUTTON
              GestureDetector(
                onTap: () => _openEdit(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white),
                  ),
                  child: const Text(
                    "Edit profile",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 45),

              // GLASS CARD
              _glassCard(
                child: Column(
                  children: const [
                    _Item(Icons.email, "Email"),
                    _Divider(),
                    _Item(Icons.archive, "Archive"),
                    _Divider(),
                    _Item(Icons.folder, "Library"),
                  ],
                ),
              ),

              const SizedBox(height: 24), // Adjusted space between glassCard and sign-out button

              // Use Spacer or Expanded to push Sign Out button down
              const Spacer(),

              // SIGN OUT BUTTON
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: GestureDetector(
                  onTap: () => _signOut(context),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1), // Nền mờ cho nút sign out
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15), // Gạch viền mờ
                      ),
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(13),
                          child: Icon(Icons.exit_to_app, color: Colors.white), // Biểu tượng "Sign out"
                        ),
                        const Text(
                          "Sign out",
                          style: TextStyle(
                            color: Colors.white,
                            /*fontWeight: FontWeight.bold,*/
                            fontSize: 16.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= GLASS CARD =================
  static Widget _glassCard({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18), // Bo góc cho Card
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18), // Bo góc cho Container
              border: Border.all(color: Colors.white.withOpacity(0.15), width: 1), // Viền mờ
              color: Colors.white.withOpacity(0.1), // Màu nền mờ cho glass card
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Item(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(text, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white54),
      onTap: () {},
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      color: Colors.white38,
      thickness: 1,
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet();

  @override
  _EditProfileSheetState createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final TextEditingController _usernameController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      maxChildSize: 0.85,
      minChildSize: 0.45,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF121212), // Nền xám đen
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [

                const SizedBox(height: 25),

                // Avatar section
                Stack(
                  children: [
                    const CircleAvatar(
                      radius: 55, // Tăng kích thước của avatar chính
                      backgroundColor: Color(0xFF6A1B9A), // Màu background cho avatar
                      child: Text(
                        "NH",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 30, // Tăng kích thước chữ trong avatar
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 15, // Tăng kích thước của avatar camera
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.camera_alt,
                          size: 18, // Tăng kích thước của biểu tượng camera
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 42), // Khoảng cách giữa avatar và tên người dùng

                // Tên người dùng label
                Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    "  Name", // Label cho input
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 15,
                      /*fontWeight: FontWeight.bold,*/
                    ),
                  ),
                ),

                const SizedBox(height: 8), // Khoảng cách giữa label và TextField

                // Tên người dùng input field
                TextField(
                  controller: _usernameController,
                  style: const TextStyle(color: Colors.white, fontSize: 18), // Thêm kích thước chữ
                  decoration: InputDecoration(
                    hintText: "",
                    hintStyle: const TextStyle(color: Colors.white),
                    filled: true,
                    fillColor: const Color(0xFF121212), // Màu nền ô nhập liệu
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 45), // Khoảng cách giữa ô nhập tên người dùng và nút

                // Lưu hồ sơ button
                SizedBox(
                  width: 150,
                  height: 45,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFFFFF),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Save",
                      style: TextStyle(fontSize: 18), // Thêm kích thước chữ cho nút Save
                    ),
                  ),
                ),

                const SizedBox(height: 15), // Khoảng cách giữa nút lưu và nút hủy

                // Hủy button
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.white70, fontSize: 18), // Thêm kích thước chữ cho nút Cancel
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

