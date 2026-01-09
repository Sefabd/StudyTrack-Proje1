import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  Timer? _timer;
  int _seconds = 0;
  bool _isRunning = false;
  String? _selectedLesson; 

  // Ders listesi 
  final List<String> _lessons = ['Matematik', 'Fizik', 'Yazılım', 'İngilizce', 'Tarih', 'Diğer'];

  // Zamanı 00:00:00 formatına çeviren fonksiyon
  String _formatTime(int seconds) {
    int sec = seconds % 60;
    int min = (seconds ~/ 60) % 60;
    int hrs = seconds ~/ 3600;
    return "${hrs.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
  }

  void _startTimer() {
    if (_isRunning) return;
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _seconds++);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _finishSession() {
    _stopTimer();
    if (_seconds < 60) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("1 dakikadan az çalışmalar kaydedilmez!")));
      return;
    }
    _showSaveDialog();
  }

  // Kaydetme Penceresi
  void _showSaveDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Çalışmayı Kaydet"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Süre: ${_formatTime(_seconds)}"),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedLesson,
                hint: const Text("Ders Seçiniz"),
                items: _lessons.map((lesson) => DropdownMenuItem(value: lesson, child: Text(lesson))).toList(),
                onChanged: (val) => setState(() => _selectedLesson = val),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
            ElevatedButton(
              onPressed: () async {
                if (_selectedLesson == null) return;
                await _saveToFirebase();
                if (mounted) Navigator.pop(context); // Dialog'u kapat
                if (mounted) Navigator.pop(context); // Ana Ekrana dön
              },
              child: const Text("KAYDET"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveToFirebase() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 1. Oturumu 'study_sessions' koleksiyonuna ekle
      await FirebaseFirestore.instance.collection('study_sessions').add({
        'userId': user.uid,
        'lesson': _selectedLesson,
        'durationMinutes': (_seconds / 60).round(), 
        'date': Timestamp.now(),
      });

      // 2. İstatistik güncelleme
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Çalışma başarıyla kaydedildi! 🎉")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Zamanlayıcı")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Zaman Göstergesi
          Text(
            _formatTime(_seconds),
            style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: Colors.indigo),
          ),
          const SizedBox(height: 50),
          
          // Butonlar
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Başlat / Durdur Butonu
              FloatingActionButton.large(
                heroTag: "btn1",
                backgroundColor: _isRunning ? Colors.orange : Colors.green,
                onPressed: _isRunning ? _stopTimer : _startTimer,
                child: Icon(_isRunning ? Icons.pause : Icons.play_arrow, size: 40, color: Colors.white),
              ),
              const SizedBox(width: 20),
              // Bitir Butonu
              if (_seconds > 0) 
                FloatingActionButton(
                  heroTag: "btn2",
                  backgroundColor: Colors.red,
                  onPressed: _finishSession,
                  child: const Icon(Icons.stop, color: Colors.white),
                ),
            ],
          ),
          const SizedBox(height: 20),
          
          TextButton.icon(
            onPressed: _showManualEntryDialog,
            icon: const Icon(Icons.edit_calendar),
            label: const Text("Manuel Ekle"),
          ),
          const SizedBox(height: 20),
          // --------------------------
          Text(_isRunning ? "Çalışılıyor..." : "Hazır mısın?", style: const TextStyle(fontSize: 18, color: Colors.grey)),
        ],
      ),
    );
  }

  // MANUEL EKLEME PENCERESİ 
  void _showManualEntryDialog() {
    TextEditingController durationController = TextEditingController();
    String? localSelectedLesson;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Manuel Aktivite Ekle"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Sayacı açmayı unuttun mu? Sorun değil, buradan ekle."),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: localSelectedLesson,
                hint: const Text("Ders Seçiniz"),
                items: _lessons.map((lesson) => DropdownMenuItem(value: lesson, child: Text(lesson))).toList(),
                onChanged: (val) => localSelectedLesson = val,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Süre (Dakika)", border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
            ElevatedButton(
              onPressed: () async {
                if (localSelectedLesson == null || durationController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen ders ve süre giriniz."), backgroundColor: Colors.redAccent));
                  return;
                }

                int minutes = int.tryParse(durationController.text) ?? 0;
                if (minutes <= 0) return;

                User? user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await FirebaseFirestore.instance.collection('study_sessions').add({
                    'userId': user.uid,
                    'lesson': localSelectedLesson,
                    'durationMinutes': minutes,
                    'date': Timestamp.now(),
                  });
                  if (!mounted) return;
                  if (mounted) {
                    Navigator.pop(context); // Dialog kapat
                    Navigator.pop(context); // Ana Ekrana dön
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Aktivite eklendi! 🎉"), backgroundColor: Colors.green));
                  }
                }
              },
              child: const Text("EKLE"),
            ),
          ],
        );
      },
    );
  }
}