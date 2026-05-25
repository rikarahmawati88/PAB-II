import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:game/models/game.dart';
import 'package:game/services/game_service.dart';
import 'package:game/services/auth_service.dart';
import 'package:game/screens/login_screen.dart';

class GameListScreen extends StatefulWidget {
  const GameListScreen({super.key});
  @override
  State<GameListScreen> createState() => _GameListScreenState();
}

class _GameListScreenState extends State<GameListScreen> {
  final GameService _gameService = GameService();
  final AuthService _authService = AuthService();
  static const _dark1 = Color(0xFF1a1a2e);
  static const _dark2 = Color(0xFF16213e);
  static const _red = Color(0xFFe94560);
  static const _purple = Color(0xFF533483);

  void _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: _dark2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.logout, color: _red), SizedBox(width: 10),
          Text('Logout', style: TextStyle(color: Colors.white)),
        ]),
        content: Text('Yakin ingin keluar?', style: TextStyle(color: Colors.white.withOpacity(0.8))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text('Batal', style: TextStyle(color: Colors.white.withOpacity(0.6)))),
          ElevatedButton(onPressed: () => Navigator.pop(c, true), style: ElevatedButton.styleFrom(backgroundColor: _red), child: const Text('Logout', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (ok == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
      }
    }
  }

  void _showGameDialog({Game? game}) {
    final titleC = TextEditingController(text: game?.title ?? '');
    final genreC = TextEditingController(text: game?.genre ?? '');
    final platC = TextEditingController(text: game?.platform ?? '');
    double rating = game?.rating ?? 5.0;
    String? imgB64 = game?.imageBase64;
    bool loading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) {
        Future<void> pickImg() async {
          try {
            final p = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 400, maxHeight: 400, imageQuality: 50);
            if (p != null) { final b = await p.readAsBytes(); setSt(() => imgB64 = base64Encode(b)); }
          } catch (e) { if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)); }
        }
        Future<void> save() async {
          if (titleC.text.trim().isEmpty || genreC.text.trim().isEmpty || platC.text.trim().isEmpty) {
            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Semua field harus diisi!'), backgroundColor: Colors.red));
            return;
          }
          setSt(() => loading = true);
          final g = Game(id: game?.id, title: titleC.text.trim(), genre: genreC.text.trim(), platform: platC.text.trim(), rating: rating, imageBase64: imgB64, createdAt: game?.createdAt ?? DateTime.now());
          try {
            if (game == null) { await _gameService.addGame(g); } else { await _gameService.updateGame(g); }
            if (ctx.mounted) Navigator.pop(ctx);
          } catch (e) { if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)); }
          setSt(() => loading = false);
        }

        return Dialog(
          backgroundColor: _dark1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: _red.withOpacity(0.3))),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Icon(game == null ? Icons.add_circle_outline : Icons.edit_note_rounded, color: _red, size: 28),
                const SizedBox(width: 10),
                Text(game == null ? 'Tambah Game' : 'Edit Game', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 6),
              Divider(color: _red.withOpacity(0.3)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: pickImg,
                child: Container(
                  width: double.infinity, height: 160,
                  decoration: BoxDecoration(color: _dark2, borderRadius: BorderRadius.circular(14), border: Border.all(color: _purple.withOpacity(0.4), width: 1.5)),
                  child: imgB64 != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(13), child: Image.memory(base64Decode(imgB64!), fit: BoxFit.cover, width: double.infinity))
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.image_outlined, size: 50, color: Colors.white.withOpacity(0.3)),
                        const SizedBox(height: 8),
                        Text('Tap untuk pilih gambar', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14)),
                      ]),
                ),
              ),
              const SizedBox(height: 18),
              _field(titleC, 'Judul Game', Icons.sports_esports),
              const SizedBox(height: 14),
              _field(genreC, 'Genre', Icons.category_outlined, hint: 'Contoh: Action, RPG'),
              const SizedBox(height: 14),
              _field(platC, 'Platform', Icons.devices_rounded, hint: 'Contoh: PC, PS5, Mobile'),
              const SizedBox(height: 18),
              Row(children: [
                Icon(Icons.star_rounded, color: Colors.amber.shade400, size: 22),
                const SizedBox(width: 8),
                Text('Rating: ${rating.toStringAsFixed(1)}', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
              ]),
              SliderTheme(
                data: SliderTheme.of(ctx).copyWith(activeTrackColor: _red, inactiveTrackColor: _red.withOpacity(0.2), thumbColor: _red, overlayColor: _red.withOpacity(0.2)),
                child: Slider(value: rating, min: 0, max: 10, divisions: 20, label: rating.toStringAsFixed(1), onChanged: (v) => setSt(() => rating = v)),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: loading ? null : () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: BorderSide(color: Colors.white.withOpacity(0.3)), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Batal'),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: loading ? null : save,
                  style: ElevatedButton.styleFrom(backgroundColor: _red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(game == null ? 'Simpan' : 'Update', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                )),
              ]),
            ]),
          ),
        );
      }),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon, {String? hint}) {
    return TextField(
      controller: c, style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label, hintText: hint, hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: _red.withOpacity(0.7)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _red)),
        filled: true, fillColor: _dark2,
      ),
    );
  }

  void _confirmDelete(Game game) {
    showDialog(context: context, builder: (c) => AlertDialog(
      backgroundColor: _dark1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.red.withOpacity(0.3))),
      title: const Row(children: [Icon(Icons.delete_forever, color: Colors.redAccent), SizedBox(width: 10), Text('Hapus Game', style: TextStyle(color: Colors.white))]),
      content: RichText(text: TextSpan(text: 'Yakin ingin menghapus ', style: TextStyle(color: Colors.white.withOpacity(0.8)), children: [
        TextSpan(text: '"${game.title}"', style: const TextStyle(color: _red, fontWeight: FontWeight.bold)), const TextSpan(text: '?'),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: Text('Batal', style: TextStyle(color: Colors.white.withOpacity(0.6)))),
        ElevatedButton(onPressed: () async { Navigator.pop(c); if (game.id != null) await _gameService.deleteGame(game.id!); },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), child: const Text('Hapus', style: TextStyle(color: Colors.white))),
      ],
    ));
  }

  Widget _stars(double rating) {
    double s = rating / 2;
    int full = s.floor();
    bool half = (s - full) >= 0.5;
    int empty = 5 - full - (half ? 1 : 0);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      ...List.generate(full, (_) => const Icon(Icons.star_rounded, color: Colors.amber, size: 16)),
      if (half) const Icon(Icons.star_half_rounded, color: Colors.amber, size: 16),
      ...List.generate(empty, (_) => Icon(Icons.star_outline_rounded, color: Colors.amber.withOpacity(0.4), size: 16)),
      const SizedBox(width: 4),
      Text(rating.toStringAsFixed(1), style: TextStyle(color: Colors.amber.shade300, fontSize: 13, fontWeight: FontWeight.bold)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dark1,
      appBar: AppBar(
        title: const Row(children: [
          Icon(Icons.sports_esports_rounded, color: _red), SizedBox(width: 10),
          Text('GameVault', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        ]),
        backgroundColor: _dark2, foregroundColor: Colors.white, elevation: 0,
        actions: [
          if (_authService.currentUser != null)
            Padding(padding: const EdgeInsets.only(right: 4), child: Chip(
              avatar: const Icon(Icons.person, size: 16, color: Colors.white),
              label: Text(_authService.currentUser!.email?.split('@').first ?? '', style: const TextStyle(color: Colors.white, fontSize: 12)),
              backgroundColor: _purple.withOpacity(0.5), side: BorderSide.none,
            )),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout_rounded), tooltip: 'Logout', style: IconButton.styleFrom(foregroundColor: _red)),
        ],
      ),
      body: StreamBuilder<List<Game>>(
        stream: _gameService.getGames(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: _red));
          if (snap.hasError) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.error_outline, size: 60, color: _red.withOpacity(0.5)), const SizedBox(height: 16),
            Text('Terjadi kesalahan', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 18)),
          ]));
          final games = snap.data ?? [];
          if (games.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.sports_esports_outlined, size: 80, color: _red.withOpacity(0.3)), const SizedBox(height: 16),
            Text('Belum ada game', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 20, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text('Tap + untuk tambah game favorit!', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14)),
          ]));
          return ListView.builder(
            padding: const EdgeInsets.all(16), itemCount: games.length,
            itemBuilder: (_, i) => _card(games[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showGameDialog(),
        backgroundColor: _red, foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Game', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _card(Game game) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _dark2, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _purple.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showGameDialog(game: game),
        child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: _dark1, border: Border.all(color: _red.withOpacity(0.3))),
            child: game.imageBase64 != null
              ? ClipRRect(borderRadius: BorderRadius.circular(11), child: Image.memory(base64Decode(game.imageBase64!), fit: BoxFit.cover, width: 80, height: 80))
              : Icon(Icons.sports_esports_rounded, size: 36, color: _red.withOpacity(0.4)),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(game.title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: _purple.withOpacity(0.3), borderRadius: BorderRadius.circular(6)),
                child: Text(game.genre, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500))),
              const SizedBox(width: 6),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: _red.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                child: Text(game.platform, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500))),
            ]),
            const SizedBox(height: 6),
            _stars(game.rating),
          ])),
          Column(children: [
            InkWell(onTap: () => _showGameDialog(game: game), borderRadius: BorderRadius.circular(8),
              child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _purple.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.edit_rounded, color: _purple, size: 20))),
            const SizedBox(height: 8),
            InkWell(onTap: () => _confirmDelete(game), borderRadius: BorderRadius.circular(8),
              child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 20))),
          ]),
        ])),
      ),
    );
  }
}
