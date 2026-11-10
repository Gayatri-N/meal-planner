import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../core/logger/logger.dart';

/// Marks a field for removal in [LocalDocumentStore.update], like
/// Firestore's `FieldValue.delete()`.
const deleteField = _DeleteField();

final class _DeleteField {
  const _DeleteField();
}

typedef JsonMap = Map<String, Object?>;

/// A small on-device document store with the same shape as Firestore,
/// used until Firebase is connected (ARCHITECTURE.md § Local storage).
///
/// - Data is collections of JSON documents: `collection → id → document`.
/// - [update] takes Firestore-style dotted field paths
///   (`slots.lunch.status`) and [deleteField], and creates missing parents
///   (like `set(..., SetOptions(merge: true))`).
/// - [watch] emits the document now and after every change, like
///   `snapshots()`.
/// - Changes apply in memory at once (watchers see them immediately);
///   the file is rewritten afterwards, one write at a time, atomically.
///
/// Everything lives in one JSON file. For the planned data sizes (a few
/// hundred days) that is a few hundred KB.
class LocalDocumentStore {
  LocalDocumentStore({
    required Future<Directory> Function() this.directory,
    required this.logger,
    this.fileName = 'local_store.json',
  });

  /// Keeps everything in memory only; nothing is read or written to disk.
  /// For widget tests, where real file I/O cannot complete.
  LocalDocumentStore.memory({required this.logger})
    : directory = null,
      fileName = '';

  /// Where the file lives; resolved on first use. Null = memory only.
  final Future<Directory> Function()? directory;
  final Logger logger;
  final String fileName;

  /// collection → document id → document.
  Map<String, Map<String, JsonMap>>? _data;
  Future<void>? _loading;
  File? _file;

  /// Serializes file writes so they never interleave.
  Future<void> _pendingWrite = Future.value();

  final _watchers = <String, Set<void Function()>>{};

  /// The document, or null if it does not exist.
  Future<JsonMap?> get(String collection, String id) async {
    await _ensureLoaded();
    return _copy(_data?[collection]?[id]);
  }

  /// Emits the document (or null) now, then after every change to it.
  Stream<JsonMap?> watch(String collection, String id) {
    final key = _key(collection, id);
    late final StreamController<JsonMap?> controller;
    void push() {
      if (!controller.isClosed) {
        controller.add(_copy(_data?[collection]?[id]));
      }
    }

    controller = StreamController<JsonMap?>(
      onListen: () async {
        _watchers.putIfAbsent(key, () => {}).add(push);
        await _ensureLoaded();
        push();
      },
      onCancel: () => _watchers[key]?.remove(push),
    );
    return controller.stream;
  }

  /// Applies [fields] to the document, creating it if missing. Keys are
  /// dotted paths; a value of [deleteField] removes that field.
  Future<void> update(String collection, String id, JsonMap fields) async {
    await _ensureLoaded();
    final docs = (_data ??= {}).putIfAbsent(collection, () => {});
    final doc = docs.putIfAbsent(id, () => {});
    for (final MapEntry(key: path, value: value) in fields.entries) {
      _apply(doc, path.split('.'), _copyValue(value));
    }
    _notify(collection, id);
    await _persist();
  }

  Future<void> delete(String collection, String id) async {
    await _ensureLoaded();
    if (_data?[collection]?.remove(id) != null) {
      _notify(collection, id);
      await _persist();
    }
  }

  /// Every document in [collection], keyed by id. For migrating this
  /// store's contents to Firestore after sign-in.
  Future<Map<String, JsonMap>> all(String collection) async {
    await _ensureLoaded();
    return {
      for (final MapEntry(key: id, value: doc)
          in (_data?[collection] ?? const <String, JsonMap>{}).entries)
        id: _copy(doc) ?? {},
    };
  }

  // --- internals ----------------------------------------------------------

  static String _key(String collection, String id) => '$collection/$id';

  void _notify(String collection, String id) {
    for (final push in [...?_watchers[_key(collection, id)]]) {
      push();
    }
  }

  static void _apply(JsonMap doc, List<String> path, Object? value) {
    var node = doc;
    for (final segment in path.take(path.length - 1)) {
      final child = node[segment];
      if (child is JsonMap) {
        node = child;
      } else {
        if (value == deleteField) return; // nothing to delete
        final created = <String, Object?>{};
        node[segment] = created;
        node = created;
      }
    }
    if (value == deleteField) {
      node.remove(path.last);
    } else {
      node[path.last] = value;
    }
  }

  Future<void> _ensureLoaded() => _loading ??= _load();

  Future<void> _load() async {
    final resolve = directory;
    if (resolve == null) {
      _data = {}; // memory only; _file stays null, so nothing is written
      return;
    }
    final dir = await resolve();
    final file = _file = File('${dir.path}/$fileName');
    if (!file.existsSync()) {
      _data = {};
      return;
    }
    try {
      final decoded = jsonDecode(await file.readAsString());
      _data = {
        for (final MapEntry(key: collection, value: docs)
            in (decoded as JsonMap).entries)
          collection: {
            for (final MapEntry(key: id, value: doc)
                in (docs as JsonMap).entries)
              id: doc as JsonMap,
          },
      };
    } on Object catch (e, s) {
      // Keep the unreadable file for diagnosis and start empty rather
      // than crash on every launch.
      final backup =
          '${file.path}.corrupt-${DateTime.now().millisecondsSinceEpoch}';
      logger.error(
        'Unreadable $fileName; moved to $backup',
        error: e,
        stackTrace: s,
        name: 'store',
      );
      await file.rename(backup);
      _data = {};
    }
  }

  Future<void> _persist() {
    final snapshot = jsonEncode(_data);
    return _pendingWrite = _pendingWrite.then((_) => _write(snapshot));
  }

  /// Write to a temp file, then rename over the real one, so a crash
  /// mid-write never leaves a half-written file.
  Future<void> _write(String json) async {
    final file = _file;
    if (file == null) return;
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(json, flush: true);
    await temp.rename(file.path);
  }

  static JsonMap? _copy(JsonMap? doc) =>
      doc == null ? null : jsonDecode(jsonEncode(doc)) as JsonMap;

  static Object? _copyValue(Object? value) => switch (value) {
    _DeleteField() => value,
    Map() || List() => jsonDecode(jsonEncode(value)),
    _ => value,
  };
}
