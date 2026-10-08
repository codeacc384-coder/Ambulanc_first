import 'package:ambulance_first/core/config/supabase_config.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> initializeTestEnvironment() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Widget tests do not need a real Supabase client. Initializing it here
  // creates an HttpClient outside the Flutter test zone and fails with a
  // "There is no current invoker" error.
  await SupabaseConfig.load();
}