package com.example.overlay;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.media.projection.MediaProjection;
import android.media.projection.MediaProjectionManager;
import android.os.Bundle;
import android.util.Log;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.content.ContextCompat;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

// Import your plugin’s helper class.
import flutter.overlay.window.flutter_overlay_window.ScreenCaptureHelper;
import flutter.overlay.window.flutter_overlay_window.NativeContext;

public class MainActivity extends FlutterActivity {
    private static final int REQUEST_CODE_FOR_SCREEN_CAPTURE = 1250;
    private static final String CHANNEL_MAIN = "com.example.overlay/main";
    private static final String CHANNEL_OVERLAY = "com.example.overlay/overlay_to";
    private static Context appContext;
    private MediaProjectionManager projectionManager;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        appContext = getApplicationContext();
        projectionManager = (MediaProjectionManager) getSystemService(Context.MEDIA_PROJECTION_SERVICE);

        // Start the foreground service that shows the notification (if needed).
        Intent serviceIntent = new Intent(this, ScreenCaptureForegroundService.class);
        ContextCompat.startForegroundService(this, serviceIntent);

        // Optionally, request screen capture permission immediately.
        requestCapturePermission();

        // Store the application context in your native helper.
        setupNativeContext();
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        // Register the main channel for Flutter-to-native communication.
        new MethodChannel(flutterEngine.getDartExecutor(), CHANNEL_MAIN)
                .setMethodCallHandler((call, result) -> {
                    switch (call.method) {
                        case "sendContext":
                            handleSendContext(result);
                            break;
                        case "checking":
                            result.success("Successful");
                            break;
                        default:
                            result.notImplemented();
                            break;
                    }
                });

        // Register the overlay channel for overlay-to-native communication.
        new MethodChannel(flutterEngine.getDartExecutor(), CHANNEL_OVERLAY)
                .setMethodCallHandler((call, result) -> {
                    Log.d("MainActivity", "Received overlay method: " + call.method);
                    if (call.method.equals("start_capture")) {
                        Log.d("MainActivity", "Start capture method called");
                        handleScreenCapture(result);
                    } else {
                        result.notImplemented();
                    }
                });
    }

    /**
     * Request MediaProjection permission.
     */
    private void requestCapturePermission() {
        if (projectionManager != null) {
            Intent captureIntent = projectionManager.createScreenCaptureIntent();
            startActivityForResult(captureIntent, REQUEST_CODE_FOR_SCREEN_CAPTURE);
        } else {
            Log.e("MainActivity", "ProjectionManager is null, cannot request permission");
        }
    }

    /**
     * Store the application context in the native helper.
     */
    private void setupNativeContext() {
        NativeContext.setApplicationContext(appContext);
        Log.d("MainActivity", "Application context stored");
    }

    /**
     * Handler for the "sendContext" method call.
     */
    private void handleSendContext(MethodChannel.Result result) {
        try {
            NativeContext.setApplicationContext(appContext);
            result.success(true);
            Log.d("MainActivity", "Context sent to native side");
        } catch (Exception e) {
            result.error("CONTEXT_ERROR", "Failed to send context", null);
        }
    }

    /**
     * Handler for the "start_capture" method call from the overlay channel.
     */
    private void handleScreenCapture(MethodChannel.Result result) {
        // Check if MediaProjection is ready.
        if (!ScreenCaptureHelper.isReady()) {
            result.error("NOT_READY", "MediaProjection not initialized", null);
            return;
        }
        new Thread(() -> {
            try {
                // Use the application context (or an Activity context if required).
                byte[] imageData = ScreenCaptureHelper.capture(appContext);
                result.success(imageData);
            } catch (Exception e) {
                result.error("CAPTURE_ERROR", e.getMessage(), null);
            }
        }).start();
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        if (requestCode == REQUEST_CODE_FOR_SCREEN_CAPTURE) {
            handleCapturePermissionResult(resultCode, data);
        }
        super.onActivityResult(requestCode, resultCode, data);
    }

    /**
     * Handle the result of the MediaProjection permission request.
     */
    private void handleCapturePermissionResult(int resultCode, Intent data) {
        if (resultCode == Activity.RESULT_OK && data != null) {
            MediaProjection projection = projectionManager.getMediaProjection(resultCode, data);
            // Pass the MediaProjection instance to your plugin helper.
            ScreenCaptureHelper.configure(projection);
            notifyCaptureReady();
        } else {
            Log.e("MainActivity", "Screen capture permission denied");
        }
    }

    /**
     * Notify Dart that the capture functionality is ready.
     */
    private void notifyCaptureReady() {
        new MethodChannel(getFlutterEngine().getDartExecutor(), CHANNEL_MAIN)
                .invokeMethod("on_capture_ready", null);
    }

    public static Context getAppContext() {
        return appContext;
    }
}
