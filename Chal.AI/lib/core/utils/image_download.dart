export 'image_download_stub.dart'
    if (dart.library.js_interop) 'image_download_web.dart'
    if (dart.library.io) 'image_download_io.dart';
