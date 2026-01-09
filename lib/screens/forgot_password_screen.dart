import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen e-postanızı girin.")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sıfırlama bağlantısı e-postanıza gönderildi! 📧"), backgroundColor: Colors.green)
        );
        Navigator.pop(context); // Giriş ekranına dön
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: ${e.message}"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Şifre Sıfırlama")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("E-posta adresinizi girin, size şifre sıfırlama bağlantısı gönderelim.", textAlign: TextAlign.center),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "E-posta", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _resetPassword,
                    child: const Text("Bağlantı Gönder"),
                  ),
          ],
        ),
      ),
    );
  }
}