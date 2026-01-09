import 'package:flutter/material.dart';
import 'package:study_track/services/auth_service.dart';
import 'package:study_track/screens/dashboard_screen.dart';
import 'package:study_track/screens/register_screen.dart';
import 'package:study_track/screens/forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lütfen e-posta ve şifre giriniz!"), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    String? res = await AuthService().signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (res == null) {
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res), backgroundColor: Colors.redAccent));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      // Stack kullanarak arka planı ve içeriği ayırdık
      body: Stack(
        children: [
          // 1. KATMAN: Arka Plan 
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.45,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(50),
                  bottomRight: Radius.circular(50),
                ),
              ),
            ),
          ),

          // 2. KATMAN: Kaydırılabilir İçerik
          // Center ve SingleChildScrollView kombinasyonu hem ortalar hem taşmayı önler
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.school_rounded, size: 60, color: Color(0xFF1A1A2E)),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "StudyTrack",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Text(
                    "Başarıya Odaklan",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  
                  const SizedBox(height: 40),

                  // Form Kartı
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text("Giriş Yap", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                        const SizedBox(height: 20),
                        
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            hintText: "E-posta",
                            prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: "Şifre",
                            prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordScreen())),
                            child: const Text("Şifremi Unuttum?", style: TextStyle(color: Color(0xFFE94560), fontSize: 12)),
                          ),
                        ),

                        const SizedBox(height: 10),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A1A2E),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text("GİRİŞ YAP", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      
                      const Text("Hesabın yok mu?", style: TextStyle(color: Colors.black54)),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                        child: const Text("Hemen Kayıt Ol", style: TextStyle(color: Color(0xFFE94560), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
