import 'package:flutter/material.dart';
import 'login.dart';
import 'chat.dart';
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ChatPage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// BACKGROUND IMAGE
          Positioned.fill(
            child: Image.asset(
              'assets/images/home.png',
              fit: BoxFit.cover,
            ),
          ),

          /// CONTENT
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(flex: 5),

                /// MAIN HEADLINE
                const Text(
                  'Helping you',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 45,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),

                const SizedBox(height: 14),

                /// SUB HEADLINE
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 30,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    children: [
                      TextSpan(text: 'understand '),
                      TextSpan(
                        text: 'PDFs ',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: 'faster'),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// DESCRIPTION (RichText + justify ~3 lines)
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: RichText(
                    textAlign: TextAlign.left, // ✅ bỏ justify
                    text: const TextSpan(
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16.5, // ✅ nhỏ lại
                        color: Color(0xFFE6EDF3),
                        height: 1.45, // ✅ gọn hơn
                      ),
                      children: [
                        TextSpan(text: 'Chat with '),
                        TextSpan(
                          text: 'ChatPDF',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF00E676), // cùng màu nút
                          ),
                        ),
                        TextSpan(
                          text:
                          '. Ask questions and get instant answers from your documents. '
                              'Understand PDFs faster with clear summaries and key insights.',
                        ),
                      ],
                    ),
                  ),
                ),


                const SizedBox(height: 25),

                /// GET STARTED BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                      elevation: 10,
                    ),
                    child: const Text(
                      'Get Started!',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
