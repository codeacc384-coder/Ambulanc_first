import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/auth_user.dart' as app_models;
import 'supabase_service.dart';

/// Supabase authentication repository for Ambulance First.
///
/// Authentication source:
///   Supabase Auth
///
/// User/profile source:
///   profiles table
///
/// Role source:
///   profiles.role
///
/// No demo users, hardcoded accounts, fake IDs, or local authentication
/// are used here.
class SupabaseAuthRepository {
  SupabaseClient get _db => SupabaseService.client;

  // ===========================================================================
  // CURRENT USER
  // ===========================================================================

  Future<app_models.AuthUser?> currentUser() async {
    final user = _db.auth.currentUser;

    if (user == null) {
      return null;
    }

    return profileForUser(user);
  }

  // ===========================================================================
  // LOGIN
  // ===========================================================================

  Future<app_models.AuthUser> signIn({
    required String identifier,
    required String password,
  }) async {
    final trimmedIdentifier = identifier.trim();

    if (trimmedIdentifier.isEmpty) {
      throw const AuthException(
        'Please enter your email address or mobile number.',
      );
    }

    if (password.isEmpty) {
      throw const AuthException(
        'Please enter your password.',
      );
    }

    AuthResponse response;

    // Email login
    if (trimmedIdentifier.contains('@')) {
      response = await _db.auth.signInWithPassword(
        email: trimmedIdentifier.toLowerCase(),
        password: password,
      );
    }

    // Mobile login
    else {
      response = await _db.auth.signInWithPassword(
        phone: trimmedIdentifier,
        password: password,
      );
    }

    final user = response.user;

    if (user == null) {
      throw const AuthException(
        'Authentication failed. No authenticated user was returned.',
      );
    }

    // Authentication succeeded.
    // Now load the real profile from Supabase.
    return profileForUser(user);
  }

  // ===========================================================================
  // REGISTER CUSTOMER
  // ===========================================================================

  Future<app_models.AuthUser?> registerCustomer({
    required String fullName,
    required String identifier,
    required String mobile,
    required String password,
  }) async {
    final name = fullName.trim();
    final trimmedIdentifier = identifier.trim();
    final phone = mobile.trim();

    if (name.isEmpty) {
      throw const AuthException(
        'Full name is required.',
      );
    }

    if (trimmedIdentifier.isEmpty) {
      throw const AuthException(
        'Email address or mobile number is required.',
      );
    }

    if (phone.isEmpty) {
      throw const AuthException(
        'Mobile number is required.',
      );
    }

    if (password.length < 6) {
      throw const AuthException(
        'Password must contain at least 6 characters.',
      );
    }

    final metadata = <String, dynamic>{
      'full_name': name,
      'name': name,
      'phone': phone,

      // Self-registration can ONLY create a customer.
      //
      // Operational roles such as DRIVER, TEAM_LEAD, CUSTOMER_CARE,
      // DOCTOR and ADMIN must be provisioned by the backend/admin system.
      'role': 'CUSTOMER',
    };

    AuthResponse response;

    if (trimmedIdentifier.contains('@')) {
      response = await _db.auth.signUp(
        email: trimmedIdentifier.toLowerCase(),
        password: password,
        data: metadata,
      );
    } else {
      response = await _db.auth.signUp(
        phone: trimmedIdentifier,
        password: password,
        data: metadata,
      );
    }

    final user = response.user;

    if (user == null) {
      return null;
    }

    // Supabase can require email/phone confirmation.
    //
    // In that case user exists but there is no active session yet.
    if (response.session == null) {
      return null;
    }

    return profileForUser(user);
  }

  // ===========================================================================
  // LOGOUT
  // ===========================================================================

  Future<void> signOut() async {
    await _db.auth.signOut();
  }

  // ===========================================================================
  // LOAD PROFILE
  // ===========================================================================

  Future<app_models.AuthUser> profileForUser(User user) async {
    Map<String, dynamic>? row;

    // -------------------------------------------------------------------------
    // Primary profile relationship:
    //
    // profiles.id = auth.users.id
    // -------------------------------------------------------------------------

    try {
      final result = await _db
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (result != null) {
        row = Map<String, dynamic>.from(result);
      }
    } catch (_) {
      // Some schemas use profiles.user_id instead.
      // Try that only if the primary query fails.
    }

    // -------------------------------------------------------------------------
    // Alternate relationship:
    //
    // profiles.user_id = auth.users.id
    // -------------------------------------------------------------------------

    if (row == null) {
      try {
        final result = await _db
            .from('profiles')
            .select()
            .eq('user_id', user.id)
            .maybeSingle();

        if (result != null) {
          row = Map<String, dynamic>.from(result);
        }
      } catch (_) {
        // Ignore here and report a clear profile error below.
      }
    }

    // -------------------------------------------------------------------------
    // Profile does not exist
    // -------------------------------------------------------------------------

    if (row == null) {
      throw StateError(
        'Authenticated user has no matching profiles row. '
        'The Supabase Auth account exists, but its profile has not been '
        'created in the profiles table.',
      );
    }

    // -------------------------------------------------------------------------
    // ROLE
    // -------------------------------------------------------------------------

    final role = _normalizeRole(
      row['role']?.toString(),
    );

    if (role == null) {
      throw StateError(
        'The profiles row contains an unsupported or missing role.',
      );
    }

    // -------------------------------------------------------------------------
    // Build AuthUser entirely from Supabase data
    // -------------------------------------------------------------------------

    return app_models.AuthUser(
      id: _firstNonEmpty([
        row['id'],
        row['user_id'],
        user.id,
      ]),
      name: _firstNonEmpty([
        row['full_name'],
        row['name'],
        user.userMetadata?['full_name'],
        user.userMetadata?['name'],
      ]),
      email: _firstNonEmpty([
        row['email'],
        user.email,
      ]),
      phone: _firstNonEmpty([
        row['phone'],
        user.phone,
        user.userMetadata?['phone'],
      ]),
      role: role,
    );
  }

  // ===========================================================================
  // ROLE NORMALIZATION
  // ===========================================================================

  String? _normalizeRole(String? raw) {
    if (raw == null) {
      return null;
    }

    switch (raw.trim().toUpperCase()) {
      case 'CUSTOMER':
        return 'CUSTOMER';

      case 'CUSTOMER_CARE':
      case 'CUSTOMER CARE':
        return 'CUSTOMER_CARE';

      case 'TEAM_LEAD':
      case 'TEAM LEAD':
        return 'TEAM_LEAD';

      case 'DRIVER':
        return 'DRIVER';

      case 'DOCTOR':
        return 'DOCTOR';

      case 'ADMIN':
        return 'ADMIN';

      default:
        return null;
    }
  }

  // ===========================================================================
  // FIRST NON-EMPTY VALUE
  // ===========================================================================

  String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';

      if (text.isNotEmpty) {
        return text;
      }
    }

    return '';
  }
}