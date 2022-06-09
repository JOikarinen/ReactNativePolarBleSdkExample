package com.reactnativepolarblesdk

import android.util.Log
import android.util.Pair
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.polar.sdk.api.PolarBleApi
import com.polar.sdk.api.PolarBleApiCallback
import com.polar.sdk.api.PolarBleApiDefaultImpl
import com.polar.sdk.api.errors.PolarInvalidArgument
import com.polar.sdk.api.model.PolarDeviceInfo
import com.polar.sdk.api.model.PolarEcgData
import com.polar.sdk.api.model.PolarHrData
import com.polar.sdk.api.model.PolarSensorSetting
import io.reactivex.rxjava3.android.schedulers.AndroidSchedulers
import io.reactivex.rxjava3.core.Flowable
import io.reactivex.rxjava3.core.Single
import java.util.*

class PolarBleSdkModule(reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext) {
    companion object {
        private const val TAG = "PolarBleSdkModule"
        private const val API_LOGGER_TAG = "API LOGGER"
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

    @ReactMethod
    fun connectToDevice(deviceId: String) {
        Log.d(TAG, "connectToDevice called")
        try {
            api.connectToDevice(deviceId)
        } catch (polarInvalidArgument: PolarInvalidArgument) {
            Log.e(TAG, "Failed to connect. Reason $polarInvalidArgument ")
        }
    }

    @ReactMethod
    fun startEcgStream(deviceId: String) {
        Log.d(TAG, "startEcgStream called")
        requestStreamSettings(deviceId, PolarBleApi.DeviceStreamingFeature.ECG)
            .flatMap { settings: PolarSensorSetting ->
                api.startEcgStreaming(deviceId, settings)
            }
            .subscribe(
                { polarEcgData: PolarEcgData ->
                    for (microVolts in polarEcgData.samples) {
                        Log.d(TAG, "    yV: $microVolts")
                    }
                },
                { error: Throwable ->
                    Log.e(TAG, "ECG stream failed. Reason $error")
                },
                { Log.d(TAG, "ECG stream complete") }
            )
    }

    private fun requestStreamSettings(identifier: String, feature: PolarBleApi.DeviceStreamingFeature): Flowable<PolarSensorSetting> {
        val availableSettings = api.requestStreamSettings(identifier, feature)
            .observeOn(AndroidSchedulers.mainThread())
            .onErrorReturn { error: Throwable ->
                val errorString = "Settings are not available for feature $feature. REASON: $error"
                Log.w(TAG, errorString)
                PolarSensorSetting(emptyMap())
            }
        val allSettings = api.requestFullStreamSettings(identifier, feature)
            .onErrorReturn { error: Throwable ->
                Log.w(TAG, "Full stream settings are not available for feature $feature. REASON: $error")
                PolarSensorSetting(emptyMap())
            }
        return Single.zip(availableSettings, allSettings) { available: PolarSensorSetting, all: PolarSensorSetting ->
            if (available.settings.isEmpty()) {
                throw Throwable("Settings are not available")
            } else {
                Log.d(TAG, "Feature " + feature + " available settings " + available.settings)
                Log.d(TAG, "Feature " + feature + " all settings " + all.settings)
                return@zip Pair(available, all)
            }
        }
            .observeOn(AndroidSchedulers.mainThread())
            .toFlowable()
            .map { sensorSettings: Pair<PolarSensorSetting, PolarSensorSetting> ->
                sensorSettings.first.maxSettings()
            }
    }
}
