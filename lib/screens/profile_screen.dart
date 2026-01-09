import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _nameController = TextEditingController();

  // HAZIR AVATAR LİSTESİ 
  final List<String> _avatarOptions = [
    'https://cdn-icons-png.flaticon.com/512/4140/4140048.png',
    'https://cdn-icons-png.flaticon.com/512/4140/4140047.png',
    'https://cdn-icons-png.flaticon.com/512/4140/4140037.png',
    'https://cdn-icons-png.flaticon.com/512/4140/4140051.png',
    'https://cdn-icons-png.flaticon.com/512/4140/4140040.png',
    'https://cdn-icons-png.flaticon.com/512/4140/4140039.png',
    'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
    'https://cdn-icons-png.flaticon.com/512/3135/3135768.png',
  ];

  // AVATAR SEÇME 
  void _showAvatarSelectionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 400,
          child: Column(
            children: [
              const Text("Bir Avatar Seç", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _avatarOptions.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _updateProfilePic(_avatarOptions[index]),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Image.network(_avatarOptions[index]),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  //  SEÇİLEN AVATARI KAYDETME 
  Future<void> _updateProfilePic(String url) async {
    Navigator.pop(context);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'profilePic': url,
        'profilePicBase64': FieldValue.delete(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil resmi güncellendi! "), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
      }
    }
  }

  // İsim Güncelleme Penceresi
  void _showEditProfileDialog(String currentName) {
    _nameController.text = currentName;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Profili Düzenle"),
          content: TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: "Ad Soyad", border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
            ElevatedButton(
              onPressed: () async {
                if (_nameController.text.isNotEmpty) {
                  await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
                    'name': _nameController.text.trim(),
                  });
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text("Kaydet"),
            ),
          ],
        );
      },
    );
  }
  
  //  HEDEF GÜNCELLEME 
  void _showEditGoalDialog(int currentDaily, int currentWeekly) {
    TextEditingController dailyController = TextEditingController(text: currentDaily.toString());
    TextEditingController weeklyController = TextEditingController(text: currentWeekly.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Hedef Ayarları"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dailyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Günlük Hedef (dk)", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: weeklyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Haftalık Hedef (dk)", border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
            ElevatedButton(
              onPressed: () async {
                int? newDaily = int.tryParse(dailyController.text);
                int? newWeekly = int.tryParse(weeklyController.text);

                if (newDaily != null && newWeekly != null && newDaily > 0 && newWeekly > 0) {
                  
                  await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
                    'dailyGoalMinutes': newDaily,
                    'weeklyGoalMinutes': newWeekly,
                  });
                  if (mounted) Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hedefler güncellendi! "), backgroundColor: Colors.green));
                }
              },
              child: const Text("Kaydet"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profilim")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Hata oluştu"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          var data = snapshot.data!.data() as Map<String, dynamic>;
          String name = data['name'] ?? 'Öğrenci';
          String email = data['email'] ?? '';
          
          // Günlük ve Haftalık Hedefleri çek
          int dailyGoal = data['dailyGoalMinutes'] ?? 60;
          int weeklyGoal = data['weeklyGoalMinutes'] ?? 300;
          
          String profilePic = data['profilePic'] ?? 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png';

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 30),
                
                // PROFİL RESMİ ALANI 
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.indigo.shade100,
                      backgroundImage: NetworkImage(profilePic),
                    ),
                    InkWell(
                      onTap: _showAvatarSelectionSheet,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Colors.indigo, shape: BoxShape.circle),
                        child: const Icon(Icons.edit, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 15),
                Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text(email, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),
                
                ElevatedButton.icon(
                  onPressed: () => _showEditProfileDialog(name),
                  icon: const Icon(Icons.edit),
                  label: const Text("İsmi Düzenle"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 30),
                const Divider(),
                
                // Ayarlar Listesi
                ListTile(
                  leading: const Icon(Icons.track_changes, color: Colors.indigo),
                  // Hedefleri göster 
                  title: Text("Hedefler: Günlük $dailyGoal / Haftalık $weeklyGoal dk"),
                  trailing: const Icon(Icons.edit, size: 16),
                  
                  onTap: () => _showEditGoalDialog(dailyGoal, weeklyGoal),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text("Çıkış Yap", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  onTap: () async {
                    await AuthService().signOut();
                    if (!mounted) return;
                    if (mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}