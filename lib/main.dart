import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDUeR7o1UqUu0XoGQJvLx9PpL2r8QZx0M",
      appId: "1:1029384756:android:abcd1234",
      messagingSenderId: "1029384756",
      projectId: "ayolapor-4c8a9",
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AyoLapor',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;
  final _pages = const [LaporPage(), AdminPage()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.edit_document), label: 'Lapor'),
          BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
        ],
      ),
    );
  }
}

class LaporPage extends StatefulWidget {
  const LaporPage({super.key});
  @override
  State<LaporPage> createState() => _LaporPageState();
}

class _LaporPageState extends State<LaporPage> {
  final _nama = TextEditingController();
  final _npm = TextEditingController();
  final _kelas = TextEditingController();
  final _prodi = TextEditingController();
  final _judul = TextEditingController();
  final _deskripsi = TextEditingController();
  File? _foto;
  bool _loading = false;

  Future<void> _ambilFoto() async {
    final XFile? x = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 70);
    if (x != null) setState(() => _foto = File(x.path));
  }

  Future<void> _kirim() async {
    if (_nama.text.isEmpty || _npm.text.isEmpty || _kelas.text.isEmpty || _prodi.text.isEmpty || _judul.text.isEmpty || _deskripsi.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Isi semua dulu ya beb!')));
      return;
    }
    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance.collection('laporan').add({
        'nama': _nama.text.trim(),
        'npm': _npm.text.trim(),
        'kelas': _kelas.text.trim(),
        'prodi': _prodi.text.trim(),
        'judul': _judul.text.trim(),
        'deskripsi': _deskripsi.text.trim(),
        'status': 'Menunggu',
        'createdAt': FieldValue.serverTimestamp(),
        'adaFoto': _foto != null,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text('BERHASIL! Laporan masuk database!')));
      _nama.clear(); _npm.clear(); _kelas.clear(); _prodi.clear(); _judul.clear(); _deskripsi.clear();
      setState(() => _foto = null);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text('GAGAL: $e')));
    }
    setState(() => _loading = false);
  }

  Widget _input(TextEditingController c, String label, {int maxLines = 1, TextInputType? type}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(controller: c, maxLines: maxLines, keyboardType: type, decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AyoLapor - Buat Laporan'), backgroundColor: Colors.blue, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _input(_nama, 'Nama Lengkap'),
            _input(_npm, 'NPM', type: TextInputType.number),
            _input(_kelas, 'Kelas'),
            _input(_prodi, 'Prodi'),
            _input(_judul, 'Judul Laporan'),
            _input(_deskripsi, 'Deskripsi Laporan', maxLines: 4),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _ambilFoto,
              child: Container(
                height: 150, width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                child: _foto != null ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_foto!, fit: BoxFit.cover)) : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.camera_alt, size: 40, color: Colors.grey), Text('Tap untuk Ambil Foto (Opsional)')]),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _kirim,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                child: Text(_loading ? 'Mengirim...' : 'Kirim Laporan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin - Daftar Laporan'), backgroundColor: Colors.blue, foregroundColor: Colors.white),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('laporan').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('Belum ada laporan'));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(d['judul'] ?? '-'),
                  subtitle: Text('${d['nama'] ?? '-'} | NPM: ${d['npm'] ?? '-'} | ${d['kelas'] ?? '-'} | ${d['prodi'] ?? '-'}\n${d['deskripsi'] ?? ''}\nStatus: ${d['status'] ?? ''}'),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) => FirebaseFirestore.instance.collection('laporan').doc(docs[i].id).update({'status': v}),
                    itemBuilder: (c) => const [PopupMenuItem(value: 'Menunggu', child: Text('Menunggu')), PopupMenuItem(value: 'Diproses', child: Text('Diproses')), PopupMenuItem(value: 'Selesai', child: Text('Selesai'))],
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
