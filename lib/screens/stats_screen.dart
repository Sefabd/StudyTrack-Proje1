import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  // Son 7 günün tarihlerini hesaplar
  DateTime getSevenDaysAgo() {
    DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
  }

  // Haftanın gün isimlerini almak için
  String getDayName(int weekday) {
    const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return days[weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("İstatistikler & Analiz")),
      body: StreamBuilder<DocumentSnapshot>(
        //  KULLANICI HEDEFİNİ ÇEKİYORUZ
        stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());

          var userData = userSnapshot.data!.data() as Map<String, dynamic>;
          // Haftalık hedefi buradan alıyoruz
          int weeklyGoal = userData['weeklyGoalMinutes'] ?? 300;

          return StreamBuilder<QuerySnapshot>(
            //  ÇALIŞMA VERİLERİNİ ÇEKİYORUZ
            stream: FirebaseFirestore.instance
                .collection('study_sessions')
                .where('userId', isEqualTo: user!.uid)
                .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(getSevenDaysAgo()))
                .snapshots(),
            builder: (context, sessionSnapshot) {
              if (sessionSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              var docs = sessionSnapshot.data?.docs ?? [];

              // VERİ ANALİZİ
              Map<int, int> dailyTotals = {}; // Hangi gün kaç dk çalışıldı?
              Map<String, int> lessonTotals = {}; // Hangi ders kaç dk?
              int totalWeeklyMinutes = 0;

              
              DateTime now = DateTime.now();
              for (int i = 0; i < 7; i++) {
                DateTime day = now.subtract(Duration(days: i));
                int dayKey = day.year * 10000 + day.month * 100 + day.day;
                dailyTotals[dayKey] = 0;
              }

              // Verileri doldur
              for (var doc in docs) {
                var data = doc.data() as Map<String, dynamic>;
                int minutes = (data['durationMinutes'] as num).toInt();
                String lesson = data['lesson'] ?? 'Diğer';
                DateTime date = (data['date'] as Timestamp).toDate();
                int dayKey = date.year * 10000 + date.month * 100 + date.day;

                // Günlük toplamı güncelle
                if (dailyTotals.containsKey(dayKey)) {
                  dailyTotals[dayKey] = dailyTotals[dayKey]! + minutes;
                }
                
                // Ders toplamını güncelle
                lessonTotals[lesson] = (lessonTotals[lesson] ?? 0) + minutes;
                
                // Haftalık toplamı güncelle
                totalWeeklyMinutes += minutes;
              }

              // Grafiği düzgün çizmek için listeyi tarihe göre sırala
              var sortedDays = dailyTotals.entries.toList()
                ..sort((a, b) => a.key.compareTo(b.key));

              // Maksimum değeri bul 
              int maxDaily = dailyTotals.values.fold(0, (p, c) => p > c ? p : c);
              if (maxDaily == 0) maxDaily = 60; 

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //  HAFTALIK HEDEF 
                    _buildWeeklyGoalCard(totalWeeklyMinutes, weeklyGoal),
                    
                    const SizedBox(height: 20),
                    const Text("Son 7 Gün Performansı", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),

                    // GRAFİK 
                    Container(
                      height: 200,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: sortedDays.map((entry) {
                          int day = entry.key % 100;
                          int month = (entry.key ~/ 100) % 100;
                          int year = entry.key ~/ 10000;
                          DateTime date = DateTime(year, month, day);
                          
                          double barHeight = (entry.value / maxDaily) * 120; 

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text("${entry.value}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.indigo)),
                              const SizedBox(height: 5),
                              Container(
                                width: 20,
                                height: barHeight == 0 ? 5 : barHeight,
                                decoration: BoxDecoration(
                                  color: entry.value > 0 ? Colors.indigo : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(getDayName(date.weekday), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Text("Ders Bazlı Dağılım", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),

                    //  DERS LİSTESİ 
                    ...lessonTotals.entries.map((entry) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange.shade100,
                            child: const Icon(Icons.book, color: Colors.orange),
                          ),
                          title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                          trailing: Text("${entry.value} dk", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      );
                    }).toList(),
                    
                    if (lessonTotals.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Center(child: Text("Henüz bu hafta çalışma kaydı yok. 📉")),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Haftalık Hedef Kartı 
  Widget _buildWeeklyGoalCard(int current, int goal) {
    
    double percent = (goal == 0 ? 0.0 : current / goal).clamp(0.0, 1.0).toDouble();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.purple.shade400, Colors.purple.shade700]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Haftalık Hedef", style: TextStyle(color: Colors.white, fontSize: 16)),
              Text("$current / $goal dk", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          LinearProgressIndicator(
            value: percent,
            backgroundColor: Colors.white24,
            color: Colors.white,
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
          const SizedBox(height: 10),
          Text(
            percent >= 1.0 ? "Tebrikler! Hedefine ulaştın! 🎉" : "%${(percent * 100).toInt()} tamamlandı, devam et! 🔥",
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}