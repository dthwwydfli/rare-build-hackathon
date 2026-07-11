package com.example.accountability_app

import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.accountability/usage_stats"

    private val gamblingPackages = setOf(
        "com.bet365",
        "com.paddypower",
        "com.williamhill",
        "com.ladbrokes",
        "com.betway",
        "com.skybet",
        "com.betfair",
        "com.betfred",
        "com.unibet",
        "com.pokerstars"
    )

    private val gamblingDisplayNames = mapOf(
        "com.bet365" to "Bet365",
        "com.paddypower" to "Paddy Power",
        "com.williamhill" to "William Hill",
        "com.ladbrokes" to "Ladbrokes",
        "com.betway" to "Betway",
        "com.skybet" to "Sky Bet",
        "com.betfair" to "Betfair",
        "com.betfred" to "Betfred",
        "com.unibet" to "Unibet",
        "com.pokerstars" to "PokerStars"
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getForegroundApp" -> {
                        val foreground = getForegroundPackage()
                        if (foreground == null) {
                            result.success(null)
                        } else {
                            val isGambling = gamblingPackages.contains(foreground)
                            result.success(
                                mapOf(
                                    "packageName" to foreground,
                                    "appName" to (gamblingDisplayNames[foreground] ?: foreground),
                                    "isGambling" to isGambling
                                )
                            )
                        }
                    }
                    "requestUsagePermission" -> {
                        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun getForegroundPackage(): String? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) return null
        val usageStatsManager =
            getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val end = System.currentTimeMillis()
        val begin = end - 60_000
        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            begin,
            end
        ) ?: return null

        var recentPackage: String? = null
        var recentTime = 0L
        for (stat in stats) {
            if (stat.lastTimeUsed > recentTime) {
                recentTime = stat.lastTimeUsed
                recentPackage = stat.packageName
            }
        }
        return recentPackage
    }
}
