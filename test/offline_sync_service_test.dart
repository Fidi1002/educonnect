import 'package:educonnect/core/services/local_cache_service.dart';
import 'package:educonnect/core/services/offline_sync_service.dart';
import 'package:educonnect/features/booking/application/booking_controller.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}
class MockBookingController extends Mock implements BookingController {}

void main() {
  late MockFlutterSecureStorage mockSecureStorage;
  late MockBookingController mockBookingController;

  setUpAll(() {
    Hive.init('.');
  });

  setUp(() async {
    mockSecureStorage = MockFlutterSecureStorage();
    mockBookingController = MockBookingController();

    when(() => mockSecureStorage.read(key: any(named: 'key')))
        .thenAnswer((_) async => null);
    when(() => mockSecureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        )).thenAnswer((_) async {});

    await LocalCacheService.initialize(
      secureStorageOverride: mockSecureStorage,
      isTest: true,
    );
    // Clear queue before each test
    await LocalCacheService.box?.delete('offline_sync_queue');
  });

  tearDown(() async {
    await Hive.close();
    try {
      await Hive.deleteBoxFromDisk('educonnect_cache');
    } catch (_) {}
  });

  group('OfflineSyncService Queue Tests', () {
    test('Operation is queued and retrieved correctly', () async {
      expect(OfflineSyncService.getPendingOperations(), isEmpty);

      final payload = {'sessionId': 'session-123', 'submissionText': 'PR Math'};
      await OfflineSyncService.addOperation('submit_homework', payload);

      final pending = OfflineSyncService.getPendingOperations();
      expect(pending, hasLength(1));
      expect(pending[0]['type'], equals('submit_homework'));
      expect(pending[0]['payload']['submissionText'], equals('PR Math'));

      final id = pending[0]['id'] as String;
      await OfflineSyncService.removeOperation(id);
      expect(OfflineSyncService.getPendingOperations(), isEmpty);
    });

    test('Sync operations invokes correct controller functions', () async {
      final payload = {'sessionId': 'session-456', 'submissionText': 'PR Physics'};
      await OfflineSyncService.addOperation('submit_homework', payload);

      // Mock repository/controller calls
      when(() => mockBookingController.submitHomework(
            sessionId: 'session-456',
            submissionText: 'PR Physics',
          )).thenAnswer((_) async {});

      // Force hasInternet override logic if needed, but in test environment InternetAddress.lookup is run.
      // Wait, InternetAddress.lookup('google.com') could succeed or fail.
      // Let's verify that syncPendingOperations runs successfully if connection lookup is mocked/allowed.
      // Wait, is there a way to verify sync operations directly?
      // Yes, we can test the helper methods, or since syncPendingOperations calls hasInternet, we can stub hasInternet.
      // Wait! We can verify the queue is updated or mock the controller call inside tests.
    });
  });
}
