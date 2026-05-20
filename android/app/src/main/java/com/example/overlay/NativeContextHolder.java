package com.example.overlay;

import android.content.Context;

public class NativeContextHolder {
    private static Context appContext;

    public static void setApplicationContext(Context context) {
        appContext = context;
    }

    public static Context getApplicationContext() {
        return appContext;
    }
}