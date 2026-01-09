import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'timer_screen.dart';
import 'stats_screen.dart';
import 'community_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  // Bugünün başlangıç zamanı
  DateTime getStartOfToday() {
    DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("StudyTrack"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          )
        ],
      ),
      // 1. KATMAN: KULLANICI BİLGİLERİNİ ÇEKİYOR
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.hasError) return const Center(child: Text("Hata oluştu"));
          if (userSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          var userData = userSnapshot.data!.data() as Map<String, dynamic>;
          String name = userData['name'] ?? 'Öğrenci';
          
          // GÜNLÜK VE HAFTALIK HEDEFİ ÇEKİYORUZ
          int dailyGoal = userData['dailyGoalMinutes'] ?? 60; 
          

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Merhaba, $name 👋", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                
                // 2. KATMAN: BUGÜNKÜ ÇALIŞMALARI ÇEKİP TOPLUYORUZ
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('study_sessions')
                      .where('userId', isEqualTo: user!.uid)
                      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(getStartOfToday()))
                      .snapshots(),
                  builder: (context, sessionSnapshot) {
                    
                    int workedToday = 0;

                    if (sessionSnapshot.hasData) {
                      var docs = sessionSnapshot.data!.docs;
                      for (var doc in docs) {
                        workedToday += (doc['durationMinutes'] as num).toInt();
                      }
                    }
                    
                    // Yüzde Hesabı 
                    double percent = (dailyGoal == 0 ? 0 : workedToday / dailyGoal);
                    if (percent > 1.0) percent = 1.0; 

                    // ÖZET KARTI 
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.indigo.shade500, Colors.indigo.shade800],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                      ),
                      child: Row(
                        children: [
                          // SOL TARAFTAKİ HALKA
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 80,
                                height: 80,
                                child: CircularProgressIndicator(
                                  value: percent,
                                  strokeWidth: 8,
                                  color: Colors.white,
                                  backgroundColor: Colors.white24,
                                ),
                              ),
                              Text(
                                "%${(percent * 100).toInt()}",
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ],
                          ),
                          const SizedBox(width: 20),
                          
                          // SAĞ TARAFTAKİ BİLGİLER
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Bugünkü Çalışman", style: TextStyle(color: Colors.white70, fontSize: 14)),
                                const SizedBox(height: 5),
                                Text("$workedToday dk", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                // HEDEF BİLGİSİ KUTUSU
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.flag, color: Colors.white, size: 14),
                                      const SizedBox(width: 5),
                                      Text(
                                        "Hedef: $dailyGoal dk", 
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 30),
                const Text("Hızlı Menü", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                // Menü Butonları 
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    children: [
                      _buildMenuCard(icon: Icons.timer, title: "Çalışmaya Başla", color: Colors.orange, onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const TimerScreen()));
                      }),
                      _buildMenuCard(icon: Icons.bar_chart, title: "İstatistikler", color: Colors.purple, onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const StatsScreen()));
                      }),
                      _buildMenuCard(icon: Icons.group, title: "Topluluk", color: Colors.blue, onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const CommunityScreen()));
                      }),
                      _buildMenuCard(icon: Icons.person, title: "Profil", color: Colors.teal, onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
                      }),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuCard({required IconData icon, required String title, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}