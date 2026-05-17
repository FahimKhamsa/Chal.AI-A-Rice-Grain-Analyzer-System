// lib/core/config/api_config.dart
//
// Central place to configure the Chal.AI backend URL.
// ─────────────────────────────────────────────────────────────────────────────
// DEVELOPMENT (phone on same WiFi as dev machine):
//   1. Find your machine's LAN IP:
//        Windows: ipconfig  → "IPv4 Address" e.g. 192.168.1.105
//        macOS:   ifconfig  → en0 inet       e.g. 192.168.1.105
//   2. Set baseUrl below to http://<that-ip>:8000
//   3. On Android you ALSO need cleartext traffic allowed — see
//        android/app/src/main/AndroidManifest.xml  (already configured below)
//
// PRODUCTION (cloud):
//   Replace with your cloud URL, e.g. https://chalai-api.onrender.com
// ─────────────────────────────────────────────────────────────────────────────

class ApiConfig {
  ApiConfig._(); // prevent instantiation

  // ── Local FastAPI backend (development only) ───────────────────────────────
  /// Base URL of the FastAPI backend — NO trailing slash.
  static const String baseUrl = String.fromEnvironment('LOCAL_API_BASE_URL',
      defaultValue: 'http://localhost:8000');

  static const String analyzeEndpoint = '$baseUrl/api/v1/rice';
  static const String healthEndpoint = '$baseUrl/health';
  static const Duration requestTimeout = Duration(seconds: 60);

  // ── RunPod Serverless ──────────────────────────────────────────────────────
  // Values are injected at build time from .env.json via --dart-define-from-file.
  // Never hardcode secrets here — .env.json is gitignored.

  static const String runpodEndpointId =
      String.fromEnvironment('RUNPOD_ENDPOINT_ID');

  static const String runpodApiKey = String.fromEnvironment('RUNPOD_API_KEY');

  // ── Supabase Storage (input image uploads) ─────────────────────────────────
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  static const String supabaseUploadBucket = String.fromEnvironment(
      'SUPABASE_UPLOAD_BUCKET',
      defaultValue: 'rice-uploads');
}
