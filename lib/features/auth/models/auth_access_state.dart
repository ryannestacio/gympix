import 'auth_session.dart';

enum AuthAccessStatus { loading, unauthenticated, unauthorized, authorized }

class AuthAccessState {
  const AuthAccessState._({required this.status, this.session, this.reason});

  const AuthAccessState.loading() : this._(status: AuthAccessStatus.loading);

  const AuthAccessState.unauthenticated()
    : this._(status: AuthAccessStatus.unauthenticated);

  const AuthAccessState.unauthorized({String? reason})
    : this._(status: AuthAccessStatus.unauthorized, reason: reason);

  const AuthAccessState.authorized(AuthSession session)
    : this._(status: AuthAccessStatus.authorized, session: session);

  final AuthAccessStatus status;
  final AuthSession? session;
  final String? reason;

  bool get isAuthorized => status == AuthAccessStatus.authorized;
}
