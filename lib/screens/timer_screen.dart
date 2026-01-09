import 'dart:async';
import 'dart:ui'; 
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

  final List<String> _lessons = ['Matematik', 'Fizik', 'Yazılım', 'İngilizce', 'Tarih', 'Diğer'];

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("1 dakikadan az çalışmalar kaydedilmez!")),
        );
      }
      return;
    }
    _showSaveDialog();
  }

  void _showSaveDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Çalışmayı Kaydet"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Süre: ${_formatTime(_seconds)}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedLesson,
                hint: const Text("Ders Seçiniz"),
                items: _lessons.map((lesson) => DropdownMenuItem(value: lesson, child: Text(lesson))).toList(),
                onChanged: (val) => setState(() => _selectedLesson = val),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("İptal"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_selectedLesson == null) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text("Lütfen ders seçin")),
                  );
                  return;
                }

                await _saveToFirebase();

                if (!mounted) return;
                Navigator.pop(dialogContext);
                if (!mounted) return;
                Navigator.pop(context);
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
      await FirebaseFirestore.instance.collection('study_sessions').add({
        'userId': user.uid,
        'lesson': _selectedLesson,
        'durationMinutes': (_seconds / 60).round(),
        'date': Timestamp.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Çalışma başarıyla kaydedildi! 🎉"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
      }
    }
  }

  void _showManualEntryDialog() {
    TextEditingController durationController = TextEditingController();
    String? localSelectedLesson;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          scrollable: true,
          title: const Text("Manuel Aktivite Ekle"),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Sayacı açmayı unuttun mu? Sorun değil."),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      value: localSelectedLesson,
                      hint: const Text("Ders Seçiniz"),
                      items: _lessons.map((lesson) => DropdownMenuItem(value: lesson, child: Text(lesson))).toList(),
                      onChanged: (val) => setDialogState(() => localSelectedLesson = val),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: durationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Süre (Dakika)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("İptal"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (localSelectedLesson == null || durationController.text.isEmpty) return;
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
                  Navigator.pop(dialogContext);
                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Aktivite eklendi! 🎉"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text("EKLE"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Zamanlayıcı"),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _formatTime(_seconds),
                  style: const TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(height: 50),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton.large(
                    heroTag: "btn1",
                    backgroundColor: _isRunning ? Colors.orange : Colors.green,
                    onPressed: _isRunning ? _stopTimer : _startTimer,
                    child: Icon(_isRunning ? Icons.pause : Icons.play_arrow, size: 40, color: Colors.white),
                  ),
                  const SizedBox(width: 20),
                  if (_seconds > 0)
                    FloatingActionButton(
                      heroTag: "btn2",
                      backgroundColor: Colors.red,
                      onPressed: _finishSession,
                      child: const Icon(Icons.stop, color: Colors.white),
                    ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              OutlinedButton.icon(
                onPressed: _showManualEntryDialog,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  side: const BorderSide(color: Colors.indigo),
                ),
                icon: const Icon(Icons.edit_calendar, color: Colors.indigo),
                label: const Text("Manuel Aktivite Ekle", style: TextStyle(color: Colors.indigo)),
              ),
              
              const SizedBox(height: 20),
              Text(
                _isRunning ? "Çalışılıyor..." : "Hazır mısın?",
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
