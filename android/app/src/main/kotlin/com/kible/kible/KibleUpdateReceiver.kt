package com.kible.kible

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Vakit girişinde, açılışta ve saat/saat dilimi değişikliğinde güncelleme yapar. */
class KibleUpdateReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        KibleUpdater.refresh(context)
    }

    companion object {
        const val ACTION_TICK = "com.kible.kible.PRAYER_TICK"
    }
}
