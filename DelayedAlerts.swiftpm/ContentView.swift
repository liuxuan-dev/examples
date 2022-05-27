import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Button("请求授权") {
                requestAuthorization()
            }
            
            Button("触发提醒") {
                triggerNotification()
            }
        }
    }
    
    // MARK: 请求授权
    func requestAuthorization() {
        let center = UNUserNotificationCenter.current()
        // 向用户请求：通知、声音、徽章（即：App 图标上的“小红点”）授权。
        center.requestAuthorization(options: [.alert, .sound, .badge]) { grant, error in
            if let error = error {
                print("授权异常", error)
                return
            }
            print("用户\(grant ? "同意" : "拒绝")授权")
        }
    }
    
    // MARK: 触发通知
    func triggerNotification() {
        // 触发通知前仍然应该先判断是否具备通知权限，因为有可能用户之后在系统设置中主动将通知关闭。
        UNUserNotificationCenter.current().getNotificationSettings { settings in
           
            guard settings.authorizationStatus == .authorized else { return }
            guard settings.alertSetting == .enabled else { return }
            
            // 1. 创建通知内容
            let content = UNMutableNotificationContent()
            content.title = "通知提醒"
            content.body = "5秒时间已过"
            content.sound = .default // 通知声音
            content.badge = 1 // 徽章数字（“小红点”中的数字）
            
            // 2. 创建触发方式
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false) // repeats 设置为 true 可以开启通知循环，但前提是间隔时间不少于 60 秒。
            
            // 3. 安排通知请求
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger) // identifier 是通知的标识ID，可以通过它来取消一个通知。
            UNUserNotificationCenter.current().add(request)
        }
    }
}
