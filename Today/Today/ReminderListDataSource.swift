//
//  ReminderListDataSource.swift
//  Today
//
//  Created by Liu Xuan on 2022/1/17.
//

import UIKit
import EventKit

/// “提醒”列表数据源
class ReminderListDataSource: NSObject { // [0]
    
    // 完成提醒动作
    typealias ReminderCompletedAction = (Int) -> Void
    // 删除提醒动作
    typealias ReminderDeletedAction = (Bool) -> Void
    // 提醒数据变更动作
    typealias RemindersChangedAction = () -> Void
    
    // MARK:  数据过滤
    enum Filter: Int {
        case today
        case future
        case all
        
        // 判断某个日期是否在包含的范围内
        func shouldInclude(date: Date) -> Bool {
            let isInToday = Locale.current.calendar.isDateInToday(date) // [5]
            switch self {
            case .today:
                return isInToday
            case .future:
                return date > Date() && !isInToday
            case .all:
                return true
            }
        }
    }
    
    // 当前过滤模式
    var filter: Filter = .today
    
    // 完成百分比
    var percentComplete: Double {
        guard filteredReminders.count > 0 else {
            return 1 // TODO: 为何要设置为 1？
        }
        let numComplete: Double = filteredReminders.reduce(0) { $0 + ($1.isComplete ? 1 : 0) }
        // 完成比例
        return numComplete / Double(filteredReminders.count)
    }
    
    private var filteredReminders: [Reminder] {
        reminders
            .filter { filter.shouldInclude(date: $0.dueDate) } // 过滤日期
            .sorted { $0.dueDate < $1.dueDate } // 日期较早的排前面
    }
    
    // 利用其申请授权访问用户的系统自带“提醒”App的记录 [6]
    private let eventStore = EKEventStore()
    
    private var reminders: [Reminder] = []
    
    private var reminderCompletedAction: ReminderCompletedAction?
    private var reminderDeletedAction: ReminderDeletedAction?
    private var remindersChangedAction: RemindersChangedAction?
    
    /// 初始化构造器
    /// - Parameters:
    ///   - reminderCompletedAction: 当“完成提醒” 按钮被用户点击时被调用
    ///   - reminderDeletedAction: 当提醒被用户删除时调用
    init(reminderCompletedAction: @escaping ReminderCompletedAction, reminderDeletedAction: @escaping ReminderDeletedAction, remindersChangedAction: @escaping RemindersChangedAction) {
        
        self.reminderCompletedAction = reminderCompletedAction
        self.reminderDeletedAction = reminderDeletedAction
        self.remindersChangedAction = remindersChangedAction
        super.init()
        // 请求用户授权访问提醒数据，授权成功则加载提醒数据。
        self.requestAccess { authorized in
            guard authorized else {
                return
            }
            self.readAllReminders()
            
            // 注册提醒数据变更通知
            NotificationCenter.default.addObserver(self, selector: #selector(self.storeChanged(_:)), name: .EKEventStoreChanged, object: self.eventStore) // 最后一个参数 object 表示“通知发件人”，这里的发件人是 eventStore 对象
        }
    }
    
    deinit {
        // 在对象卸载时删除观察者（iOS 9.0 或 macOS 10.11 版本以上不需要手动删除）
        NotificationCenter.default.removeObserver(self, name: .EKEventStoreChanged, object: eventStore)
    }
    
    // 接受提醒数据变更通知
    @objc
    func storeChanged(_ notification: NSNotification) {
        // 接收到数据变更通知后重新加载数据
        requestAccess { authorized in
            if authorized {
                self.readAllReminders()
            }
        }
    }
    
    // MARK: - 数据操作方法
    // 获取数据
    func reminder(at row: Int) -> Reminder {
        // tip: 当您的基础数据不再是简单的数组时，这些方法将作为稳定接口，稍后您将维护。
        // 重过滤后的提醒事项中获取数据
        return filteredReminders[row]
    }
    
    // 更新数据
    func update(_ reminder: Reminder, at row: Int, completion: (Bool) -> Void) {
        saveReimider(reminder) { id in
            let success = id != nil
            if success {
                let index = self.index(for: row)
                reminders[index] = reminder
            }
            completion(success)
        }
    }
    
    // 新增数据
    func add(_ reminder: Reminder, completion: (Bool, Int?) -> Void) {
        
        saveReimider(reminder) { id in
            guard let id = id else {
                completion(false, nil)
                return
            }
            
            let reminder = Reminder(id: id, title: reminder.title, dueDate: reminder.dueDate, notes: reminder.notes, isComplete: reminder.isComplete)
            
            // 将数据新增在首行
            reminders.insert(reminder, at: 0)
            // 如果当前过滤条件为“今天”，但新增的是“明天”的提醒，则索引返回为 nil
            let index = filteredReminders.firstIndex { $0.id == reminder.id }
            completion(true, index)
        }
        
    }
    
    // 删除数据
    func delete(at row: Int, complection: (Bool) -> Void) {
        let reminder = reminder(at: row)
        removeReminder(reminder) { success in
            if success {
                let index = self.index(for: row)
                reminders.remove(at: index)
            }
            
            complection(success)
        }
    }
    
    // 根据 filteredIndex 索引映射出原始数据的索引
    func index(for filteredIndex: Int) -> Int {
        let filteredReminder = reminder(at: filteredIndex)
        guard let index = reminders.firstIndex(where: { $0.id == filteredReminder.id }) else {
            fatalError("Couldn't retrieve index in source array")
        }
        return index
    }
}

// [1]
extension ReminderListDataSource: UITableViewDataSource {
    
