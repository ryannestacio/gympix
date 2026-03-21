import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/alunos/ui/alunos_page.dart';
import '../../features/auth/models/auth_access_state.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/auth/ui/access_denied_page.dart';
import '../../features/auth/ui/login_page.dart';
import '../../features/auth/ui/session_gate.dart';
import '../../features/cobranca/ui/cobranca_page.dart';
import '../../features/configuracoes/ui/config_page.dart';
import '../../features/home/ui/home_page.dart';
import 'app_shell.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  final accessAsync = ref.watch(authAccessStateProvider);
  final access = accessAsync.asData?.value;
  final isResolving = accessAsync.isLoading && access == null;

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isLogin = location == '/login';
      final isDenied = location == '/access-denied';
      final isPublicCobranca = location == '/cobranca';

      if (isPublicCobranca) return null;

      if (isResolving) {
        return isLogin ? null : '/login';
      }

      final currentAccess = access ?? const AuthAccessState.loading();
      return switch (currentAccess.status) {
        AuthAccessStatus.loading => isLogin ? null : '/login',
        AuthAccessStatus.unauthenticated => isLogin ? null : '/login',
        AuthAccessStatus.unauthorized => isDenied ? null : '/access-denied',
        AuthAccessStatus.authorized => (isLogin || isDenied) ? '/' : null,
      };
    },
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: LoginPage()),
      ),
      GoRoute(
        path: '/access-denied',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: AccessDeniedPage()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            SessionGate(child: AppShell(navigationShell: navigationShell)),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: HomePage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/alunos',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: AlunosPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/config',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ConfigPage()),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/cobranca',
        builder: (context, state) {
          final nome = state.uri.queryParameters['nome'] ?? '';
          final pix = state.uri.queryParameters['pix'] ?? '';
          final valor = state.uri.queryParameters['valor'] ?? '';
          return CobrancaPage(nome: nome, pixCode: pix, valor: valor);
        },
      ),
    ],
    errorBuilder: (context, state) => _RouterErrorPage(error: state.error),
  );
}

class _RouterErrorPage extends StatelessWidget {
  const _RouterErrorPage({this.error});
  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: Text(error?.toString() ?? 'Rota invalida')),
    );
  }
}
