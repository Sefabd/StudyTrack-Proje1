import 'package:flutter/material.dart';
import '../services/auth_service.dart'; 

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  void _register() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurun"), backgroundColor: Colors.orange)
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    String? result = await AuthService().signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      name: _nameController.text.trim(),
    );
    
    setState(() => _isLoading = false);

    if (result == null) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Kayıt Başarılı! Giriş yapabilirsiniz."), backgroundColor: Colors.green)
        );
        Navigator.pop(context);
      }
    } else {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result), backgroundColor: Colors.redAccent)
        );
      }
    }
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("StudyTrack Kayıt")),
     
      
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_add, size: 80, color: Colors.indigo),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController, 
                  decoration: const InputDecoration(labelText: "Ad Soyad", border: OutlineInputBorder())
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _emailController, 
                  decoration: const InputDecoration(labelText: "E-posta", border: OutlineInputBorder())
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _passwordController, 
                  decoration: const InputDecoration(labelText: "Şifre", border: OutlineInputBorder()), 
                  obscureText: true
                ),
                const SizedBox(height: 30),
                _isLoading 
                  ? const CircularProgressIndicator() 
                  : SizedBox(
                      width: double.infinity, 
                      height: 50,
                      child: ElevatedButton(onPressed: _register, child: const Text("Kayıt Ol")),
                    ),
              ],
            ),
          ),
        ),
      ),
     
    );
  
    
  }
}