import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:educonnect/core/services/local_cache_service.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockSecureStorage;

  setUpAll(() {
    Hive.init('.');
  });

  setUp(() {
    mockSecureStorage = MockFlutterSecureStorage();
  });

  tearDown(() async {
    await Hive.close();
    try {
      await Hive.deleteBoxFromDisk('educonnect_cache');
    } catch (_) {}
  });

  group('LocalCacheService Encryption Tests', () {
    test('initializes with new key when secure storage is empty', () async {
      when(() => mockSecureStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);
      when(() => mockSecureStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      await LocalCacheService.initialize(secureStorageOverride: mockSecureStorage, isTest: true);

      verify(() => mockSecureStorage.read(key: 'educonnect_encryption_key')).called(1);
      verify(() => mockSecureStorage.write(
            key: 'educonnect_encryption_key',
            value: any(named: 'value'),
          )).called(1);
    });

    test('initializes with existing key from secure storage', () async {
      final mockKey = Hive.generateSecureKey();
      final mockKeyBase64 = base64Url.encode(mockKey);

      when(() => mockSecureStorage.read(key: 'educonnect_encryption_key'))
          .thenAnswer((_) async => mockKeyBase64);

      await LocalCacheService.initialize(secureStorageOverride: mockSecureStorage, isTest: true);

      verify(() => mockSecureStorage.read(key: 'educonnect_encryption_key')).called(1);
      verifyNever(() => mockSecureStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ));
    });

    test('caches and retrieves active tutors correctly', () async {
      when(() => mockSecureStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);
      when(() => mockSecureStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      await LocalCacheService.initialize(secureStorageOverride: mockSecureStorage, isTest: true);

      final mockTutors = [
        {'uid': '123', 'name': 'Tutor A', 'subjects': ['Math']},
        {'uid': '456', 'name': 'Tutor B', 'subjects': ['Physics']},
      ];

      await LocalCacheService.cacheActiveTutors(mockTutors);
      final retrieved = await LocalCacheService.getActiveTutors();

      expect(retrieved.length, 2);
      expect(retrieved[0]['name'], 'Tutor A');
      expect(retrieved[1]['uid'], '456');
    });

    test('recreates box on decryption failure (robust recovery)', () async {
      // 1. Initialize box with key A
      final keyA = Hive.generateSecureKey();
      when(() => mockSecureStorage.read(key: 'educonnect_encryption_key'))
          .thenAnswer((_) async => base64Url.encode(keyA));
      
      await LocalCacheService.initialize(secureStorageOverride: mockSecureStorage, isTest: true);
      await LocalCacheService.cacheActiveTutors([{'name': 'Secret Tutor'}]);
      await Hive.close();

      // 2. Try to initialize box with key B (simulates decryption failure)
      final keyB = Hive.generateSecureKey();
      final mockSecureStorage2 = MockFlutterSecureStorage();
      when(() => mockSecureStorage2.read(key: 'educonnect_encryption_key'))
          .thenAnswer((_) async => base64Url.encode(keyB));

      // This should delete the old box on disk and open a fresh empty box rather than crash
      await LocalCacheService.initialize(secureStorageOverride: mockSecureStorage2, isTest: true);
      
      final retrieved = await LocalCacheService.getActiveTutors();
      expect(retrieved, isEmpty, reason: 'Decryption failure should recover to a fresh empty box');
    });
  });
}
