import Foundation

extension TimeInterval {

    func stringFormatted() -> String {

        let interval = Int(self)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        let hours = (interval / 3600)

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    func toMs() -> Double {
        return self //* 1000
    }
    
    func fromMs() -> Double {
        return self /// 1000
    }
}
