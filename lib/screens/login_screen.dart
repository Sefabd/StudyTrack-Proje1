import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

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
    // GÜVENLİK 
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lütfen e-posta ve şifre giriniz!"),
            backgroundColor: Colors.orange, 
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return; 
    }

    // GİRİŞ İŞLEMİ 
    setState(() => _isLoading = true);
    
   
    String? result = await AuthService().signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );
    
    setState(() => _isLoading = false);

    if (result == null) {
      // BAŞARILI 
      if(mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Giriş Başarılı! Hoşgeldin 👋"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
      }
    } else {
      // HATA 
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result), 
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("StudyTrack Giriş")),
      
     
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.school, size: 100, color: Colors.indigo),
                const SizedBox(height: 20),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: "E-posta",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: "Şifre",
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity, 
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _login,
                          child: const Text("Giriş Yap"),
                        ),
                      ),
                      
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()));
                    },
                    child: const Text("Şifremi Unuttum"),
                    ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterScreen(),
                      ),
                    );
                  },
                  child: const Text("Hesabın yok mu? Kayıt Ol"),
                ),
              ],
            ),
          ),
        ),
      ),
      
    );
  }
}
