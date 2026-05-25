import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game.dart';

/// Service untuk operasi CRUD data game ke Cloud Firestore
/// Mengimplementasikan Create, Read, Update, dan Delete
class GameService {
  final CollectionReference _gamesCollection =
      FirebaseFirestore.instance.collection('games');

  /// READ - Stream semua data game, diurutkan berdasarkan tanggal terbaru
  Stream<List<Game>> getGames() {
    return _gamesCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Game.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  /// CREATE - Menambahkan game baru ke Firestore
  Future<void> addGame(Game game) async {
    await _gamesCollection.add(game.toMap());
  }

  /// UPDATE - Mengupdate data game yang sudah ada di Firestore
  Future<void> updateGame(Game game) async {
    if (game.id == null) return;
    await _gamesCollection.doc(game.id).update(game.toMap());
  }

  /// DELETE - Menghapus game dari Firestore
  Future<void> deleteGame(String gameId) async {
    await _gamesCollection.doc(gameId).delete();
  }
}