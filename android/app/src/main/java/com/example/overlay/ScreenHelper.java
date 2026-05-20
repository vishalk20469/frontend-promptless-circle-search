package com.example.overlay;

import android.content.Context;
import android.graphics.PixelFormat;
import android.hardware.display.DisplayManager;
import android.media.Image;
import android.media.ImageReader;
import android.media.projection.MediaProjection;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.Display;
import android.view.WindowManager;

import java.nio.ByteBuffer;

public class ScreenHelper {
    private static final String TAG = "ScreenCaptureHelper";
    private static MediaProjection mediaProjection;
    private static ImageReader imageReader;
    private static int screenWidth;
    private static int screenHeight;
    private static int screenDensity;

    /**
     * Configure the MediaProjection instance.
     */
    public static void configure(MediaProjection projection) {
        mediaProjection = projection;
        Log.d(TAG, "MediaProjection configured");
    }

    /**
     * Check if the MediaProjection is ready for screen capture.
     */
    public static boolean isReady() {
        return mediaProjection != null;
    }

    /**
     * Initialize the screen capture setup.
     */
    public static void initialize(Context context) {
        // Get screen dimensions and density.
        WindowManager windowManager = (WindowManager) context.getSystemService(Context.WINDOW_SERVICE);
        Display display = windowManager.getDefaultDisplay();
        DisplayMetrics metrics = new DisplayMetrics();
        display.getMetrics(metrics);
        screenWidth = metrics.widthPixels;
        screenHeight = metrics.heightPixels;
        screenDensity = metrics.densityDpi;

        // Create an ImageReader to capture the screen.
        imageReader = ImageReader.newInstance(
                screenWidth, screenHeight, PixelFormat.RGBA_8888, 2
        );
        Log.d(TAG, "ImageReader initialized");
    }

    /**
     * Capture the screen and return the image as a byte array.
     */
    public static byte[] capture(Context context) {
        if (mediaProjection == null) {
            Log.e(TAG, "MediaProjection not configured");
            return null;
        }

        try {
            // Start the screen capture.
            mediaProjection.createVirtualDisplay(
                    "ScreenCapture",
                    screenWidth, screenHeight, screenDensity,
                    DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                    imageReader.getSurface(), null, null
            );

            // Acquire the latest image.
            Image image = imageReader.acquireLatestImage();
            if (image == null) {
                Log.e(TAG, "Failed to acquire image");
                return null;
            }

            // Convert the image to a byte array.
            byte[] imageData = imageToByteArray(image);
            image.close();
            Log.d(TAG, "Screen capture successful");
            return imageData;
        } catch (Exception e) {
            Log.e(TAG, "Error capturing screen: " + e.getMessage());
            return null;
        }
    }

    /**
     * Convert an Image to a byte array.
     */
    private static byte[] imageToByteArray(Image image) {
        Image.Plane[] planes = image.getPlanes();
        ByteBuffer buffer = planes[0].getBuffer();
        byte[] data = new byte[buffer.remaining()];
        buffer.get(data);
        return data;
    }

    /**
     * Release resources used for screen capture.
     */
    public static void releaseResources() {
        if (mediaProjection != null) {
            mediaProjection.stop();
            mediaProjection = null;
            Log.d(TAG, "MediaProjection resources released");
        }

        if (imageReader != null) {
            imageReader.close();
            imageReader = null;
            Log.d(TAG, "ImageReader resources released");
        }
    }
}