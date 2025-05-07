
import UserNotifications
import UIKit
import Foundation

protocol BHLocalNotificationsManagerDelegate: AnyObject {

    func localNotificationsManager(_ manager: BHLocalNotificationsManager, presentationOptionsForNotification info: NotificationInfoCommonObject) -> UNNotificationPresentationOptions
    func localNotificationsManager(_ manager: BHLocalNotificationsManager, performActionForNotification info: NotificationInfoCommonObject, actionIdentifier: String, completionHandler: @escaping (Bool) -> Void)
}


class BHLocalNotificationsManager: NSObject {

    weak var delegate: BHLocalNotificationsManagerDelegate?

    fileprivate var typeClassMap = [NotificationInfo.PayloadType: NotificationInfoObject.Type]()

    // MARK: - Initialization

    override init() {
        super.init()

        UNUserNotificationCenter.current().delegate = self
        registerNotificationInfoClasses()
    }

    fileprivate func registerNotificationInfoClasses() {

        typeClassMap[.newEpisodeInvitation] = NewEpisodeNotificationInfo.self
        typeClassMap[.newEpisodesReminder] = NewEpisodesReminderNotificationInfo.self
        typeClassMap[.liveEpisodeStarted] = LiveEpisodeStartedNotificationInfo.self
        typeClassMap[.liveEpisodeScheduled] = LiveEpisodeScheduledNotificationInfo.self
        typeClassMap[.liveEpisodeMeetingRoom] = LiveEpisodeMeetingRoomNotificationInfo.self
        typeClassMap[.massNotification] = MassNotificationInfo.self
    }

    // MARK: - Public

    func cleanAllNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        updateApplicationIconBadgeNumber()
    }
    
    func updateApplicationIconBadgeNumber() {
        UNUserNotificationCenter.current().getDeliveredNotifications() { notifications in
            DispatchQueue.main.async {
                UIApplication.shared.applicationIconBadgeNumber = notifications.count
            }
        }
    }
    
    // MARK: - Private

    fileprivate func composeNotificationInfoObject(from payload: NotificationInfo.Payload) -> NotificationInfoCommonObject? {

        guard let infoCommon = NotificationInfoCommonObject.init(from: payload) else {
            BHLog.w("\(#function) - Failed to init NotificationInfoCommonObject from payload: \(payload)")
            return nil
        }

        guard let notificationInfoClass = typeClassMap[infoCommon.payloadType] else { return nil }

        return createNotificationInfoObject(objectType: notificationInfoClass, from: payload)
    }

    fileprivate func createNotificationInfoObject(objectType: NotificationInfoObject.Type, from payload: NotificationInfo.Payload) -> NotificationInfoCommonObject? {
        return objectType.init(from: payload) as? NotificationInfoCommonObject
    }

    fileprivate func cleanNotifications(_ categories: [NotificationInfo.PayloadType]) {

        let categoryRawValues = categories.compactMap { $0.rawValue }

        UNUserNotificationCenter.current().getDeliveredNotifications { deliveredNotifications in

            let notificationsWithIdentifiers = deliveredNotifications.filter { categoryRawValues.contains($0.request.content.categoryIdentifier) }
            let identifiers = notificationsWithIdentifiers.compactMap { $0.request.identifier }

            if identifiers.isEmpty {
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension BHLocalNotificationsManager: UNUserNotificationCenterDelegate {

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

        let userInfo = notification.request.content.userInfo

        BHLog.p("\(#function) - userInfo = \(userInfo)")

        guard let info = composeNotificationInfoObject(from: userInfo) else {
            BHLog.w("\(#function) - Failed to recognize notification")
            return
        }
        
        let presentationOptions = delegate?.localNotificationsManager(self, presentationOptionsForNotification: info)
        
        completionHandler(presentationOptions ?? [.banner, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {

        let userInfo = response.notification.request.content.userInfo

        BHLog.p("\(#function) - userInfo = \(userInfo)")

        guard let info = composeNotificationInfoObject(from: userInfo) else {
            BHLog.w("\(#function) - Failed to recognize notification from background")
            return
        }
        
        delegate?.localNotificationsManager(self, performActionForNotification: info, actionIdentifier: response.actionIdentifier) { performed in

            if !performed {}

            completionHandler()
        }
    }
}
