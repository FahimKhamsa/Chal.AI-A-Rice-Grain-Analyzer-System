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

  /// Base URL of the FastAPI backend — NO trailing slash.
  static const String baseUrl = 'http://localhost:8000';
  //  ↑ Works via USB debugging because `adb reverse tcp:8000 tcp:8000`
  //    tunnels your PC's port 8000 directly to the phone over USB.
  //    Re-run `adb reverse tcp:8000 tcp:8000` if you unplug/replug the cable.
  //    Replace with your LAN IP when running on a physical device.
  //    Example for physical device on same WiFi: 'http://192.168.1.105:8000'

  /// Analyze endpoint
  static const String analyzeEndpoint = '$baseUrl/analyze';

  /// Health check endpoint
  static const String healthEndpoint = '$baseUrl/health';

  /// Request timeout — the pipeline can take a few seconds on CPU
  static const Duration requestTimeout = Duration(seconds: 60);
}
