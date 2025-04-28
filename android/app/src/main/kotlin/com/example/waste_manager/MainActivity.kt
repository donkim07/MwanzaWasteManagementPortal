
package tz.co.wastemanagementportal

import android.os.Build
import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Enable edge-to-edge display (works for Android 15 and maintains backward compatibility)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // For Android 12 (S) and above
            androidx.core.view.WindowCompat.setDecorFitsSystemWindows(window, false)
        } else {
            // For older Android versions
            window.setDecorFitsSystemWindows(false)
        }
        
        // For Android 15 specific implementation
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            // Using enableEdgeToEdge() as recommended by Google
            androidx.activity.EdgeToEdge.enable(this)
        }
    }
}