    // 使用一个静态常量来存储单元格标识符 [2]
    static let reminderListCellIndentifier = "ReminderListCell"
    
    // 提供表中的行数
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredReminders.count
    }
    
    // 为每行提供单元格
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // [3]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Self.reminderListCellIndentifier, for: indexPath) as? ReminderListCell else {
            fatalError("Unable to dequeue ReminderListCell")
        }
        
        let currentReminder = filteredReminders[indexPath.row]
        // 基于当前过滤模式来使用相应的日期格式化方案
        let dateText = currentReminder.dueTimeText(for: filter)
        cell.configure(title: currentReminder.title, dateText: dateText, isDone: currentReminder.isComplete) {
            // 切换“完成”状态，并重新加载对应的表格行
            var modifiedReminder = currentReminder
            modifiedReminder.isComplete.toggle()
            self.update(modifiedReminder, at: indexPath.row) { success in
                if success {
                    self.reminderCompletedAction?(indexPath.row)
                }
            }
        }
        
        return cell
    }
    
    // 滑动删除单元格
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {

        guard editingStyle == .delete else {
            return
        }
        
        // 删除对应提醒
        self.delete(at: indexPath.row) { success in
            if success {
                // 将多个操作合并成一起执行，而不是每删一条执行一次删除动画。
                tableView.performBatchUpdates {
                    // 删除索引组标识的行，并带有删除动画。
                    tableView.deleteRows(at: [indexPath], with: .automatic)
                } completion: { _ in
                    // deleteRows(at: with:) 不会刷新表数据，所以执行它是有必要的。
                    tableView.reloadData()
                }
            }
            reminderDeletedAction?(success)
        }
    }
}

extension Reminder {
    
    // MARK: - dueDate 格式化支持
    static let timeFormatter: DateFormatter = {
       let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        return timeFormatter
    }()
    
    static let futureFormatter: DateFormatter = {
       let futureFormatter = DateFormatter()
        futureFormatter.dateStyle = .medium
        futureFormatter.timeStyle = .short
        return futureFormatter
    }()
    
    static let todayFormatter: DateFormatter = {
        let format = NSLocalizedString("'Today at '%@", comment: "format string for dates occurring today")
        let todayFormatter = DateFormatter()
        // 自定义格式化今天的日期
        todayFormatter.dateFormat = String(format: format, "hh:mm a")
         return todayFormatter
    }()
    
    func dueTimeText(for filter: ReminderListDataSource.Filter) -> String {
        let isInToday = Locale.current.calendar.isDateInToday(self.dueDate)
        switch filter {
        case .today:
            return Self.timeFormatter.string(from: self.dueDate)
        case .future:
            return Self.futureFormatter.string(from: self.dueDate)
        case .all:
            if isInToday {
                return Self.todayFormatter.string(from: self.dueDate)
            } else {
                return Self.futureFormatter.string(from: self.dueDate)
            }
        }
    }
}

// MARK: 访问用户系统“提醒”App 记录
extension ReminderListDataSource {
    
