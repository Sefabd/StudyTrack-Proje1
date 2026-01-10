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
  
  // Avatar Listesi 
  final List<String> _avatars = [
    'https://cdn-icons-png.flaticon.com/512/4140/4140048.png',
    'https://cdn-icons-png.flaticon.com/512/4140/4140047.png',
    'https://cdn-icons-png.flaticon.com/512/4140/4140037.png',
    'https://cdn-icons-png.flaticon.com/512/4140/4140051.png',
    'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
    'https://cdn-icons-png.flaticon.com/512/3135/3135768.png',
  ];

 
  // Veritabanı güncelleme işini tek yerden yönetir
  Future<void> _updateUser(Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bilgiler güncellendi!"), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      debugPrint("Hata: $e");
    }
  }

  // İsim, Bölüm, Günlük Hedef, Haftalık Hedef... Hepsi bu fonksiyonu kullanır.
  void _showEditDialog({
    required String title, 
    required String currentValue, 
    required Function(String) onSave,
    bool isNumber = false // Sayısal klavye açılsın mı?
  }) {
    TextEditingController controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            hintText: "Yeni değer giriniz...",
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onSave(controller.text.trim()); // Kaydetme fonksiyonunu tetikle
                Navigator.pop(ctx);
              }
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }

  // Avatar Seçimi
  void _showAvatarSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        height: 350,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("Avatar Seç", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10),
                itemCount: _avatars.length,
                itemBuilder: (ctx, i) => InkWell(
                  onTap: () {
                    _updateUser({'profilePic': _avatars[i]});
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
                    child: Image.network(_avatars[i]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          var data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          
          // Verileri Çekme
          String name = data['name'] ?? 'Kullanıcı';
          String email = data['email'] ?? user?.email ?? '';
          String dept = data['department'] ?? 'Bölüm Girilmedi';
          String pic = data['profilePic'] ?? _avatars.last;
          int daily = data['dailyGoalMinutes'] ?? 60;
          int weekly = data['weeklyGoalMinutes'] ?? 300;

          return Column(
            children: [
              //  ÜST TASARIM 
              Container(
                padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1B2E), 
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                        const Text("Profilim", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.redAccent), 
                          onPressed: () async {
                            await AuthService().signOut();
                            if(mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                          }
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(radius: 50, backgroundImage: NetworkImage(pic), backgroundColor: Colors.white),
                        InkWell(
                          onTap: _showAvatarSheet,
                          child: const CircleAvatar(radius: 15, backgroundColor: Colors.redAccent, child: Icon(Icons.edit, size: 16, color: Colors.white)),
                        )
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _showEditDialog(title: "İsim Değiştir", currentValue: name, onSave: (val) => _updateUser({'name': val})),
                          child: const Icon(Icons.edit, color: Colors.white70, size: 16),
                        )
                      ],
                    ),
                    Text(email, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  ],
                ),
              ),

              // KARTLAR LİSTESİ 
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Günlük Hedef Kartı 
                    _buildCard(
                      icon: Icons.timer, 
                      title: "Günlük Hedef", 
                      value: "$daily dk", 
                      onEdit: () => _showEditDialog(
                        title: "Günlük Hedef (dk)", 
                        currentValue: daily.toString(), 
                        isNumber: true,
                        onSave: (val) => _updateUser({'dailyGoalMinutes': int.tryParse(val) ?? daily})
                      )
                    ),

                    // Haftalık Hedef Kartı 
                    _buildCard(
                      icon: Icons.bar_chart, 
                      title: "Haftalık Hedef", 
                      value: "$weekly dk", 
                      onEdit: () => _showEditDialog(
                        title: "Haftalık Hedef (dk)", 
                        currentValue: weekly.toString(), 
                        isNumber: true,
                        onSave: (val) => _updateUser({'weeklyGoalMinutes': int.tryParse(val) ?? weekly})
                      )
                    ),

                    // Bölüm/Sınıf Kartı
                    _buildCard(
                      icon: Icons.school, 
                      title: "Bölüm / Sınıf", 
                      value: dept, 
                      onEdit: () => _showEditDialog(
                        title: "Bölüm / Sınıf", 
                        currentValue: dept, 
                        onSave: (val) => _updateUser({'department': val})
                      )
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  //  Kart Tasarımı Widget'ı
  Widget _buildCard({required IconData icon, required String title, required String value, required VoidCallback onEdit}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)]),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: const Color(0xFF1A1B2E))),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            const SizedBox(width: 10),
            IconButton(icon: const Icon(Icons.edit, size: 18, color: Colors.redAccent), onPressed: onEdit),
          ],
        ),
      ),
    );
  }
}
