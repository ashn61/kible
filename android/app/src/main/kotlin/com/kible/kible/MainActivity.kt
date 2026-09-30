package com.kible.kible

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "kible/native")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // Widget'ları, kalıcı bildirimi ve sonraki vakit alarmını yeniler.
                    "refresh" -> {
                        KibleUpdater.refresh(applicationContext)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
