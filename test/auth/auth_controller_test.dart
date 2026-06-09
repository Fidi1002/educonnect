import 'dart:io';

import 'package:educonnect/features/auth/application/auth_controller.dart';
import 'package:educonnect/features/auth/data/repositories/auth_repository.dart';
import 'package:educonnect/features/auth/data/repositories/user_repository.dart';
import 'package:educonnect/features/auth/domain/models/app_user_role.dart';
import 'package:educonnect/features/auth/domain/models/auth_user.dart';
import 'package:educonnect/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:educonnect/features/auth/domain/repositories/i_user_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAuthRepository extends Mock implements IAuthRepository {}

class MockUserRepository extends Mock implements IUserRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockUserRepository mockUserRepository;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(
      const AppAuthUser(
        uid: 'test-uid',
        email: 'test@educonnect.com',
        displayName: 'Test User',
        photoUrl: '',
      ),
    );
    registerFallbackValue(AppUserRole.student);
  });

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockUserRepository = MockUserRepository();

    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
        userRepositoryProvider.overrideWithValue(mockUserRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('AuthController Offline Tests', () {
    const email = 'test@educonnect.com';
    const password = 'password123';
    const fullName = 'Test User';
    const testUser = AppAuthUser(
      uid: 'test-uid',
      email: email,
      displayName: fullName,
      photoUrl: '',
    );

    group('signInWithEmail', () {
      test('succeeds and performs upsert on user repository', () async {
        // Arrange
        when(
          () => mockAuthRepository.signInWithEmail(
            email: email,
            password: password,
          ),
        ).thenAnswer((_) async => testUser);

        when(() => mockUserRepository.upsertFromAuthUser(any())).thenAnswer(
          (_) async {},
        );

        final controller = container.read(authControllerProvider);

        // Act
        await controller.signInWithEmail(email: email, password: password);

        // Assert
        verify(
          () => mockAuthRepository.signInWithEmail(
            email: email,
            password: password,
          ),
        ).called(1);
        verify(() => mockUserRepository.upsertFromAuthUser(testUser)).called(1);
      });

      test('fails on network connection loss', () async {
        // Arrange
        when(
          () => mockAuthRepository.signInWithEmail(
            email: email,
            password: password,
          ),
        ).thenThrow(const SocketException('Koneksi internet terputus.'));

        final controller = container.read(authControllerProvider);

        // Act & Assert
        try {
          await controller.signInWithEmail(email: email, password: password);
          fail('Should have thrown SocketException');
        } catch (e) {
          expect(e, isA<SocketException>());
        }

        verify(
          () => mockAuthRepository.signInWithEmail(
            email: email,
            password: password,
          ),
        ).called(1);
        verifyNever(() => mockUserRepository.upsertFromAuthUser(any()));
      });
    });

    group('registerWithEmail', () {
      test('succeeds and performs upsert on user repository', () async {
        // Arrange
        when(
          () => mockAuthRepository.registerWithEmail(
            fullName: fullName,
            email: email,
            password: password,
          ),
        ).thenAnswer((_) async => testUser);

        when(() => mockUserRepository.upsertFromAuthUser(any())).thenAnswer(
          (_) async {},
        );

        final controller = container.read(authControllerProvider);

        // Act
        await controller.registerWithEmail(
          fullName: fullName,
          email: email,
          password: password,
        );

        // Assert
        verify(
          () => mockAuthRepository.registerWithEmail(
            fullName: fullName,
            email: email,
            password: password,
          ),
        ).called(1);
        verify(() => mockUserRepository.upsertFromAuthUser(testUser)).called(1);
      });

      test('fails with Supabase AuthException when registration database fails but user has no active session', () async {
        // Arrange
        when(
          () => mockAuthRepository.registerWithEmail(
            fullName: fullName,
            email: email,
            password: password,
          ),
        ).thenAnswer((_) async => testUser);

        when(() => mockUserRepository.upsertFromAuthUser(any())).thenThrow(
          const PostgrestException(message: 'Database upsert error'),
        );

        when(() => mockAuthRepository.hasActiveSession).thenReturn(false);

        final controller = container.read(authControllerProvider);

        // Act & Assert
        try {
          await controller.registerWithEmail(
            fullName: fullName,
            email: email,
            password: password,
          );
          fail('Should have thrown AuthException');
        } catch (e) {
          expect(e, isA<AuthException>());
          expect(
            (e as AuthException).message,
            contains('Akun berhasil dibuat. Cek email untuk verifikasi'),
          );
        }

        verify(
          () => mockAuthRepository.registerWithEmail(
            fullName: fullName,
            email: email,
            password: password,
          ),
        ).called(1);
        verify(() => mockUserRepository.upsertFromAuthUser(testUser)).called(1);
      });
    });

    group('setRole', () {
      test('succeeds when user is authenticated', () async {
        // Arrange
        when(() => mockAuthRepository.currentUser).thenReturn(testUser);
        when(
          () => mockUserRepository.setRole(
            uid: testUser.uid,
            role: AppUserRole.student,
          ),
        ).thenAnswer((_) async {});

        final controller = container.read(authControllerProvider);

        // Act
        await controller.setRole(AppUserRole.student);

        // Assert
        verify(() => mockAuthRepository.currentUser).called(1);
        verify(
          () => mockUserRepository.setRole(
            uid: testUser.uid,
            role: AppUserRole.student,
          ),
        ).called(1);
      });

      test('throws StateError when user is not authenticated', () async {
        // Arrange
        when(() => mockAuthRepository.currentUser).thenReturn(null);

        final controller = container.read(authControllerProvider);

        // Act & Assert
        expect(
          () => controller.setRole(AppUserRole.student),
          throwsA(isA<StateError>()),
        );

        verify(() => mockAuthRepository.currentUser).called(1);
        verifyNever(
          () => mockUserRepository.setRole(
            uid: any(named: 'uid'),
            role: any(named: 'role'),
          ),
        );
      });
    });

    group('runAuthTask', () {
      test('sets authLoadingProvider to true, then back to false on completion', () async {
        final controller = container.read(authControllerProvider);
        final loadingStates = <bool>[];

        container.listen<bool>(authLoadingProvider, (previous, next) {
          loadingStates.add(next);
        });

        expect(container.read(authLoadingProvider), isFalse);

        await controller.runAuthTask(() async {
          expect(container.read(authLoadingProvider), isTrue);
          return 'done';
        });

        expect(container.read(authLoadingProvider), isFalse);
        expect(loadingStates, contains(true));
      });

      test('sets authLoadingProvider to false even when task throws exception', () async {
        final controller = container.read(authControllerProvider);

        expect(container.read(authLoadingProvider), isFalse);

        var threw = false;
        try {
          await controller.runAuthTask(() async {
            expect(container.read(authLoadingProvider), isTrue);
            throw Exception('Task error');
          });
        } catch (_) {
          threw = true;
        }

        expect(threw, isTrue);
        expect(container.read(authLoadingProvider), isFalse);
      });
    });
  });
}
