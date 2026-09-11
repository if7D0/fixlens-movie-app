import 'dart:async';

import 'package:fixlens_movie_app/src/core/backend/firebase_bootstrap.dart';
import 'package:fixlens_movie_app/src/core/result/app_result.dart';
import 'package:fixlens_movie_app/src/features/account/data/auth_repository.dart';
import 'package:fixlens_movie_app/src/features/account/presentation/account_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Controllable fake (no Firebase). Requires AuthRepository to be abstract.
class FakeAuthRepository implements AuthRepository {
  final _controller = StreamController<AppUser?>.broadcast();

  AppUser? current;
  AppResult<AppUser>? nextSignIn;
  int signInCalls = 0;

  void emit(AppUser? user) {
    current = user;
    _controller.add(user);
  }

  @override
  Stream<AppUser?> authChanges() => _controller.stream;

  @override
  AppUser? get currentUser => current;

  @override
  Future<AppResult<AppUser>> signInWithGoogle() async {
    signInCalls++;
    final res = nextSignIn ?? const AppErr<AppUser>('palsu');
    if (res is AppOk<AppUser>) emit(res.data);
    return res;
  }

  @override
  Future<void> signOut() async => emit(null);
}

const _user = AppUser(
  uid: 'u1',
  displayName: 'Tester',
  email: 't@x.id',
  photoUrl: null,
);

ProviderContainer makeAccountContainer(FakeAuthRepository fake) {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(fake),
      firebaseReadyProvider.overrideWithValue(true),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('signIn success flips to signedIn', () async {
    final fake = FakeAuthRepository()
      ..nextSignIn = const AppOk<AppUser>(_user);
    final container = makeAccountContainer(fake);
    final notifier = container.read(accountProvider.notifier);

    await notifier.signIn();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final state = container.read(accountProvider);
    expect(state.status, AccountStatus.signedIn);
    expect(state.user?.uid, 'u1');
  });

  test('signIn error stays signedOut with message', () async {
    final fake = FakeAuthRepository()
      ..nextSignIn = const AppErr<AppUser>('Login dibatalkan.');
    final container = makeAccountContainer(fake);

    await container.read(accountProvider.notifier).signIn();

    final state = container.read(accountProvider);
    expect(state.status, AccountStatus.signedOut);
    expect(state.errorMessage, 'Login dibatalkan.');
  });

  test('signOut clears user', () async {
    final fake = FakeAuthRepository()..emit(_user);
    final container = makeAccountContainer(fake);

    await container.read(accountProvider.notifier).signOut();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final state = container.read(accountProvider);
    expect(state.status, AccountStatus.signedOut);
    expect(state.user, isNull);
  });
}
