package com.reactnativepolarblesdk

import android.util.Log
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.polar.sdk.api.PolarBleApi
import com.polar.sdk.api.PolarBleApiCallback
import com.polar.sdk.api.PolarBleApiDefaultImpl
import com.polar.sdk.api.model.PolarDeviceInfo
import com.polar.sdk.api.model.PolarHrData
import io.reactivex.rxjava3.android.schedulers.AndroidSchedulers
import java.util.*

class PolarBleSdkModule(reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext) {
    companion object {
        private const val TAG = "PolarBleSdkModule"
        private const val API_LOGGER_TAG = "API LOGGER"
        private const val PERMISSION_REQUEST_CODE = 1
    }

    private val api: PolarBleApi by lazy {
        // Notice PolarBleApi.ALL_FEATURES are enabled
        PolarBleApiDefaultImpl.defaultImplementation(reactContext, PolarBleApi.ALL_FEATURES)
    }

    init {
        api.setPolarFilter(false)
        api.setApiLogger { s: String -> Log.d(API_LOGGER_TAG, s) }
        api.setApiCallback(object : PolarBleApiCallback() {
            override fun blePowerStateChanged(powered: Boolean) {
                Log.d(TAG, "BLE power: $powered")
            }

            override fun deviceConnected(polarDeviceInfo: PolarDeviceInfo) {
                Log.d(TAG, "CONNECTED: " + polarDeviceInfo.deviceId)
            }

            override fun deviceConnecting(polarDeviceInfo: PolarDeviceInfo) {
                Log.d(TAG, "CONNECTING: " + polarDeviceInfo.deviceId)
            }

            override fun deviceDisconnected(polarDeviceInfo: PolarDeviceInfo) {
                Log.d(TAG, "DISCONNECTED: " + polarDeviceInfo.deviceId)
            }

            override fun streamingFeaturesReady(identifier: String, features: Set<PolarBleApi.DeviceStreamingFeature>) {
                for (feature in features) {
                    Log.d(TAG, "Streaming feature $feature is ready")
                }
            }

            override fun hrFeatureReady(identifier: String) {
                Log.d(TAG, "HR READY: $identifier")
                // hr notifications are about to start
            }

            override fun disInformationReceived(identifier: String, uuid: UUID, value: String) {
                Log.d(TAG, "uuid: $uuid value: $value")
            }

            override fun batteryLevelReceived(identifier: String, level: Int) {
                Log.d(TAG, "BATTERY LEVEL: $level")
            }

            override fun hrNotificationReceived(identifier: String, data: PolarHrData) {
                Log.d(TAG, "HR value: ${data.hr} rrsMs: ${data.rrsMs} rr: ${data.rrs} contact: ${data.contactStatus} , ${data.contactStatusSupported}")
            }

            override fun polarFtpFeatureReady(s: String) {
                Log.d(TAG, "FTP ready")
            }
        })

    }

    override fun getName(): String {
        return "PolarBleSdkModule"
    }

    @ReactMethod
    fun searchForDevice() {
        Log.d(TAG, "searchForDevice called")
        api.searchForDevice()
            .observeOn(AndroidSchedulers.mainThread())
            .subscribe(
                { polarDeviceInfo: PolarDeviceInfo ->
                    Log.d(TAG, "polar device found id: " + polarDeviceInfo.deviceId + " address: " + polarDeviceInfo.address + " rssi: " + polarDeviceInfo.rssi + " name: " + polarDeviceInfo.name + " isConnectable: " + polarDeviceInfo.isConnectable)
                },
                { error: Throwable ->
                    Log.e(TAG, "Device scan failed. Reason $error")
                },
                { Log.d(TAG, "complete") }
            )

    }
}
