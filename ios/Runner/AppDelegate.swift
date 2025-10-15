import Flutter
import UIKit
import AVFoundation
import BackgroundTasks

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var audioSessionChannel: FlutterMethodChannel?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Set up audio session method channel
    setupAudioSessionChannel()
    
    // Register background task for keyword detection
    registerBackgroundTasks()
    
    // Configure initial audio session
    configureInitialAudioSession()
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func setupAudioSessionChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }
    
    audioSessionChannel = FlutterMethodChannel(
      name: "audio_session",
      binaryMessenger: controller.binaryMessenger
    )
    
    audioSessionChannel?.setMethodCallHandler { [weak self] (call, result) in
      self?.handleAudioSessionMethod(call: call, result: result)
    }
  }
  
  private func handleAudioSessionMethod(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "configureRecordingSession":
      configureRecordingSession(arguments: call.arguments, result: result)
    case "configurePlaybackSession":
      configurePlaybackSession(arguments: call.arguments, result: result)
    case "configureBackgroundSession":
      configureBackgroundSession(arguments: call.arguments, result: result)
    case "activateSession":
      activateAudioSession(result: result)
    case "deactivateSession":
      deactivateAudioSession(result: result)
    case "handleInterruption":
      handleInterruption(arguments: call.arguments, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func configureRecordingSession(arguments: Any?, result: @escaping FlutterResult) {
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playAndRecord, mode: .voiceChat, options: [
        .defaultToSpeaker,
        .allowBluetooth,
        .allowBluetoothA2DP
      ])
      result(true)
    } catch {
      result(FlutterError(code: "AUDIO_SESSION_ERROR", message: error.localizedDescription, details: nil))
    }
  }
  
  private func configurePlaybackSession(arguments: Any?, result: @escaping FlutterResult) {
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playback, mode: .default, options: [
        .allowBluetooth,
        .allowBluetoothA2DP
      ])
      result(true)
    } catch {
      result(FlutterError(code: "AUDIO_SESSION_ERROR", message: error.localizedDescription, details: nil))
    }
  }
  
  private func configureBackgroundSession(arguments: Any?, result: @escaping FlutterResult) {
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.record, mode: .voiceChat, options: [.allowBluetooth])
      result(true)
    } catch {
      result(FlutterError(code: "AUDIO_SESSION_ERROR", message: error.localizedDescription, details: nil))
    }
  }
  
  private func activateAudioSession(result: @escaping FlutterResult) {
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setActive(true)
      result(true)
    } catch {
      result(FlutterError(code: "AUDIO_SESSION_ERROR", message: error.localizedDescription, details: nil))
    }
  }
  
  private func deactivateAudioSession(result: @escaping FlutterResult) {
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setActive(false, options: .notifyOthersOnDeactivation)
      result(true)
    } catch {
      result(FlutterError(code: "AUDIO_SESSION_ERROR", message: error.localizedDescription, details: nil))
    }
  }
  
  private func handleInterruption(arguments: Any?, result: @escaping FlutterResult) {
    guard let args = arguments as? [String: Any],
          let began = args["began"] as? Bool else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
      return
    }
    
    if began {
      // Interruption began - deactivate session
      try? AVAudioSession.sharedInstance().setActive(false)
    } else {
      // Interruption ended - reactivate session
      try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    result(true)
  }
  
  private func configureInitialAudioSession() {
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
      
      // Set up interruption notifications
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(handleAudioSessionInterruption),
        name: AVAudioSession.interruptionNotification,
        object: session
      )
      
      // Set up route change notifications
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(handleAudioSessionRouteChange),
        name: AVAudioSession.routeChangeNotification,
        object: session
      )
    } catch {
      print("Failed to configure initial audio session: \(error)")
    }
  }
  
  @objc private func handleAudioSessionInterruption(notification: Notification) {
    guard let userInfo = notification.userInfo,
          let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
          let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
      return
    }
    
    switch type {
    case .began:
      // Interruption began
      audioSessionChannel?.invokeMethod("onInterruptionBegan", arguments: nil)
    case .ended:
      // Interruption ended
      if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
        let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
        if options.contains(.shouldResume) {
          audioSessionChannel?.invokeMethod("onInterruptionEnded", arguments: ["shouldResume": true])
        }
      }
    @unknown default:
      break
    }
  }
  
  @objc private func handleAudioSessionRouteChange(notification: Notification) {
    guard let userInfo = notification.userInfo,
          let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
          let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
      return
    }
    
    switch reason {
    case .newDeviceAvailable, .oldDeviceUnavailable:
      audioSessionChannel?.invokeMethod("onRouteChanged", arguments: ["reason": reason.rawValue])
    default:
      break
    }
  }
  
  private func registerBackgroundTasks() {
    BGTaskScheduler.shared.register(
      forTaskWithIdentifier: "com.voicekeywordrecorder.keyword-detection",
      using: nil
    ) { task in
      self.handleKeywordDetectionBackgroundTask(task: task as! BGAppRefreshTask)
    }
  }
  
  private func handleKeywordDetectionBackgroundTask(task: BGAppRefreshTask) {
    // Schedule next background task
    scheduleKeywordDetectionBackgroundTask()
    
    // Set expiration handler
    task.expirationHandler = {
      task.setTaskCompleted(success: false)
    }
    
    // Notify Flutter about background task
    audioSessionChannel?.invokeMethod("onBackgroundTaskStarted", arguments: nil)
    
    // Complete the task after a short period
    DispatchQueue.main.asyncAfter(deadline: .now() + 25) {
      task.setTaskCompleted(success: true)
    }
  }
  
  private func scheduleKeywordDetectionBackgroundTask() {
    let request = BGAppRefreshTaskRequest(identifier: "com.voicekeywordrecorder.keyword-detection")
    request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
    
    try? BGTaskScheduler.shared.submit(request)
  }
  
  override func applicationDidEnterBackground(_ application: UIApplication) {
    super.applicationDidEnterBackground(application)
    scheduleKeywordDetectionBackgroundTask()
  }
}
