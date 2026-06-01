import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../widgets/badge_poin.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  // bikin state buat halaman profil
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  Map<String, dynamic>? _dataSiswa;
  bool _sedangLoading = true;

  @override
  // pas layar profil pertama kali muncul, langsung narik data
  void initState() {
    super.initState();
    _ambilData();
  }

  // narik data profil pas awal buka
  Future<void> _ambilData() async {
    try {
      final res = await ApiService.getProfil();
      if (res['siswa'] != null) {
        setState(() => _dataSiswa = res['siswa']);
      }
    } catch (e) {}
    setState(() => _sedangLoading = false);
  }

  // nampilin modal buat edit profil
  Future<void> _editProfil() async {
    final ctrlNama = TextEditingController(text: _dataSiswa!['nama']);
    final ctrlKelas = TextEditingController(text: _dataSiswa!['kelas']);
    final ctrlJurusan = TextEditingController(text: _dataSiswa!['jurusan']);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profil'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: ctrlNama, decoration: const InputDecoration(labelText: 'Nama')),
              TextField(controller: ctrlKelas, decoration: const InputDecoration(labelText: 'Kelas')),
              TextField(controller: ctrlJurusan, decoration: const InputDecoration(labelText: 'Jurusan')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simpan')),
        ],
      ),
    );

    if (ok == true) {
      setState(() => _sedangLoading = true);
      try {
        final res = await ApiService.updateProfil(
          nama: ctrlNama.text,
          kelas: ctrlKelas.text,
          jurusan: ctrlJurusan.text,
        );
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['pesan'] ?? 'Berhasil')));
        _ambilData();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Terjadi kesalahan')));
        setState(() => _sedangLoading = false);
      }
    }
  }

  // fungsi buat donlot excel riwayat poin pakai browser
  Future<void> _downloadExcel() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bentar ya, lagi ngebuka link buat unduh filenya...')),
    );
    try {
      // ngambil url yang udah dikasih token
      final url = await ApiService.getExportExcelUrl();
      final uri = Uri.parse(url);
      
      // buka browser bawaan buat donlot
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Yah gagal buka link buat donlot nih')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ada yang error: $e')),
        );
      }
    }
  }

  // buat fungsi logout user nih
  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              await ApiService.hapusToken();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // kalau user pengen hapus akun
  void _hapusAkun() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Akun', style: TextStyle(color: Colors.red)),
        content: const Text('Tindakan ini tidak bisa dibatalkan. Semua data kamu akan terhapus. Yakin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              setState(() => _sedangLoading = true);
              Navigator.pop(ctx);
              try {
                final res = await ApiService.hapusAkun();
                await ApiService.hapusToken();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['pesan'] ?? 'Akun dihapus')));
                  Navigator.pushReplacementNamed(context, '/login');
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menghapus akun')));
                setState(() => _sedangLoading = false);
              }
            },
            child: const Text('Ya, Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  // ngerender keseluruhan tampilan halaman profil
  Widget build(BuildContext context) {
    if (_sedangLoading) return const Center(child: CircularProgressIndicator());
    if (_dataSiswa == null)
      return const Center(child: Text('Gagal muat profil'));

    return Scaffold(
      body: ListView(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF16205E), Color(0xFF4E5C99)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: Text(
                    (_dataSiswa!['nama'] ?? 'S')[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  _dataSiswa!['nama'] ?? '-',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _dataSiswa!['email'] ?? '-',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                BadgePoin(poin: _dataSiswa!['saldo_poin'] ?? 0),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _infoBox(Icons.school, 'Kelas', _dataSiswa!['kelas'] ?? '-'),
                _infoBox(Icons.book, 'Jurusan', _dataSiswa!['jurusan'] ?? '-'),
                const SizedBox(height: 30),
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit Profil'),
                  onTap: _editProfil,
                ),
                ListTile(
                  leading: const Icon(Icons.download, color: Colors.green),
                  title: const Text('Download Riwayat (Excel)', style: TextStyle(color: Colors.green)),
                  onTap: _downloadExcel,
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Riwayat Transaksi'),
                  onTap: () => Navigator.pushNamed(context, '/riwayat'),
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.orange),
                  title: const Text(
                    'Keluar',
                    style: TextStyle(color: Colors.orange),
                  ),
                  onTap: _logout,
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text(
                    'Hapus Akun',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                  onTap: _hapusAkun,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // widget kotak info buat nampilin data profil
  Widget _infoBox(IconData icon, String title, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF16205E)),
        title: Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
