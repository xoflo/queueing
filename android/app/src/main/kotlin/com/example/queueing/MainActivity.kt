package com.example.queueing

import android.app.admin.DevicePolicyManager
import android.app.ActivityManager
import android.content.ComponentName
import android.content.Context
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import android.view.View
import android.os.BatteryManager
import android.net.wifi.WifiManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel


class MainActivity : FlutterActivity() {

    private val CHANNEL = "battery.channel"
    private var wifiLock: WifiManager.WifiLock? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call, result ->
            if (call.method == "getBatteryLevel") {
                val batteryLevel = getBatteryLevel()
                result.success(batteryLevel)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getBatteryLevel(): Int {
        val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        return batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
    }


    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        whitelistAppForLockTask()
        acquireWifiLock()

        window.decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                        or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                        or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                        or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                        or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                        or View.SYSTEM_UI_FLAG_FULLSCREEN
                )


    }

    // Keeps the Wi-Fi radio out of low-power/doze mode for as long as the
    // app is alive. Standard, long-documented Android API (WIFI_MODE_FULL_HIGH_PERF
    // is marked deprecated since API 29 but still functional) — this is what
    // VOIP/streaming apps use to stop the radio from sleeping and dropping
    // the connection on its own. Some budget/OEM Android builds layer their
    // own power management on top and may ignore this; worth monitoring on
    // this specific kiosk hardware to confirm it actually helps.
    private fun acquireWifiLock() {
        try {
            val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            wifiLock = wifiManager.createWifiLock(WifiManager.WIFI_MODE_FULL_HIGH_PERF, "kiosk_wifi_lock")
            wifiLock?.setReferenceCounted(false)
            wifiLock?.acquire()
            Log.i("MainActivity", "Wifi high-perf lock acquired")
        } catch (e: Exception) {
            Log.e("MainActivity", "Failed to acquire wifi lock: ${e.message}")
        }
    }

    override fun onDestroy() {
        try {
            if (wifiLock?.isHeld == true) {
                wifiLock?.release()
                Log.i("MainActivity", "Wifi high-perf lock released")
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Failed to release wifi lock: ${e.message}")
        }
        super.onDestroy()
    }

    override fun onResume() {
        super.onResume()
        window.decorView.postDelayed({
            startLockTaskIfAllowed()
        }, 1000)
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            window.decorView.systemUiVisibility = (
                    View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                            or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                            or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                            or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                            or View.SYSTEM_UI_FLAG_FULLSCREEN
                            or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                    )
        }
    }

    private fun whitelistAppForLockTask() {
        try {
            val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
            val adminComponent = ComponentName(this, MyDeviceAdminReceiver::class.java)

            // This tells the system that this app is allowed to use Lock Task Mode
            dpm.setLockTaskPackages(adminComponent, arrayOf(packageName))
            Log.i("MainActivity", "Lock task package set successfully")
        } catch (e: Exception) {
            Log.e("MainActivity", "Failed to set lock task package: ${e.message}")
        }
    }

    private fun startLockTaskIfAllowed() {
        try {
            val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            if (activityManager.lockTaskModeState == ActivityManager.LOCK_TASK_MODE_NONE) {
                startLockTask()
                Log.i("MainActivity", "Lock task started")
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Failed to start lock task: ${e.message}")
        }
    }
}