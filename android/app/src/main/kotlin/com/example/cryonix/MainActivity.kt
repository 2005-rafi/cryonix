package com.example.cryonix

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity is required by local_auth for biometric authentication.
class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // GAP 4 — Prevent screenshots and app-switcher previews from capturing sensitive data.
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }
}
