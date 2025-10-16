package io.flutter.embedding.android;

import android.app.Activity;
import android.os.Bundle;

/**
 * Minimal stand-in for Flutter's FlutterActivity that allows the Android module
 * to compile in environments where the Flutter engine is unavailable.
 */
public class FlutterActivity extends Activity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }
}
