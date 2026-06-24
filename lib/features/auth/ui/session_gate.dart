import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/auth_access_state.dart';
import '../providers/auth_providers.dart';

class SessionGate extends ConsumerWidget {
  const SessionGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authAccessStateProvider, (previous, next) {
      final status = next.asData?.value.status;
      if (status == AuthAccessStatus.unauthenticated ||
          status == AuthAccessStatus.unauthorized) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          context.go(
            status == AuthAccessStatus.unauthorized
                ? '/access-denied'
                : '/login',
          );
        });
      }
    });

    final access = ref.watch(authAccessSnapshotProvider);
    if (access.status == AuthAccessStatus.authorized) {
      return child;
    }

    // O redirecionamento do router resolve estados nao autorizados.
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
