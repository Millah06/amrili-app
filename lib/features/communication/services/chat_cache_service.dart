import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/chat_message.dart';
import '../models/chat_model.dart';

/// Local-first chat cache.
///
/// Phase 3 cost/offline layer: Firestore is only a short-lived transport
/// (messages self-expire server-side after 120h and a backend job deletes
/// them), while THIS cache is the durable, instant, offline history on the
/// device. The chat list and conversation seed from here first, then reconcile
/// with the live Firestore stream.
///
/// Storage format: JSON strings in plain Hive boxes — no generated adapters,
/// so the schema can evolve without migrations.
class ChatCacheService {
  ChatCacheService._();
  static final ChatCacheService instance = ChatCacheService._();

  static const String _listBoxName = 'chat_list_cache';
  static const String _msgBoxName = 'chat_messages_cache';

  /// Keep at most this many messages per room on-device to bound storage.
  static const int _maxMessagesPerRoom = 300;

  Box<String>? _listBox;
  Box<String>? _msgBox;

  bool get _ready => _listBox != null && _msgBox != null;

  /// Open boxes once at startup (called from main.dart after Hive.initFlutter).
  Future<void> init() async {
    _listBox = await Hive.openBox<String>(_listBoxName);
    _msgBox = await Hive.openBox<String>(_msgBoxName);
  }

  // ── Chat list ───────────────────────────────────────────────

  String _listKey(String userId) => 'list_$userId';

  /// Persist the chat list for a user (newest-first order preserved).
  Future<void> saveChatList(String userId, List<ChatModel> chats) async {
    if (!_ready || userId.isEmpty) return;
    final encoded = jsonEncode(chats.map((c) => c.toMap()).toList());
    await _listBox!.put(_listKey(userId), encoded);
  }

  /// Read the cached chat list, or empty if none.
  List<ChatModel> getChatList(String userId) {
    if (!_ready || userId.isEmpty) return const [];
    final raw = _listBox!.get(_listKey(userId));
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => ChatModel.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  // ── Messages ────────────────────────────────────────────────

  String _msgKey(String roomId) => 'room_$roomId';

  /// Persist messages for a room. Expects newest-first (matches the Firestore
  /// query order); trims to [_maxMessagesPerRoom].
  Future<void> saveMessages(String roomId, List<ChatMessage> messages) async {
    if (!_ready || roomId.isEmpty) return;
    final trimmed = messages.length > _maxMessagesPerRoom
        ? messages.sublist(0, _maxMessagesPerRoom)
        : messages;
    final encoded = jsonEncode(trimmed.map((m) => m.toMap()).toList());
    await _msgBox!.put(_msgKey(roomId), encoded);
  }

  /// Read cached messages for a room (newest-first), or empty.
  List<ChatMessage> getMessages(String roomId) {
    if (!_ready || roomId.isEmpty) return const [];
    final raw = _msgBox!.get(_msgKey(roomId));
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => ChatMessage.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Merge a fresh batch (from Firestore) with what we already have, so that
  /// messages the server has since deleted (expired) remain readable locally.
  /// Returns the merged, newest-first list that was persisted.
  Future<List<ChatMessage>> mergeAndSaveMessages(
    String roomId,
    List<ChatMessage> fresh,
  ) async {
    final existing = getMessages(roomId);
    final byId = <String, ChatMessage>{};
    // Existing first, then fresh overwrites with newer status/content.
    for (final m in existing) {
      byId[m.id] = m;
    }
    for (final m in fresh) {
      byId[m.id] = m;
    }
    final merged = byId.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await saveMessages(roomId, merged);
    return merged.length > _maxMessagesPerRoom
        ? merged.sublist(0, _maxMessagesPerRoom)
        : merged;
  }

  /// Wipe everything (e.g. on logout).
  Future<void> clear() async {
    await _listBox?.clear();
    await _msgBox?.clear();
  }
}
