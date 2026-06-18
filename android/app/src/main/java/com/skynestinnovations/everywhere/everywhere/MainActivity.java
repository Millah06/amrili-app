package com.skynestinnovations.everywhere.everywhere;

import android.os.Bundle;

import androidx.annotation.Nullable;
import androidx.core.view.WindowCompat;

import io.flutter.embedding.android.FlutterFragmentActivity;

public class MainActivity extends FlutterFragmentActivity {

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // Flutter 3.27+ calls enableEdgeToEdge() inside the Flutter fragment's
        // lifecycle (which runs during super.onCreate above). That sets
        // decorFitsSystemWindows=false, silently disabling adjustResize so the
        // keyboard never resizes the window and viewInsets.bottom stays 0.
        //
        // Posting to the decor view's message queue runs AFTER the fragment
        // finishes attaching, so this call executes last and wins — restoring
        // classic adjustResize behavior and making every TextField rise above
        // the keyboard automatically.
        getWindow().getDecorView().post(() ->
            WindowCompat.setDecorFitsSystemWindows(getWindow(), true)
        );
    }
}
