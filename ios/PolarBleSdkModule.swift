//
//  PolarBleSdkModule.swift
//  ReactNativePolarBleSDK


import Foundation
import PolarBleSdk
import RxSwift
import CoreBluetooth

@objc(PolarBleSdkModule)
class PolarBleSdkModule: NSObject {
  
  private var api = PolarBleApiDefaultImpl.polarImplementation(DispatchQueue.main, features: Features.allFeatures.rawValue)
  private var isSearchOn: Bool = false
  private var searchDisposable: Disposable?
  private let disposeBag = DisposeBag()
  
  override init() {
    super.init()
    api.polarFilter(true)
    api.observer = self
    api.deviceFeaturesObserver = self
    api.powerStateObserver = self
    api.deviceInfoObserver = self
    api.sdkModeFeatureObserver = self
    api.deviceHrObserver = self
    //api.logger = self
  }
  
  @objc(searchForDevice)
  func searchForDevice() -> Void {
    NSLog("native searchForDevice called")
    if !isSearchOn {
      isSearchOn = true
      searchDisposable = api.searchForDevice()
        .observe(on: MainScheduler.instance)
        .subscribe{ e in
          switch e {
          case .completed:
            NSLog("search complete")
            self.isSearchOn = false
          case .error(let err):
            NSLog("search error: \(err)")
            self.isSearchOn = false
          case .next(let item):
            NSLog("polar device found: \(item.name) connectable: \(item.connectable) address: \(item.address.uuidString)")
          }
        }
    } else {
      isSearchOn = false
      searchDisposable?.dispose()
    }
  }
  
  @objc
  func connectToDevice(_ deviceId: String) -> Void {
    do {
      try api.connectToDevice(deviceId)
    } catch let err {
      NSLog("Failed to connect to \(deviceId). Reason \(err)")
    }
  }
  
  @objc
  func startEcgStream(_ deviceId: String) -> Void {
    getStreamSettings(deviceId: deviceId, feature:  DeviceStreamingFeature.ecg)
      .asObservable()
      .flatMap({
        (settings) -> Observable<PolarEcgData> in
        return self.api.startEcgStreaming(deviceId, settings: settings)
      }).observe(on: MainScheduler.instance)
      .subscribe{ e in
        switch e {
        case .next(let data):
          for µv in data.samples {
            NSLog("ECG    µV: \(µv)")
          }
        case .error(let err):
          NSLog("ECG stream failed: \(err)")
        case .completed:
          NSLog("ECG stream completed")
        }
      }.disposed(by: disposeBag)
  }
  
  fileprivate func getStreamSettings(deviceId: String, feature: PolarBleSdk.DeviceStreamingFeature) -> Single<PolarSensorSetting> {
    NSLog("Stream settings fetch for \(feature)")
    return api.requestStreamSettings(deviceId, feature: feature)
      .map { settings -> PolarSensorSetting in settings.maxSettings() }
  }
  
  @objc
  func constantsToExport() -> [String: Any]! {
    return ["someKey": "someValue"]
  }
  
}

// MARK: - PolarBleApiPowerStateObserver
extension PolarBleSdkModule : PolarBleApiPowerStateObserver {
  func blePowerOn() {
    NSLog("BLE ON")
  }
  
  func blePowerOff() {
    NSLog("BLE OFF")
  }
}

// MARK: - PolarBleApiObserver
extension PolarBleSdkModule : PolarBleApiObserver {
  func deviceConnecting(_ polarDeviceInfo: PolarDeviceInfo) {
    NSLog("DEVICE CONNECTING: \(polarDeviceInfo)")
    
  }
  
  func deviceConnected(_ polarDeviceInfo: PolarDeviceInfo) {
    NSLog("DEVICE CONNECTED: \(polarDeviceInfo)")
    
  }
  
  func deviceDisconnected(_ polarDeviceInfo: PolarDeviceInfo) {
    NSLog("DISCONNECTED: \(polarDeviceInfo)")
  }
}

// MARK: - PolarBleApiDeviceInfoObserver
extension PolarBleSdkModule : PolarBleApiDeviceInfoObserver {
  func batteryLevelReceived(_ identifier: String, batteryLevel: UInt) {
    NSLog("battery level updated: \(batteryLevel)")
  }
  
  func disInformationReceived(_ identifier: String, uuid: CBUUID, value: String) {
    NSLog("dis info: \(uuid.uuidString) value: \(value)")
  }
}

// MARK: - PolarBleApiSdkModeFeatureObserver
extension PolarBleSdkModule : PolarBleApiDeviceFeaturesObserver {
  func hrFeatureReady(_ identifier: String) {
    NSLog("HR ready")
  }
  
  func ftpFeatureReady(_ identifier: String) {
    NSLog("FTP ready")
  }
  
  func streamingFeaturesReady(_ identifier: String, streamingFeatures: Set<DeviceStreamingFeature>) {
    for feature in streamingFeatures {
      NSLog("Feature \(feature) is ready.")
    }
  }
}

// MARK: - PolarBleApiSdkModeFeatureObserver
extension PolarBleSdkModule : PolarBleApiSdkModeFeatureObserver {
  func sdkModeFeatureAvailable(_ identifier: String) {
    NSLog("SDK mode feature available. Device \(identifier)")
  }
}

// MARK: - PolarBleApiDeviceHrObserver
extension PolarBleSdkModule : PolarBleApiDeviceHrObserver {
  func hrValueReceived(_ identifier: String, data: PolarHrData) {
    NSLog("(\(identifier)) HR value: \(data.hr) rrsMs: \(data.rrsMs) rrs: \(data.rrs) contact: \(data.contact) contact supported: \(data.contactSupported)")
  }
}

// MARK: - PolarBleApiLogger
extension PolarBleSdkModule : PolarBleApiLogger {
  func message(_ str: String) {
    NSLog("Polar SDK log:  \(str)")
  }
}