    /// 是否已经获得用户授权
    var isAvailable: Bool {
        // 有三种状态，分别为： authorized 已授权；denied 已拒绝；notDetermined 未确认
        return EKEventStore.authorizationStatus(for: .reminder) == .authorized
    }
    
    
    /// 请求用户授权
    /// - Parameter completed: 授权结果
    func requestAccess(completion: @escaping (Bool) -> Void) {
        let currentStatus = EKEventStore.authorizationStatus(for: .reminder)
        // 如果已经授权或拒绝授权则直接回调完成方法提供结果
        guard currentStatus == .notDetermined else {
            completion(currentStatus == .authorized)
            return
        }
        
        // 请求用户授权
        eventStore.requestAccess(to: .reminder) { (success, error) in
            completion(success)
        }
    }
    
    
    /// 读取所有提醒记录
    private func readAllReminders() {
        // 未授权则直接返回一个空列表
        guard isAvailable else {
            reminders = []
            return
        }
        
        // 查询条件为空
        let predication = eventStore.predicateForReminders(in: nil)
        
        // 查询所有“提醒”记录（包含截止日期的数据）
        eventStore.fetchReminders(matching: predication) { ekReminders in
            guard let ekReminders = ekReminders else {
                return
            }
            self.reminders = ekReminders.compactMap {
                guard let dueDate = $0.alarms?.first?.absoluteDate else {
                    return nil
                }
                
                let reminder: Reminder = .init(id: $0.calendarItemIdentifier, title: $0.title, dueDate: dueDate, notes: $0.notes, isComplete: $0.isCompleted)
                return reminder
            }
            
            // 数据加载后触发变更动作
            self.remindersChangedAction?()
        }
    }
    
    
    /// 查询指定标识的提醒记录
    /// - Parameters:
    ///   - id: 唯一标识
    ///   - completion: 查询完成后的回调
    private func readReminder(with id: String, completion: (EKReminder?) -> Void) {
        guard isAvailable else {
            completion(nil)
            return
        }
        
        guard let ekReminder = eventStore.calendarItem(withIdentifier: id) as? EKReminder else {
            completion(nil)
            return
        }
        
        completion(ekReminder)
    }
    
    /// 保存提醒
    /// 将提醒保存到 EventStore 中，根据 reminder.id 先查询对象是否已经存在，存在则更新相关记录，不存在则创建对象并设置相关信息。
    /// - Parameters:
    ///   - reminder: 要保存的提醒对象
    ///   - completion: 保存成功则参数为提醒ID（新增情况下不会使用 Reminder.ID 保存，而是使用 EKReminder 对象自动生成的ID。）
    private func saveReimider(_ reminder: Reminder, completion: (String?) -> Void) {
        guard isAvailable else {
            completion(nil)
            return
        }
        
        readReminder(with: reminder.id) { ekReminder in
            // 新增对象不存在则创建一个
            let ekReminder = ekReminder ?? EKReminder(eventStore: eventStore)
            ekReminder.title = reminder.title
            ekReminder.notes = reminder.notes
            ekReminder.isCompleted = reminder.isComplete
            // 提醒添加到用户指定的默认日历？
            ekReminder.calendar = eventStore.defaultCalendarForNewReminders()
            
            // 如果原提醒日期设置与当前提醒日期不一样则删除这个提醒
            ekReminder.alarms?.forEach { alarm in
                if let absoluteDate = alarm.absoluteDate {
                   let comparison = Locale.current.calendar.compare(absoluteDate, to: reminder.dueDate, toGranularity: .minute)
                    if comparison != .orderedSame {
                        ekReminder.removeAlarm(alarm)
                    }
                }
            }
            
            // 如果没有提醒，那么就根据 dueDate 创建一个提醒
            if !ekReminder.hasAlarms {
                ekReminder.addAlarm(.init(absoluteDate: reminder.dueDate))
            }
            
            // 保存提醒
            do {
                try eventStore.save(ekReminder, commit: true)
                completion(ekReminder.calendarItemIdentifier)
            } catch {
                print("保存提醒失败：\(error.localizedDescription)")
                completion(nil)
            }
            
        }
        
    }
    
    
    /// 删除提醒
    /// - Parameters:
    ///   - reminder: 删除对象
    ///   - completion: 回调函数返回 true 表示删除成功
    private func removeReminder(_ reminder: Reminder, completion: (Bool) -> Void) {
        guard isAvailable else {
            completion(false)
            return
        }
        
        readReminder(with: reminder.id) { ekReminder in
            guard let ekReminder = ekReminder else {
                completion(false)
                return
            }
            do {
                try eventStore.remove(ekReminder, commit: true)
                completion(true)
            } catch {
                print("删除提醒失败：\(error.localizedDescription)")
                completion(false)
            }
        }
    }
}

/*
 [0] 必须是 NSObject 的子类，才能实现 UITableViewDataSource 协议。
 [1] 表视图只管理数据显示，不管理数据本身。要管理数据，必须向表提供一个实现 UITableViewDataSource 协议的对象。
     UITableViewDataSource 需要两种数据源方法：一种是提供表中的行数，另一种是为每行提供单元格。
 [2] 它对应与在 Interface Builder 中 所创建的 ReminderListCell 的 “Identifier” 属性值。
 [3] 利用此方式获取单元格会优化性能，因为它返回可重用的单元格。
 [5] Locale.current.calendar 是基于用户当前区域设置的日历
 [6] 利用 EKEventStore 可以申请访问用户日历或提醒数据。（Tip：在 Info.plist 文件中 “Information Property List” 下添加 “Privacy - Reminders Usage Description” 属性，并添加向用户授权时的说明内容。）
  */
