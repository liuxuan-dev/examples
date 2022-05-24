//
//  ReminderDetailViewDataSource.swift
//  Today
//
//  Created by Liu Xuan on 2022/1/17.
//

import UIKit

/// “提醒”详情视图的查看数据源
class ReminderDetailViewDataSource: NSObject {

    enum ReminderRow: Int, CaseIterable { // [1]
        case title
        case date
        case time
        case notes
        
        // [3]
        static let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            formatter.timeStyle = .none
            return formatter
        }()
        
        static let timeFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            return formatter
        }()
        
        // 提供“提醒”的文本显示
        func displayText(for reminder: Reminder?) -> String? {
            switch self {
            case .title:
                return reminder?.title
            case .date:
                guard let date = reminder?.dueDate else {
                    return nil
                }
                // 保持与提醒列表中日期格式化风格一致
                if Locale.current.calendar.isDateInToday(date) {
                    return NSLocalizedString("Today", comment: "Today for date description")
                }
                return Self.dateFormatter.string(from: date)
            case .time:
                guard let date = reminder?.dueDate else {
                    return nil
                }
                return Self.timeFormatter.string(from: date)
            case .notes:
                return reminder?.notes
            }
        }
        
        // 返回这一行的图标
        var cellImage: UIImage? {
            switch self {
            case .title:
                return nil
            case .date:
                return .init(systemName: "calendar.circle")
            case .time:
                return .init(systemName: "clock")
            case .notes:
                return .init(systemName: "square.and.pencil")
            }
        }
    }
    
    private var reminder: Reminder
    
    init(reminder: Reminder) {
        self.reminder = reminder
        super.init()
    }
    
}

extension ReminderDetailViewDataSource: UITableViewDataSource {
    
    // [2]
    static let reminderDetailCellIndentifer = "RreminderDetailCell"
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        ReminderRow.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.reminderDetailCellIndentifer, for: indexPath)
        let row = ReminderRow(rawValue: indexPath.row)

        var configuration = cell.defaultContentConfiguration()
        configuration.text = row?.displayText(for: reminder)
        configuration.image = row?.cellImage
        cell.contentConfiguration = configuration
        
        return cell
    }
}


/*
 [1] Int：隐式的为其提供 Int 类型的原始值，默认第一个 case 从 0 开始。CaseIterable 协议有一个 allCases 属性，可以使用该属性来遍历枚举的每个 case。
 [2] 单独使用一个变量来存储标识符的好处是避免了因为输入错误而导致程序奔溃。
 [3] 无法将存储的实例属性添加到枚举或扩展中，但可以添加存储的静态属性。
 */
