import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:game/models/game.dart';
import 'package:game/services/game_service.dart';

/// Widget dialog untuk Tambah dan Edit data game
/// Digunakan oleh GameListScreen melalui fungsi showGameDialog()
///
/// Fitur:
/// - Input judul, genre, platform, rating
/// - Pilih gambar dari galeri dan konversi ke base64
/// - Validasi input sebelum menyimpan
/// - Mendukung mode Create (game == null) dan Update (game != null)

// Warna tema gaming
const Color _dark1 = Color(0xFF1a1a2e);
const Color _dark2 = Color(0xFF16213e);
const Color _red = Color(0xFFe94560);
const Color _purple = Color(0xFF533483);

/// Fungsi helper untuk menampilkan GameDialog dari halaman manapun
void showGameDialog(BuildContext context, {Game? game}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => GameDialog(game: game),
  );
}

class GameDialog extends StatefulWidget {
  /// Jika game != null, maka dialog dalam mode Edit
  /// Jika game == null, maka dialog dalam mode Tambah
  final Game? game;

  const GameDialog({super.key, this.game});

  @override
  State<GameDialog> createState() => _GameDialogState();
}

class _GameDialogState extends State<GameDialog> {
  final GameService _gameService = GameService();

  late TextEditingController _titleController;
  late TextEditingController _genreController;
  late TextEditingController _platformController;
  late double _rating;
  String? _imageBase64;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller dengan data game yang ada (jika mode edit)
    _titleController = TextEditingController(text: widget.game?.title ?? '');
    _genreController = TextEditingController(text: widget.game?.genre ?? '');
    _platformController =
        TextEditingController(text: widget.game?.platform ?? '');
    _rating = widget.game?.rating ?? 5.0;
    _imageBase64 = widget.game?.imageBase64;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _genreController.dispose();
    _platformController.dispose();
    super.dispose();
  }

  /// Pilih gambar dari galeri lalu konversi ke base64
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 50,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _imageBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih gambar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Simpan data game ke Firestore (Create / Update)
  Future<void> _saveGame() async {
    // Validasi: semua field wajib diisi
    if (_titleController.text.trim().isEmpty) {
      _showError('Judul game tidak boleh kosong!');
      return;
    }
    if (_genreController.text.trim().isEmpty) {
      _showError('Genre tidak boleh kosong!');
      return;
    }
    if (_platformController.text.trim().isEmpty) {
      _showError('Platform tidak boleh kosong!');
      return;
    }

    setState(() => _isLoading = true);

    // Buat objek Game dari input
    final newGame = Game(
      id: widget.game?.id,
      title: _titleController.text.trim(),
      genre: _genreController.text.trim(),
      platform: _platformController.text.trim(),
      rating: _rating,
      imageBase64: _imageBase64,
      createdAt: widget.game?.createdAt ?? DateTime.now(),
    );

    try {
      if (widget.game == null) {
        // CREATE - Tambah game baru ke Firestore
        await _gameService.addGame(newGame);
      } else {
        // UPDATE - Perbarui data game di Firestore
        await _gameService.updateGame(newGame);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError('Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Tampilkan pesan error
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  /// Widget TextField yang konsisten dengan tema gaming
  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? hint,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: _red.withOpacity(0.7)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _red),
        ),
        filled: true,
        fillColor: _dark2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.game != null;

    return Dialog(
      backgroundColor: _dark1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: _red.withOpacity(0.3)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ===== Header Dialog =====
            Row(
              children: [
                Icon(
                  isEdit ? Icons.edit_note_rounded : Icons.add_circle_outline,
                  color: _red,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  isEdit ? 'Edit Game' : 'Tambah Game',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Divider(color: _red.withOpacity(0.3)),
            const SizedBox(height: 16),

            // ===== Image Picker =====
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  color: _dark2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _purple.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: _imageBase64 != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Image.memory(
                          base64Decode(_imageBase64!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            size: 50,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap untuk pilih gambar',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 18),

            // ===== Input Fields =====
            _buildField(
              _titleController,
              'Judul Game',
              Icons.sports_esports,
            ),
            const SizedBox(height: 14),
            _buildField(
              _genreController,
              'Genre',
              Icons.category_outlined,
              hint: 'Contoh: Action, RPG, Puzzle',
            ),
            const SizedBox(height: 14),
            _buildField(
              _platformController,
              'Platform',
              Icons.devices_rounded,
              hint: 'Contoh: PC, PS5, Mobile',
            ),
            const SizedBox(height: 18),

            // ===== Rating Slider =====
            Row(
              children: [
                Icon(Icons.star_rounded, color: Colors.amber.shade400, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Rating: ${_rating.toStringAsFixed(1)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: _red,
                inactiveTrackColor: _red.withOpacity(0.2),
                thumbColor: _red,
                overlayColor: _red.withOpacity(0.2),
                valueIndicatorColor: _red,
                valueIndicatorTextStyle: const TextStyle(color: Colors.white),
              ),
              child: Slider(
                value: _rating,
                min: 0,
                max: 10,
                divisions: 20,
                label: _rating.toStringAsFixed(1),
                onChanged: (value) {
                  setState(() => _rating = value);
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4), fontSize: 12)),
                Text('10',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4), fontSize: 12)),
              ],
            ),
            const SizedBox(height: 24),

            // ===== Tombol Batal & Simpan =====
            Row(
              children: [
                // Tombol Batal
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                // Tombol Simpan / Update
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      shadowColor: _red.withOpacity(0.4),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            isEdit ? 'Update' : 'Simpan',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
