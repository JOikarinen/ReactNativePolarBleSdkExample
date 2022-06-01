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
