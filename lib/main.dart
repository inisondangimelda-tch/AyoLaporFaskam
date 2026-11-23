import 'dart:io';
import 'dart:convert';
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
      debugShowCheckedModeBanner: false,
      title: 'Ayo Lapor Faskam',
      theme: ThemeData(primarySwatch: Colors.teal, useMaterial3: true),
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
  // ===== FORM =====
  final _judulController = TextEditingController();
  final _deskripsiController = TextEditingController();
  String _kategori = 'Fasilitas';
  String? _base64Image;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (picked != null) {
      final bytes = await File(picked.path).readAsBytes();
      setState(() => _base64Image = base64Encode(bytes));
    }
  }

  Future<void> _kirimLaporan() async {
    if (_judulController.text.isEmpty || _deskripsiController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Judul & Deskripsi wajib diisi')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('laporan').add({
        'judul': _judulController.text,
        'deskripsi': _deskripsiController.text,
        'kategori': _kategori,
        'status': 'Menunggu',
        'nama': 'Sondang Imelda',
        'waktu': FieldValue.serverTimestamp(),
        'foto': _base64Image ?? '',
      });
      _judulController.clear();
      _deskripsiController.clear();
      setState(() => _base64Image = null);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Laporan berhasil dikirim!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
    setState(() => _isLoading = false);
  }

  // ===== UBAH STATUS & HAPUS =====
  Future<void> _ubahStatus(String docId, String statusBaru) async {
    await FirebaseFirestore.instance.collection('laporan').doc(docId).update({'status': statusBaru});
  }

  Future<void> _hapusLaporan(String docId, String judul) async {
    bool? yakin = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Laporan?'),
        content: Text('Yakin mau hapus "$judul"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (yakin == true) {
      await FirebaseFirestore.instance.collection('laporan').doc(docId).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayo Lapor Faskam'), backgroundColor: Colors.teal, foregroundColor: Colors.white),
      body: Column(
        children: [
          // --- FORM INPUT ---
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(controller: _judulController, decoration: const InputDecoration(labelText: 'Judul Laporan', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(controller: _deskripsiController, decoration: const InputDecoration(labelText: 'Deskripsi', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                Row(
                  children: [
                    DropdownButton<String>(
                      value: _kategori,
                      items: ['Fasilitas', 'Kebersihan', 'Keamanan', 'Lainnya'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _kategori = v!),
                    ),
                    const Spacer(),
                    TextButton.icon(onPressed: _pickImage, icon: const Icon(Icons.photo), label: Text(_base64Image == null ? 'Pilih Foto' : 'Foto Terpilih')),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _kirimLaporan,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    child: Text(_isLoading ? 'Mengirim...' : 'Kirim Laporan', style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          // --- LIST LAPORAN DARI FIREBASE ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('laporan').orderBy('waktu', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('Belum ada laporan'));

                final docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final item = doc.data() as Map<String, dynamic>;
                    String status = item['status'] ?? 'Menunggu';
                    Color statusColor = status == 'Selesai' ? Colors.green : status == 'Diproses' ? Colors.orange : Colors.grey;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(item['judul'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(20)),
                                  child: Text(status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(item['deskripsi'] ?? ''),
                            const SizedBox(height: 4),
                            Text('Kategori: ${item['kategori'] ?? '-'} | Oleh: ${item['nama'] ?? '-'}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 10),
                            // TOMBOL SELESAI & LAINNYA
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () => _ubahStatus(doc.id, 'Diproses'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                                  child: const Text('Diproses', style: TextStyle(color: Colors.white)),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () => _ubahStatus(doc.id, 'Selesai'),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                  child: const Text('Selesai', style: TextStyle(color: Colors.white)),
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: () => _hapusLaporan(doc.id, item['judul'] ?? ''),
                                  icon: const Icon(Icons.delete, color: Colors.red),
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
          ),
        ],
      ),
    );
  }
}
