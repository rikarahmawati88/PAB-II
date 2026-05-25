/// Model class untuk data Game Favorite
/// Menyimpan informasi game yang akan disimpan ke Cloud Firestore
class Game {
  final String? id;
  final String title;
  final String genre;
  final String platform;
  final double rating;
  final String? imageBase64;
  final DateTime createdAt;

  Game({
    this.id,
    required this.title,
    required this.genre,
    required this.platform,
    required this.rating,
    this.imageBase64,
    required this.createdAt,
  });

  /// Membuat objek Game dari data Firestore document snapshot
  factory Game.fromMap(String id, Map<String, dynamic> map) {
    return Game(
      id: id,
      title: map['title'] ?? '',
      genre: map['genre'] ?? '',
      platform: map['platform'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      imageBase64: map['imageBase64'],
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  /// Mengkonversi objek Game menjadi Map untuk disimpan ke Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'genre': genre,
      'platform': platform,
      'rating': rating,
      'imageBase64': imageBase64,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}