import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auth_access_state.dart';
import '../providers/auth_providers.dart';

class SessionGate extends ConsumerWidget {
  const SessionGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(authAccessSnapshotProvider);
    if (access.status == AuthAccessStatus.authorized) {
      return child;
    }

    // O redirecionamento do router resolve estados nao autorizados.
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
