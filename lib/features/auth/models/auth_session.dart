enum TenantRole { owner, admin, staff }

class AuthSession {
  const AuthSession({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.tenantId,
    required this.role,
  });

  final String uid;
  final String email;
  final String displayName;
  final String tenantId;
  final TenantRole role;
}

class SessionLookupResult {
  const SessionLookupResult.authorized(this.session) : deniedReason = null;

  const SessionLookupResult.denied(this.deniedReason) : session = null;

  final AuthSession? session;
  final String? deniedReason;

  bool get isAuthorized => session != null;
}

TenantRole parseTenantRole(dynamic value) {
  if (value is String) {
    for (final role in TenantRole.values) {
      if (role.name == value.trim().toLowerCase()) return role;
    }
  }
  return TenantRole.staff;
}
