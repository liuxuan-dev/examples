import SwiftUI
/*
 自定义通知操作
 在这个示例中，我们通过创建自定义通知来实现，用户再不打开应用的情况下，直接在通知达到时作出选择。
 */
struct ContentView: View {
    
    init() {
        setupNotificationDelegate()
        registerNotificationTypes()
    }
    
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
    
    // MARK: 设置通知委托
    let confirmMettingInvitation = ConfirmMettingInvitation()
    func setupNotificationDelegate() {
        UNUserNotificationCenter.current().delegate = confirmMettingInvitation
        print("已设置通知委托")
    }
    
    // MARK: 注册通知类型
    func registerNotificationTypes() {
        
        // 创建“接受”和“拒绝”两个通知操作项
        let acceptAction = UNNotificationAction(identifier: "ACCEPT_ACTION", title: "接受") // [1]
        let declineAction = UNNotificationAction(identifier: "DECLINE_ACTION", title: "拒绝")
        
        // 创建带有自定义操作的通知种类
        let meetingInviteCategory = UNNotificationCategory(
            identifier: "METTING_INVITATION_CATEGORY", // [2]
            actions: [acceptAction, declineAction],
            intentIdentifiers: [])
        
        // 注册自定通知类型
        UNUserNotificationCenter.current().setNotificationCategories([meetingInviteCategory]) // [3]
        print("已经注册自定通知类型")
    }
    
    // MARK: 请求授权
    func requestAuthorization() {
        // 向用户请求：通知、声音、徽章（即：App 图标上的“小红点”）授权。
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { grant, error in
            if let error = error {
                print("授权异常", error)
                return
            }
            print("已申请通知授权，授权结果：\(grant)")
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
            content.title = "员工周会"
            content.body = "每周一下午2点"
            content.sound = .default
            content.badge = 1
            content.userInfo = ["METTING_ID": "METTING_01", "USER_ID": "USER_01"]
            content.categoryIdentifier = "METTING_INVITATION_CATEGORY"
            
            // 2. 创建触发方式
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            // 3. 安排通知请求
            let request = UNNotificationRequest(identifier: "METTING_INVITATION_REQUEST", content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request)
            print("已经安排通知请求")
        }
    }
}

class ConfirmMettingInvitation: NSObject, UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        // 消除徽章
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        // 匹配处理对应的通知类型
        if response.notification.request.content.categoryIdentifier == "METTING_INVITATION_CATEGORY" {
            
            // 从 userInfo 中拿到额外的附加信息
            let userInfo = response.notification.request.content.userInfo
            let mettingID = userInfo["METTING_ID"] as! String
            let userID = userInfo["USER_ID"] as! String
            
            // 根据用户的选择执行不同的逻辑（用户在收到通知时，必须长按通知才能看到“通知选项”）
            switch response.actionIdentifier { // 对应创建 UNNotificationAction 时设置的 identifer 。
            case "ACCEPT_ACTION":
                acceptMettingInvitation(mettingID: mettingID, userID: userID)
            case "DECLINE_ACTION":
                declineMettingInvitation(mettingID: mettingID, userID: userID)
            default:
                // 用户点击“通知”直达应用前台，未作出选择。
                break
            }
        }
        
        completionHandler()
        print("已经处理用户的通知操作")
    }
    
    
    func acceptMettingInvitation(mettingID: String, userID: String) {
        print("用户\(userID)确定参加\(mettingID)会议")
    }
    
    func declineMettingInvitation(mettingID: String, userID: String) {
        print("用户\(userID)拒绝参加\(mettingID)会议")
    }
}

/*
 [1] 定义的操作对象都必须具备唯一的标识符，即便这些操作不属于同一个种类，因为在用户操作时，标识符是用来区分不同操作的唯一方法。
 [2] 系统使用类别标识符来查找系统已注册的类别，所以也必须保证它的唯一性。
 [3] 更好的做法是在应用启动时注册，因为它只需要注册一次，并且在注册时会替换掉之前已注册的种类。
 */
