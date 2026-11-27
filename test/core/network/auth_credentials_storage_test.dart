/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (c) 2026 - 2026 wger Team
 *
 * wger Workout Manager is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:wger/core/consts.dart';
import 'package:wger/core/network/auth_credential.dart';
import 'package:wger/core/network/auth_credentials_storage.dart';
import 'package:wger/core/network/secure_token_storage.dart';
import 'package:wger/core/shared_preferences.dart';

import '../../helpers/fake_auth_environment.dart';
import 'auth_credentials_storage_test.mocks.dart';

@GenerateMocks([SecureTokenStorage])
void main() {
  installFakeAuthEnvironment();

  late MockSecureTokenStorage secureStorage;
  late AuthCredentialsStorage storage;
  late List<LogRecord> logs;
  late StreamSubscription<LogRecord> logSub;

  setUp(() {
    secureStorage = MockSecureTokenStorage();
    storage = AuthCredentialsStorage(secureStorage);
    logs = [];
    logSub = Logger.root.onRecord.listen(logs.add);
  });

  tearDown(() => logSub.cancel());

  bool loggedKeyringWarning() => logs.any(
    (r) => r.loggerName == 'AuthCredentialsStorage' && r.level == Level.WARNING,
  );

  // A locked or unavailable keyring (e.g. a Flatpak without an unlocked Secret
  // Service) raises a PlatformException from the secure-storage plugin. It must
  // not abort the auth flow: the refresh-token write/delete is best-effort and
  // logged, while the rest of the credential bundle still goes through.
  group('tolerates a locked keyring', () {
    final keyringLocked = PlatformException(code: 'KeyringLocked', message: 'KeyringLocked');

    test('saveJwt persists the prefs, logs, and does not rethrow', () async {
      when(secureStorage.writeRefreshToken(any)).thenThrow(keyringLocked);

      await expectLater(
        storage.saveJwt(
          credential: const JwtCredential(accessToken: 'access'),
          serverUrl: 'https://wger.example',
          refreshToken: 'refresh',
        ),
        completes,
      );

      verify(secureStorage.writeRefreshToken('refresh')).called(1);
      expect(await PreferenceHelper.asyncPref.getString(PREFS_ACCESS_TOKEN), 'access');
      expect(await PreferenceHelper.asyncPref.getString(PREFS_SERVER_URL), 'https://wger.example');
      expect(loggedKeyringWarning(), isTrue);
    });

    test('updateJwt persists the prefs and does not rethrow', () async {
      when(secureStorage.writeRefreshToken(any)).thenThrow(keyringLocked);

      await expectLater(
        storage.updateJwt(
          credential: const JwtCredential(accessToken: 'access2'),
          refreshToken: 'refresh',
        ),
        completes,
      );

      expect(await PreferenceHelper.asyncPref.getString(PREFS_ACCESS_TOKEN), 'access2');
      expect(loggedKeyringWarning(), isTrue);
    });

    test('clearCredentials clears the prefs, logs, and does not rethrow', () async {
      when(secureStorage.deleteRefreshToken()).thenThrow(keyringLocked);
      await PreferenceHelper.asyncPref.setString(PREFS_ACCESS_TOKEN, 'stale');

      await expectLater(storage.clearCredentials(), completes);

      verify(secureStorage.deleteRefreshToken()).called(1);
      expect(await PreferenceHelper.asyncPref.getString(PREFS_ACCESS_TOKEN), isNull);
      expect(loggedKeyringWarning(), isTrue);
    });
  });

  // The server invalidates the previous refresh token with every rotation. If
  // the rotated one can't be written, reading the stale one from disk ends the
  // session at the next refresh.
  group('a rotated refresh token secure storage refused', () {
    final keychainLocked = PlatformException(code: 'Unexpected security result code');

    test('is read back instead of the stale one on disk', () async {
      when(secureStorage.writeRefreshToken(any)).thenThrow(keychainLocked);
      when(secureStorage.readRefreshToken()).thenAnswer((_) async => 'stale');

      await storage.updateJwt(
        credential: const JwtCredential(accessToken: 'access2'),
        refreshToken: 'rotated',
      );

      expect(await storage.readRefreshToken(), 'rotated');
      verifyNever(secureStorage.readRefreshToken());
    });

    test('is persisted on the next read once storage accepts it', () async {
      when(secureStorage.writeRefreshToken(any)).thenThrow(keychainLocked);
      await storage.updateJwt(
        credential: const JwtCredential(accessToken: 'access2'),
        refreshToken: 'rotated',
      );

      when(secureStorage.writeRefreshToken(any)).thenAnswer((_) async {});
      when(secureStorage.readRefreshToken()).thenAnswer((_) async => 'rotated');
      expect(await storage.readRefreshToken(), 'rotated');
      verify(secureStorage.writeRefreshToken('rotated')).called(2);

      // Persisted now, so the next read goes to storage again
      expect(await storage.readRefreshToken(), 'rotated');
      verify(secureStorage.readRefreshToken()).called(1);
    });

    test('is dropped when the credentials are cleared', () async {
      when(secureStorage.writeRefreshToken(any)).thenThrow(keychainLocked);
      when(secureStorage.deleteRefreshToken()).thenAnswer((_) async {});
      when(secureStorage.readRefreshToken()).thenAnswer((_) async => null);
      await storage.updateJwt(
        credential: const JwtCredential(accessToken: 'access2'),
        refreshToken: 'rotated',
      );

      await storage.clearCredentials();

      expect(await storage.readRefreshToken(), isNull);
    });
  });
}
