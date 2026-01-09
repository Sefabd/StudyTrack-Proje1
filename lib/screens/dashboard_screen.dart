import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'timer_screen.dart';
import 'stats_screen.dart';
import 'community_screen.dart';
import 'profile_screen.dart';


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
      backgroundColor: const Color(0xFFF5F7FA), 
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.hasError) return const Center(child: Text("Hata oluştu"));
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          var userData = userSnapshot.data!.data() as Map<String, dynamic>;
          String name = userData['name'] ?? 'Öğrenci';
          int dailyGoal = userData['dailyGoalMinutes'] ?? 60;

          // BUGÜNKÜ ÇALIŞMALARI HESAPLA
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('study_sessions')
                .where('userId', isEqualTo: user!.uid)
                .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(getStartOfToday()))
                .snapshots(),
            builder: (context, sessionSnapshot) {
              int workedToday = 0;
              if (sessionSnapshot.hasData) {
                for (var doc in sessionSnapshot.data!.docs) {
                  workedToday += (doc['durationMinutes'] as num).toInt();
                }
              }

              // Yüzde Hesabı
              double percent = (dailyGoal == 0 ? 0 : workedToday / dailyGoal);
              if (percent > 1.0) percent = 1.0;

              return SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- 1. ÜST BAŞLIK (HEADER) ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "Selam, $name",
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A1A2E),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text("👋", style: TextStyle(fontSize: 24)),
                                ],
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                "Bugün hedeflerini parçala!",
                                style: TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                            ],
                          ),
                          // Profil Fotoğrafı (Avatar)
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
                            child: CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.blue.shade100,
                              backgroundImage: const NetworkImage("https://cdn-icons-png.flaticon.com/512/4140/4140048.png"), 
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // --- 2. HEDEF KARTI 
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A2E), 
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1A1A2E).withOpacity(0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Günlük Hedef",
                                  style: TextStyle(color: Colors.white70, fontSize: 16),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.emoji_events, color: Color(0xFFFFD369), size: 20), 
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            
                            // Sayılar
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "$workedToday",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0, left: 5),
                                  child: Text(
                                    "/ $dailyGoal dk",
                                    style: const TextStyle(color: Colors.white38, fontSize: 18),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 20),

                            // Progress Bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: percent,
                                minHeight: 8,
                                backgroundColor: Colors.white.withOpacity(0.1),
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE94560)), 
                              ),
                            ),
                            
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                "%${(percent * 100).toInt()} Tamamlandı",
                                style: const TextStyle(color: Color(0xFFE94560), fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),
                      
                      const Text(
                        "Menü",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
                      ),
                      
                      const SizedBox(height: 15),

                      //  3. MENÜ GRİD 
                      GridView.count(
                        shrinkWrap: true, // ScrollView içinde olduğu için gerekli
                        physics: const NeverScrollableScrollPhysics(), // Scroll çakışmasını önler
                        crossAxisCount: 2,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: 1.1, // Kutuların kareye yakın olması için
                        children: [
                          _buildMenuCard(
                            title: "İstatistikler",
                            icon: Icons.bar_chart_rounded,
                            iconBgColor: const Color(0xFFE0E7FF), 
                            iconColor: const Color(0xFF4338CA), 
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const StatsScreen())),
                          ),
                          _buildMenuCard(
                            title: "Topluluk",
                            icon: Icons.group_rounded,
                            iconBgColor: const Color(0xFFE1F5FE), 
                            iconColor: const Color(0xFF0288D1), 
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CommunityScreen())),
                          ),
                          _buildMenuCard(
                            title: "Profilim",
                            icon: Icons.person_rounded,
                            iconBgColor: const Color(0xFFFFF3E0), 
                            iconColor: const Color(0xFFEF6C00), 
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
                          ),
                          _buildMenuCard(
                            title: "Çalışmaya Başla",
                            icon: Icons.play_arrow_rounded,
                            iconBgColor: const Color(0xFFFFEBEE), 
                            iconColor: const Color(0xFFD32F2F), 
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TimerScreen())),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // YARDIMCI WIDGET: MENÜ KARTI 
  Widget _buildMenuCard({
    required String title,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: iconColor, size: 30),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
