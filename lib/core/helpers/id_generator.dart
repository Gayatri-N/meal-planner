import 'dart:math';

import 'package:injectable/injectable.dart';

/// Random ids for user-created records (meal items, manual shopping
/// lines). 16 lowercase letters/digits: ~82 bits, no dots, so safe as a
/// Firestore map key and field path segment.
@lazySingleton
class IdGenerator {
  IdGenerator() : _random = Random.secure();

  /// For tests: deterministic ids.
  IdGenerator.seeded(int seed) : _random = Random(seed);

  final Random _random;

  static const _alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';

  String next() => String.fromCharCodes([
    for (var i = 0; i < 16; i++)
      _alphabet.codeUnitAt(_random.nextInt(_alphabet.length)),
  ]);
}
