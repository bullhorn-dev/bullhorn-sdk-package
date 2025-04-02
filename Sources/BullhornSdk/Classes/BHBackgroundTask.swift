
import Foundation
import UIKit.UIApplication
import AVFoundation

class BHBackgroundTask: NSObject {

    var condition: ((TimeInterval) -> Bool)?
    var actionOnCondition: (() -> Void)?
    
    var conditionToEndTask: ((TimeInterval) -> Bool)?
    var actionOnConditionToEndTask: (() -> Void)?

    let workingQueue: DispatchQueue
    let name: String?

    private let minimumIntervalBeforeTimeout: (TimeInterval) -> TimeInterval
    private let conditionToBeginTask: () -> Bool

    private var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid
    private var backgoundWorkItem: DispatchWorkItem?

    init(name: String? = nil,
                minimumIntervalBeforeTimeout: @escaping (TimeInterval) -> TimeInterval,
                conditionToBeginTask: @escaping () -> Bool) {

        self.name = name
        self.minimumIntervalBeforeTimeout = minimumIntervalBeforeTimeout
        self.conditionToBeginTask = conditionToBeginTask

        let prefix = "BackgroundTask"
        let queueName = name.map { prefix + ".\($0)" } ?? prefix
        workingQueue = DispatchQueue.init(label: queueName, qos: .userInitiated, target: .global())

        super.init()

        scheduleTask()
    }

    func scheduleTask() {

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(onWillResignActive(_:)), name: UIApplication.willResignActiveNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(onDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    func beginBackgroundTask() {
        BHLog.p("Begin background task")

        let taskId = UIApplication.shared.beginBackgroundTask(withName: name, expirationHandler: {
            self.endBackgroundTask()
            self.speakToWakeUp()
            
            guard self.conditionToBeginTask() else {
                BHLog.p("Not starting background task")
                return
            }

            self.beginBackgroundTask()
        })

        guard taskId != .invalid else {
            BHLog.p("Execution of background task is not possible")
            return
        }

        let workItem = DispatchWorkItem.init(qos: .userInitiated) {
            guard self.backgroundTaskId != .invalid else { return }

            let remainingTime = DispatchQueue.main.sync { UIApplication.shared.backgroundTimeRemaining }
            BHLog.p("UIApplication.backgroundTimeRemaining = \(remainingTime)")

            if let validCondition = self.condition, validCondition(remainingTime) {
                BHLog.p("Condition is true")
                self.actionOnCondition?()
            }

            if let validConditionToEndTask = self.conditionToEndTask, validConditionToEndTask(remainingTime) {
                BHLog.p("Condition to end task is true")
                self.actionOnConditionToEndTask?()
                self.endBackgroundTask()
            }
            else {
                let interval = self.minimumIntervalBeforeTimeout(remainingTime)
                self.backgoundWorkItem.map { self.workingQueue.asyncAfter(deadline: .now() + interval, execute: $0) }
            }
        }

        backgroundTaskId = taskId
        backgoundWorkItem = workItem
        workingQueue.async(execute: workItem)
    }

    func endBackgroundTask() {
        guard backgroundTaskId != .invalid else { return }

        BHLog.p("End background task")

        UIApplication.shared.endBackgroundTask(backgroundTaskId)
        backgroundTaskId = .invalid
        backgoundWorkItem = nil
    }

    @objc
    private func onWillResignActive(_ notification: Notification) {
        workingQueue.async {
            guard self.conditionToBeginTask() else {
                BHLog.p("Not starting background task")
                return
            }

            self.beginBackgroundTask()
        }
    }

    @objc
    private func onDidBecomeActive(_ notification: Notification) {
        workingQueue.async {
            self.endBackgroundTask()
        }
    }
    
    private func speakToWakeUp() {
        
        let utterance = AVSpeechUtterance(string: "up")
        utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
        utterance.volume = 0
        utterance.rate = 0.1

        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
    }
}
