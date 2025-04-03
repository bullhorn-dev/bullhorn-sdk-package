
import Foundation
import UIKit
import BullhornSdk

enum Appearance: String {
    case system
    case light
    case dark
}

struct ThemesManager {
    
    static let userInterfaceStyleDarkModeOn = "userInterfaceStyleDarkModeOn"
    static let themeStateKey = "ThemeStateEnum"
    
    static var shared = ThemesManager()

    private var observers = [ObjectIdentifier : WeakThemesObserver]()
    
    private init() {}
    
    private(set) var currentStyle: UIUserInterfaceStyle = UserDefaults.standard.bool(forKey: ThemesManager.userInterfaceStyleDarkModeOn) ? .dark : .light {
        didSet {
            if currentStyle != oldValue {
                styleDidChange()
            }
        }
    }

    // MARK: - Public
    
    mutating func addObserver(_ observer: ThemesObserver) {
        let id = ObjectIdentifier(observer)
        observers[id] = WeakThemesObserver(observer: observer)
    }
    
    mutating func removeObserver(_ observer: ThemesObserver) {
        let id = ObjectIdentifier(observer)
        observers.removeValue(forKey: id)
    }
    
    mutating func updateUserInterfaceStyle(_ isDarkMode: Bool) {
        currentStyle = isDarkMode ? .dark : .light
    }

    func currentTheme() -> Appearance {
        
        let rawValue = UserDefaults.standard.string(forKey: ThemesManager.themeStateKey) ?? "system"
        let currentTheme = Appearance(rawValue: rawValue)
        
        return currentTheme!
    }
    
    func currentInterfaceStyle() -> UIUserInterfaceStyle {
        switch currentTheme() {
        case .system: return .unspecified
        case .light: return .light
        case .dark: return .dark
        }
    }
    
    mutating func updateTheme(theme: Appearance) {
        
        var isDarkMode = false
        
        switch theme {
        case .system:
            if UIScreen.main.traitCollection.userInterfaceStyle == .dark {
                isDarkMode = true
            } else {
                isDarkMode = false
            }
            
        case .light:
            isDarkMode = false
            
        case .dark:
            isDarkMode = true
        }
        
        updateUserInterfaceStyle(isDarkMode)

        UserDefaults.standard.set(theme.rawValue, forKey: ThemesManager.themeStateKey)
        
        let style: UIUserInterfaceStyle = isDarkMode ? .dark : .light
        BullhornSdk.shared.updateUserInterfaceStyle(style)
     }
    
    // MARK: - Private

    mutating private func styleDidChange() {
        for (id, weakObserver) in observers {

            guard let observer = weakObserver.observer else {
                observers.removeValue(forKey: id)
                continue
            }
            
            observer.themesManager(self, didChangeStyle: currentStyle)
        }
    }
}
