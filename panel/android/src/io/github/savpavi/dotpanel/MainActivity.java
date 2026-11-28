package io.github.savpavi.dotpanel;

import android.app.Activity;
import android.app.admin.DevicePolicyManager;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.graphics.Color;
import android.os.BatteryManager;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.provider.Settings;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.view.WindowInsets;
import android.view.WindowInsetsController;
import android.view.WindowManager;
import android.webkit.WebResourceError;
import android.webkit.WebResourceRequest;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.FrameLayout;
import android.widget.TextView;

/**
 * Full-screen panel: shows dot-panel (served by the computer through adb reverse) in a
 * WebView, keeps the screen on and hides the system bars.
 *
 * As the home app it opens on boot and on Home. As device owner it also pins itself
 * (lock task), turns off the keyguard and keeps the screen awake while plugged in.
 *
 * Way out for maintenance: tap the top-left corner five times quickly. That leaves
 * lock task and opens Android settings.
 */
public class MainActivity extends Activity {
    private static final String URL = "http://localhost:8777/";
    private static final long RETRY_MS = 3000;
    private static final int CORNER_DP = 72;
    private static final int TAPS = 5;
    private static final long TAP_WINDOW_MS = 2500;

    private final Handler handler = new Handler(Looper.getMainLooper());
    private WebView web;
    private TextView status;
    private boolean failed;
    private int taps;
    private long firstTap;

    private final Runnable retry = new Runnable() {
        @Override public void run() {
            failed = false;
            web.loadUrl(URL);
        }
    };

    @Override
    protected void onCreate(Bundle state) {
        super.onCreate(state);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        getWindow().getAttributes().layoutInDisplayCutoutMode =
                WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES;
        setShowWhenLocked(true);
        setTurnScreenOn(true);

        FrameLayout root = new FrameLayout(this);
        root.setBackgroundColor(Color.BLACK);

        web = new WebView(this);
        web.setBackgroundColor(Color.BLACK);
        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setMediaPlaybackRequiresUserGesture(false);
        s.setCacheMode(WebSettings.LOAD_NO_CACHE);
        s.setAllowFileAccess(false);
        s.setAllowContentAccess(false);
        web.setOverScrollMode(View.OVER_SCROLL_NEVER);
        web.setWebViewClient(new WebViewClient() {
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest req) {
                // Stay on the panel: never follow links elsewhere.
                return !req.getUrl().toString().startsWith(URL);
            }

            @Override
            public void onReceivedError(WebView view, WebResourceRequest req, WebResourceError err) {
                if (req.isForMainFrame()) {
                    failed = true;
                    showStatus("PC bekleniyor…\nkablo takılınca kendiliğinden bağlanır");
                    handler.removeCallbacks(retry);
                    handler.postDelayed(retry, RETRY_MS);
                }
            }

            @Override
            public void onPageFinished(WebView view, String url) {
                if (!failed) status.setVisibility(View.GONE);
            }
        });
        root.addView(web, new FrameLayout.LayoutParams(-1, -1));

        status = new TextView(this);
        status.setTextColor(0xFFECE6D9);
        status.setTextSize(18);
        status.setGravity(Gravity.CENTER);
        status.setBackgroundColor(0xFF1B1A17);
        status.setText("Panel açılıyor…");
        root.addView(status, new FrameLayout.LayoutParams(-1, -1));

        setContentView(root);
        kiosk();
        web.loadUrl(URL);
    }

    private void showStatus(String text) {
        status.setText(text);
        status.setVisibility(View.VISIBLE);
    }

    /** Device-owner extras; silently skipped when the app is only the home screen. */
    private void kiosk() {
        DevicePolicyManager dpm = (DevicePolicyManager) getSystemService(Context.DEVICE_POLICY_SERVICE);
        if (dpm == null || !dpm.isDeviceOwnerApp(getPackageName())) return;
        ComponentName admin = new ComponentName(this, AdminReceiver.class);
        try {
            dpm.setLockTaskPackages(admin, new String[] {getPackageName()});
            dpm.setKeyguardDisabled(admin, true);
            dpm.setStatusBarDisabled(admin, true);
            int plugged = BatteryManager.BATTERY_PLUGGED_AC | BatteryManager.BATTERY_PLUGGED_USB
                    | BatteryManager.BATTERY_PLUGGED_WIRELESS;
            dpm.setGlobalSetting(admin, Settings.Global.STAY_ON_WHILE_PLUGGED_IN, String.valueOf(plugged));
            startLockTask();
        } catch (SecurityException | IllegalStateException e) {
            // Partial support on some ROMs; the panel still works without these.
        }
    }

    private void leave() {
        try {
            stopLockTask();
        } catch (IllegalStateException ignored) {
        }
        DevicePolicyManager dpm = (DevicePolicyManager) getSystemService(Context.DEVICE_POLICY_SERVICE);
        if (dpm != null && dpm.isDeviceOwnerApp(getPackageName())) {
            try {
                dpm.setStatusBarDisabled(new ComponentName(this, AdminReceiver.class), false);
            } catch (SecurityException ignored) {
            }
        }
        startActivity(new Intent(Settings.ACTION_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));
    }

    @Override
    public boolean dispatchTouchEvent(MotionEvent ev) {
        if (ev.getActionMasked() == MotionEvent.ACTION_DOWN) {
            float corner = CORNER_DP * getResources().getDisplayMetrics().density;
            if (ev.getX() < corner && ev.getY() < corner) {
                long now = System.currentTimeMillis();
                if (taps == 0 || now - firstTap > TAP_WINDOW_MS) {
                    taps = 0;
                    firstTap = now;
                }
                if (++taps >= TAPS) {
                    taps = 0;
                    leave();
                }
            } else {
                taps = 0;
            }
        }
        return super.dispatchTouchEvent(ev);
    }

    private void hideBars() {
        WindowInsetsController c = getWindow().getInsetsController();
        if (c != null) {
            c.hide(WindowInsets.Type.systemBars());
            c.setSystemBarsBehavior(WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE);
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        hideBars();
        web.onResume();
        kiosk();
    }

    @Override
    protected void onPause() {
        web.onPause();
        super.onPause();
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        if (hasFocus) hideBars();
    }

    @Override
    public void onBackPressed() {
        // The panel is the whole app: Back does nothing.
    }

    @Override
    protected void onDestroy() {
        handler.removeCallbacksAndMessages(null);
        web.destroy();
        super.onDestroy();
    }
}
