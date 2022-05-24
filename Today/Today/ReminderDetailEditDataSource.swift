//
//  ReminderDetailEditDataSource.swift
//  Today
//
//  Created by Liu Xuan on 2022/1/18.
//

import UIKit

/// “提醒”详情编辑的数据源
class ReminderDetailEditDataSource: NSObject {
    
    enum ReminderSection: Int, CaseIterable {
        case title
        case dueDate
        case notes
        
        // 显示文本
        var displayText: String {
            switch self {
            case .title:
                return "Title"
            case .dueDate:
                return "Date"
            case .notes:
                return "Notes"
            }
        }
        
        // 每个部分对应的行数
        var numRows: Int {
            switch self {
            case .title, .notes:
                return 1
            case .dueDate:
                return 2
            }
        }
        
        // 根据行索引获取单元格对应的标识符
        func cellIdentifier(for row: Int) -> String {
            switch self {
            case .title:
                return "EditTitleCell"
            case .dueDate:
                // 日期部分下包含两个不同类型单元格，其中 EditDateLabelCell 用来展示日期字符串，EditDateCell 用来展示日期选择器组件
                return row == 0 ? "EditDateLabelCell" : "EditDateCell"
            case .notes:
                return "EditNotesCell"
            }
        }
    }
    
    typealias ReminderChangeAction = (Reminder) -> Void
    
    static var dateLabelIdentifier: String {
        ReminderSection.dueDate.cellIdentifier(for: 0)
    }
    
    private var reminder: Reminder
    private var reminderChangeAction: ReminderChangeAction?
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter
    }()
    
    init(reminder: Reminder, changeAction: @escaping ReminderChangeAction) {
        self.reminder = reminder
        self.reminderChangeAction = changeAction
    }
    
    private func dequeueAndConfigureCell(for indexPath: IndexPath, from tableView: UITableView) -> UITableViewCell {
        // 通过 Section 索引获取到对应的 ReminderSection 对象
        guard let section = ReminderSection(rawValue: indexPath.section) else {
            fatalError("Section index out of range")
        }
        
        // 通过 ReminderSection 对象获取单元格 identifier 标识
        let identifier = section.cellIdentifier(for: indexPath.row)
        
        // 通过 identifier 出列单元格
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        
        // 根据 Case 配置不同单元格
        switch section {
        case .title:
            if let titleCell = cell as? EditTitleCell {
                titleCell.configure(title: reminder.title) { title in
                    // 当 title 被用户改变时更新数据对象
                    self.reminder.title = title
                    self.reminderChangeAction?(self.reminder)
                }
            }
        case .dueDate:
            if indexPath.row == 0 {
                cell.textLabel?.text = dateFormatter.string(from: reminder.dueDate)
            } else {
                if let dueDateCell = cell as? EditDateCell {
                    dueDateCell.configure(date: reminder.dueDate) { date in
                        self.reminder.dueDate = date
                        self.reminderChangeAction?(self.reminder)
                        
                        // 重新加载编辑视图的 dataLabel 单元格，以同步显示日期的变更。
                        let indexPaht = IndexPath(row: 0, section: section.rawValue)
                        tableView.reloadRows(at: [indexPaht], with: .automatic)
                    }
                }
            }
        case .notes:
            if let notesCell = cell as? EditNotesCell {
                notesCell.configure(notes: reminder.notes) { text in
                    self.reminder.notes = text
                    self.reminderChangeAction?(self.reminder)
                }
            }
        }
        
        return cell
    }
}

extension ReminderDetailEditDataSource: UITableViewDataSource {
    
    // 表格分为几个部分
    func numberOfSections(in tableView: UITableView) -> Int {
        ReminderSection.allCases.count
    }
    
    // 每个部分有几行
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ReminderSection(rawValue: section)?.numRows ?? 0
    }
    
    // 设置每一行的单元格
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return dequeueAndConfigureCell(for: indexPath, from: tableView)
    }
    
    // 设置每一“部分”的标题
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let section = ReminderSection(rawValue: section) else {
            fatalError("Section index out of range")
        }
        return section.displayText
    }
    
    // 设定单元格可编辑性 [1]
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // false 标识此单元格不支持编辑
        return false
    }
}

/*
 [1] 如果单元格是可编辑的，则表视图可以显示控件来“删除”单元格或“重新排序”，返回 false 以便这些控件永远不会显示在此视图中。
 */
