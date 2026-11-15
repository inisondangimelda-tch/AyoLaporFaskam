import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AyoLaporApp());
}

class AyoLaporApp extends StatelessWidget {
  const AyoLaporApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AyoLaporFaskam',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
      ),
      home: const LaporanPage(),
    );
  }
}

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});
  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  final _judulController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _lokasiController = TextEditingController();
  final _pelaporController = TextEditingController();
  String _kategori = 'Fasilitas Lain';
  File? _foto;
  final ImagePicker _picker = ImagePicker();
  bool _loading = false;

  final List<String> _kategoriList = [
    'Fasilitas Lain',
    'AC',
    'Listrik',
    'Toilet',
    'Meja Kursi',
    'Proyektor',
    'Kebersihan',
  ];

  Future<void> _pilihFoto() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Ambil dari Kamera'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? foto =
                    await _picker.pickImage(source: ImageSource.camera, imageQuality: 60);
                if (foto != null) {
                  setState(() => _foto = File(foto.path));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih dari Galeri'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? foto =
                    await _picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
                if (foto != null) {
                  setState(() => _foto = File(foto.path));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _kirimLaporan() async {
    if (_judulController.text.isEmpty ||
        _deskripsiController.text.isEmpty ||
        _lokasiController.text.isEmpty ||
        _pelaporController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi semua data dulu ya!')),
      );
      return;
    }
    setState(() => _loading = true);
    String? fotoBase64;
    if (_foto != null) {
      final bytes = await _foto!.readAsBytes();
      fotoBase64 = base64Encode(bytes);
    }
    await FirebaseFirestore.instance.collection('laporan').add({
      'judul': _judulController.text,
      'deskripsi': _deskripsiController.text,
      'kategori': _kategori,
      'lokasi': _lokasiController.text,
      'pelapor': _pelaporController.text,
      'status': 'Menunggu',
      'tanggal': DateTime.now().toString(),
      'foto': fotoBase64 ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
    _judulController.clear();
    _deskripsiController.clear();
    _lokasiController.clear();
    _pelaporController.clear();
    setState(() {
      _foto = null;
      _loading = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan berhasil dikirim!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AyoLaporFaskam'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Buat Laporan Baru',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _judulController,
              decoration: const InputDecoration(
                  labelText: 'Judul', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _deskripsiController,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Deskripsi', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _kategori,
              items: _kategoriList
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _kategori = v!),
              decoration: const InputDecoration(
                  labelText: 'Kategori', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lokasiController,
              decoration: const InputDecoration(
                  labelText: 'Lokasi (ex: Gedung SDS 2.1)',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pelaporController,
              decoration: const InputDecoration(
                  labelText: 'Nama + NIM (ex: Sondang Imelda 25781103)',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            // BAGIAN FOTO - INI YANG BARU
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _foto == null
                  ? const Center(child: Text('Belum ada foto'))
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_foto!, fit: BoxFit.cover, width: double.infinity),
                    ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _pilihFoto,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Tambah Foto'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange, foregroundColor: Colors.white),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _kirimLaporan,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('KIRIM LAPORAN', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 24),
            const Text('Daftar Laporan',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('laporan')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Text('Belum ada laporan');
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final fotoStr = data['foto'] as String? ?? '';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (fotoStr.isNotEmpty)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12)),
                              child: Image.memory(
                                base64Decode(fotoStr),
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ListTile(
                            title: Text(data['judul'] ?? ''),
                            subtitle: Text(
                                '${data['deskripsi'] ?? ''}\nLokasi: ${data['lokasi'] ?? ''}\nPelapor: ${data['pelapor'] ?? ''}'),
                            trailing: Chip(label: Text(data['status'] ?? 'Menunggu')),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
