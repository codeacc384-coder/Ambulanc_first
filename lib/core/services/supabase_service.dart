import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

import '../config/supabase_config.dart';

/// Single bootstrap point for the existing Ambulance First Supabase project.
///
/// The project URL is fixed to the shared backend. The public publishable
/// key is supplied with --dart-define=SUPABASE_PUBLISHABLE_KEY=...
/// The legacy SUPABASE_ANON_KEY define remains supported.
class SupabaseService {
  static bool _initialized = false;
  static bool _realtimeEnabled = true;

  static String get url => SupabaseConfig.url;
  static String get publishableKey => SupabaseConfig.publishableKey;
  static bool get isConfigured => SupabaseConfig.isConfigured;
  static bool get isInitialized => _initialized;
  static bool get isRealtimeEnabled => _realtimeEnabled;

  static SupabaseClient get client {
    if (!_initialized) {
      throw StateError(
        'Supabase has not been initialized. Call SupabaseService.initialize() first.',
      );
    }
    return Supabase.instance.client;
  }

  static Future<void> initialize({
    http.Client? httpClient,
    String? urlOverride,
    String? publishableKeyOverride,
    bool enableRealtime = true,
    FlutterAuthClientOptions? authOptions,
  }) async {
    if (_initialized) return;

    final configuredUrl = urlOverride ?? url;
    final configuredKey = publishableKeyOverride ?? publishableKey;
    if (configuredKey.trim().isEmpty ||
        (urlOverride == null && !isConfigured)) {
      return;
    }

    _realtimeEnabled = enableRealtime;
    await Supabase.initialize(
      url: configuredUrl,
      publishableKey: configuredKey,
      httpClient: httpClient,
      authOptions: authOptions ?? const FlutterAuthClientOptions(),
    );
    _initialized = true;
  }
}
