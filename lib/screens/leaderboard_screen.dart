import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List _peringkat = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // narik data top 10 poin
  Future<void> _loadData() async {
    try {
      final res = await ApiService.getLeaderboard();
      if (res['data'] != null && mounted) {
        setState(() => _peringkat = res['data']);
      }
    } catch (e) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Peringkat Poin')),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: _peringkat.length,
            itemBuilder: (ctx, i) {
              final p = _peringkat[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: i == 0 ? Colors.amber : (i == 1 ? Colors.grey : (i == 2 ? Colors.brown : Colors.blueGrey)),
                  child: Text('${i+1}'),
                ),
                title: Text(p['nama'] ?? ''),
                subtitle: Text(p['kelas'] ?? ''),
                trailing: Text('${p['saldo_poin']} Poin', style: const TextStyle(fontWeight: FontWeight.bold)),
              );
            },
          ),
    );
  }
}
