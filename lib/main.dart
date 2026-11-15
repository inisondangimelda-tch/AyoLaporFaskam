import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi Firebase AyoLaporFaskam
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCGqtkVSHK_XJe6iJHBVElEeear1hFik",
      appId: "1:219794824444:web:1abcaf35388cc687e7a7e9",
      messagingSenderId: "219794824444",
      projectId: "ayolaporfaskam",
      authDomain: "ayolaporfaskam.firebaseapp.com",
      storageBucket: "ayolaporfaskam.appspot.com",
    ),
  );
  
  runApp(const AyoLaporApp());
}

class AyoLaporApp extends StatelessWidget {
  const AyoLaporApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ayo Lapor Faskam',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const DaftarLaporanScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DaftarLaporanScreen extends StatelessWidget {
  const DaftarLaporanScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final CollectionReference laporanRef =
        FirebaseFirestore.instance.collection('laporan');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayo Lapor Faskam - Kampus'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: laporanRef.orderBy('tanggal', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.docs;

          if (data.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada laporan kerusakan.\nYuk bikin laporan baru!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              var item = data[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
                child: ListTile(
                  title: Text(
                    item['judul'] ?? 'Tanpa Judul',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Lokasi: ${item['lokasi']}'),
                      Text('Kategori: ${item['kategori']}'),
                      Text('Pelapor: ${item['pelapor']}'),
                      const SizedBox(height: 4),
                      Chip(
                        label: Text(
                          item['status'] ?? 'Menunggu',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        backgroundColor: item['status'] == 'Selesai'
                            ? Colors.green
                            : item['status'] == 'Diproses'
                                ? Colors.orange
                                : Colors.red,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FormLaporanScreen()),
          );
        },
        label: const Text('Buat Laporan'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }
}

class FormLaporanScreen extends StatefulWidget {
  const FormLaporanScreen({Key? key}) : super(key: key);

  @override
  _FormLaporanScreenState createState() => _FormLaporanScreenState();
}

class _FormLaporanScreenState extends State<FormLaporanScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _lokasiController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _pelaporController = TextEditingController();
  String _kategoriPilihan = 'Kelistrikan';

  final List<String> _kategoriList = ['Kelistrikan', 'Meubelair', 'Plumbing', 'Fasilitas Lain'];

  void _kirimLaporan() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('laporan').add({
          'judul': _judulController.text,
          'lokasi': _lokasiController.text,
          'kategori': _kategoriPilihan,
          'deskripsi': _deskripsiController.text,
          'pelapor': _pelaporController.text,
          'status': 'Menunggu',
          'tanggal': FieldValue.serverTimestamp(),
        });

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Laporan berhasil dikirim ke database!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Laporan Kerusakan'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _judulController,
                decoration: const InputDecoration(labelText: 'Judul Kerusakan (Cth: AC Bocor)'),
                validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
              ),
              TextFormField(
                controller: _lokasiController,
                decoration: const InputDecoration(labelText: 'Lokasi (Cth: Gedung A Lt. 2)'),
                validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
              ),
              DropdownButtonFormField<String>(
                value: _kategoriPilihan,
                items: _kategoriList.map((kategori) {
                  return DropdownMenuItem(value: kategori, child: Text(kategori));
                }).toList(),
                onChanged: (val) => setState(() => _kategoriPilihan = val!),
                decoration: const InputDecoration(labelText: 'Kategori Fasilitas'),
              ),
              TextFormField(
                controller: _deskripsiController,
                decoration: const InputDecoration(labelText: 'Deskripsi Detail'),
                maxLines: 3,
                validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
              ),
              TextFormField(
                controller: _pelaporController,
                decoration: const InputDecoration(labelText: 'Nama / Identitas Pelapor'),
                validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _kirimLaporan,
                child: const Text('Kirim Laporan Sekarang', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}