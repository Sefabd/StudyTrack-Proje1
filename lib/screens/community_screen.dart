import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _messageController = TextEditingController();

  // DURUM İKONLARI 
  final List<Map<String, String>> _activityIcons = [
    {
      'icon': '📚',
      'label': 'Ders',
      'image': 'https://cdn-icons-png.flaticon.com/512/2232/2232688.png',
    }, 
    {
      'icon': '☕',
      'label': 'Mola',
      'image': 'https://cdn-icons-png.flaticon.com/512/2935/2935307.png',
    }, 
    {
      'icon': '🎯',
      'label': 'Hedef',
      'image': 'https://cdn-icons-png.flaticon.com/512/2481/2481079.png',
    }, 
    {
      'icon': '📝',
      'label': 'Sınav',
      'image': 'https://cdn-icons-png.flaticon.com/512/2641/2641409.png',
    }, 
    {
      'icon': '💪',
      'label': 'Spor',
      'image': 'https://cdn-icons-png.flaticon.com/512/2964/2964514.png',
    }, 
    {
      'icon': '🔥',
      'label': 'Fokus',
      'image': 'https://cdn-icons-png.flaticon.com/512/426/426833.png',
    }, 
  ];

  int? _selectedIconIndex; // Seçilen ikonun sırası

  // TARİH FORMATLAMA 
  
  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "";
    DateTime d = timestamp.toDate();
    String day = d.day.toString().padLeft(2, '0');
    String month = d.month.toString().padLeft(2, '0');
    String year = d.year.toString();
    String hour = d.hour.toString().padLeft(2, '0');
    String minute = d.minute.toString().padLeft(2, '0');
    return "$day.$month.$year $hour:$minute";
  }

  // PAYLAŞIM GÖNDERME 
  void _sharePost() async {
    if (_messageController.text.isEmpty && _selectedIconIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lütfen bir mesaj yazın veya durum seçin."),
        ),
      );
      return;
    }

    try {
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      String userName = userDoc['name'] ?? 'Öğrenci';
      String userAvatar = userDoc['profilePic'] ?? '';

      await FirebaseFirestore.instance.collection('posts').add({
        'userId': user!.uid,
        'userName': userName,
        'userAvatar': userAvatar,
        'message': _messageController.text.trim(),
        'date': Timestamp.now(),
        'likes': 0,
        'likedBy': [],
        'comments': [],
        'activityImage': _selectedIconIndex != null
            ? _activityIcons[_selectedIconIndex!]['image']
            : null,
        'activityLabel': _selectedIconIndex != null
            ? _activityIcons[_selectedIconIndex!]['label']
            : null,
      });

      _messageController.clear();
      setState(() => _selectedIconIndex = null);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
  }

  // YENİ GÖNDERİ PENCERESİ 
  void _showAddPostSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Ne durumdasın? ",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _messageController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText:
                          "Bugün hedeflerini tamamladın mı? Arkadaşlarına seslen...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Bir durum ikonu ekle (İsteğe bağlı):",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  // İkon Seçici
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _activityIcons.length,
                      itemBuilder: (context, index) {
                        bool isSelected = _selectedIconIndex == index;
                        return GestureDetector(
                          onTap: () {
                            setSheetState(() {
                              _selectedIconIndex = isSelected ? null : index;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 15),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.indigo.shade100
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                              border: isSelected
                                  ? Border.all(color: Colors.indigo, width: 2)
                                  : null,
                            ),
                            child: Image.network(
                              _activityIcons[index]['image']!,
                              width: 30,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _sharePost,
                      icon: const Icon(Icons.send),
                      label: const Text("Paylaş"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // BEĞENİ İŞLEMİ 
  void _toggleLike(String docId, List likedBy) {
    if (likedBy.contains(user!.uid)) {
      FirebaseFirestore.instance.collection('posts').doc(docId).update({
        'likes': FieldValue.increment(-1),
        'likedBy': FieldValue.arrayRemove([user!.uid]),
      });
    } else {
      FirebaseFirestore.instance.collection('posts').doc(docId).update({
        'likes': FieldValue.increment(1),
        'likedBy': FieldValue.arrayUnion([user!.uid]),
      });
    }
  }

  // YORUM YAPMA PENCERESİ 
  void _showCommentDialog(DocumentSnapshot postDoc) {
    TextEditingController commentController = TextEditingController();

    //  VERİ ÇEKME 
    List comments = [];
    try {
      comments = postDoc.get('comments');
    } catch (e) {
      comments = [];
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                "Yorumlar",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const Divider(),
              Expanded(
                child: comments.isEmpty
                    ? const Center(
                        child: Text("Henüz yorum yok. İlk sen yaz!"),
                      )
                    : ListView.builder(
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          var c = comments[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(c['avatar']),
                              radius: 15,
                            ),
                            title: Text(
                              c['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            subtitle: Text(c['text']),
                            // Yorum tarihi
                            trailing: Text(
                              _formatDate(
                                c['date'],
                              ).split(' ')[1], // Sadece saati al
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        decoration: const InputDecoration(
                          hintText: "Bir yorum yaz...",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.indigo),
                      onPressed: () async {
                        if (commentController.text.isNotEmpty) {
                          var userDoc = await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user!.uid)
                              .get();
                          Map<String, dynamic> newComment = {
                            'userId': user!.uid,
                            'name': userDoc['name'],
                            'avatar': userDoc['profilePic'],
                            'text': commentController.text.trim(),
                            'date': Timestamp.now(),
                          };

                          await FirebaseFirestore.instance
                              .collection('posts')
                              .doc(postDoc.id)
                              .update({
                                'comments': FieldValue.arrayUnion([newComment]),
                              });

                          if (mounted) Navigator.pop(context);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Topluluk Akışı 🌍")),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPostSheet,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.forum_outlined, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text(
                    "Henüz kimse paylaşım yapmamış.\nİlk sen ol! ",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var post = snapshot.data!.docs[index];
              var data = post.data() as Map<String, dynamic>;

              List likedBy = data['likedBy'] ?? [];
              bool isLiked = likedBy.contains(user!.uid);

              // Yorum sayısını al
              List comments = [];
              try {
                comments = data['comments'];
              } catch (e) {
                comments = [];
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Üst Kısım: Profil + İsim
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(
                              data['userAvatar'] ??
                                  'https://ui-avatars.com/api/?name=${data['userName']}',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['userName'] ?? 'Anonim',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              
                              Text(
                                _formatDate(data['date']),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          if (data['activityImage'] != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.indigo.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Image.network(
                                    data['activityImage'],
                                    width: 20,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    data['activityLabel'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.indigo.shade800,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Text(
                        data['message'],
                        style: const TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 15),

                      const Divider(),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          TextButton.icon(
                            onPressed: () => _toggleLike(post.id, likedBy),
                            icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : Colors.grey,
                            ),
                            label: Text(
                              "${data['likes'] ?? 0} Beğeni",
                              style: TextStyle(
                                color: isLiked ? Colors.red : Colors.grey,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _showCommentDialog(post),
                            icon: const Icon(Icons.comment, color: Colors.grey),
                            label: Text(
                              "${comments.length} Yorum",
                              style: const TextStyle(color: Colors.grey),
                            ),
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
}
