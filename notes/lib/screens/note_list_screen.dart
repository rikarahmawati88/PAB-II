import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/note_service.dart';
import '../widgets/note_dialog.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/fcm_service.dart';
import '../l10n/app_localizations.dart';
import 'subscribe_screen.dart';

class NoteListScreen extends StatefulWidget {
  const NoteListScreen({super.key, this.onLocaleChanged});

  final ValueChanged<Locale>? onLocaleChanged;

  @override
  State<NoteListScreen> createState() => _NoteListScreenState();
}

class _NoteListScreenState extends State<NoteListScreen> {
  final NoteService _noteService = NoteService();
  final FcmService _fcmService = FcmService(); // tambahan

  /// Show dialog to add a new note
  Future<void> _addNote() async {
    final note = await showDialog<Note>(
      context: context,
      builder: (context) => const NoteDialog(),
    );

    if (note != null) {
      try {
        await _noteService.addNote(note);

        // Send notification via REST API
      await _fcmService.sendNoteNotification(
      title: note.title,
      description: note.description,
    );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.noteAdded),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.noteAddFailed(e.toString())),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Show dialog to edit an existing note
  Future<void> _editNote(Note note) async {
    final updatedNote = await showDialog<Note>(
      context: context,
      builder: (context) => NoteDialog(note: note),
    );

    if (updatedNote != null) {
      try {
        await _noteService.updateNote(updatedNote);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.noteUpdated),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.noteUpdateFailed(e.toString())),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Show confirmation dialog and delete a note
  Future<void> _deleteNote(Note note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppLocalizations.of(context)!.deleteNote),
        content: Text(AppLocalizations.of(context)!.deleteConfirm(note.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirm == true && note.id != null) {
      try {
        await _noteService.deleteNote(note.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.noteDeleted),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.noteDeleteFailed(e.toString())),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Format date to readable string
  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}, '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.sticky_note_2, color: Colors.white),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.appTitle),
          ],
        ),
        actions: [
          PopupMenuButton<Locale>(
            tooltip: AppLocalizations.of(context)!.language,
            icon: const Icon(Icons.language),
            onSelected: (locale) => widget.onLocaleChanged?.call(locale),
            itemBuilder: (context) {
              final current = Localizations.localeOf(context).languageCode;
              return [
                PopupMenuItem<Locale>(
                  value: const Locale('id'),
                  child: Row(
                    children: [
                      if (current == 'id')
                        const Icon(Icons.check, size: 18, color: Colors.deepPurple)
                      else
                        const SizedBox(width: 18),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context)!.languageIndonesian),
                    ],
                  ),
                ),
                PopupMenuItem<Locale>(
                  value: const Locale('en'),
                  child: Row(
                    children: [
                      if (current == 'en')
                        const Icon(Icons.check, size: 18, color: Colors.deepPurple)
                      else
                        const SizedBox(width: 18),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context)!.languageEnglish),
                    ],
                  ),
                ),
              ];
            },
          ),
          IconButton(
            icon: const Icon(Icons.subscriptions),
            tooltip: AppLocalizations.of(context)!.subscribeTooltip,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SubscribeScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.copy_all),
            tooltip: AppLocalizations.of(context)!.copyFcmToken,
            onPressed: () async {
              final token = await FirebaseMessaging.instance.getToken();
              if (token != null) {
                await Clipboard.setData(ClipboardData(text: token));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.fcmTokenCopied)),
                  );
                }
                debugPrint('FCM Token: $token');
              }
            },
          ),
        ],

        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple.shade50, Colors.white],
          ),
        ),
        child: StreamBuilder<List<Note>>(
          stream: _noteService.getNotes(),
          builder: (context, snapshot) {
            // Loading state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // Error state
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.errorOccurred,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: TextStyle(color: Colors.grey.shade500),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final notes = snapshot.data ?? [];

            // Empty state
            if (notes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.note_add_outlined,
                      size: 80,
                      color: Colors.deepPurple.shade200,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.noNotes,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.addNoteHint,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Notes list
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return _buildNoteCard(note);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Build a single note card
  Widget _buildNoteCard(Note note) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image (if available)
          if (note.imageBase64 != null && note.imageBase64!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.memory(
                base64Decode(note.imageBase64!),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 100,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  note.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  note.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),

                // Footer: date + action buttons
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(note.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const Spacer(),
                    // Edit Button
                    IconButton(
                      onPressed: () => _editNote(note),
                      icon: const Icon(Icons.edit_outlined),
                      color: Colors.deepPurple,
                      iconSize: 20,
                      tooltip: 'Edit',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                    const SizedBox(width: 4),
                    // Delete Button
                    IconButton(
                      onPressed: () => _deleteNote(note),
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red,
                      iconSize: 20,
                      tooltip: 'Hapus',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
