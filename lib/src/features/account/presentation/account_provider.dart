import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/backend/firebase_bootstrap.dart';
import '../../../core/result/app_result.dart';
import '../data/auth_repository.dart';

enum AccountStatus { signedOut, signingIn, signedIn }

class AccountState {
  final AccountStatus status;
  final AppUser? user;
  final String? errorMessage;

  const AccountState({
    this.status = AccountStatus.signedOut,
    this.user,
    this.errorMessage,
  });

  AccountState copyWith({
    AccountStatus? status,
    AppUser? user,
    String? errorMessage,
  }) {
    return AccountState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (_) => throw UnimplementedError('Override authRepositoryProvider'),
);

class AccountNotifier extends Notifier<AccountState> {
  StreamSubscription<AppUser?>? _sub;

  @override
  AccountState build() {
    final ready = ref.watch(firebaseReadyProvider);
    ref.onDispose(() => _sub?.cancel());
    if (!ready) return const AccountState();
    final repo = ref.watch(authRepositoryProvider);
    _sub?.cancel();
    _sub = repo.authChanges().listen((user) {
      if (!ref.mounted) return;
      state = user == null
          ? const AccountState()
          : AccountState(status: AccountStatus.signedIn, user: user);
    });
    final current = repo.currentUser;
    return current == null
        ? const AccountState()
        : AccountState(status: AccountStatus.signedIn, user: current);
  }

  Future<void> signIn() async {
    state = state.copyWith(
      status: AccountStatus.signingIn,
      errorMessage: null,
    );
    final res = await ref.read(authRepositoryProvider).signInWithGoogle();
    if (!ref.mounted) return;
    switch (res) {
      case AppOk():
        // authChanges listener flips state to signedIn.
        break;
      case AppErr(message: final m):
        state = state.copyWith(
          status: AccountStatus.signedOut,
          errorMessage: m,
        );
    }
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    if (!ref.mounted) return;
    state = const AccountState();
  }
}

final accountProvider = NotifierProvider<AccountNotifier, AccountState>(
  AccountNotifier.new,
);
