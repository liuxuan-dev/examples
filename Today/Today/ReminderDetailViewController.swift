//
//  ReminderDetailViewController.swift
//  Today
//
//  Created by Liu Xuan on 2022/1/17.
//

import UIKit

/// “提醒”详情视图
/// 根据编辑状态来更改不同的数据源，从而实现查看和编辑两种不同的模式。
class ReminderDetailViewController: UITableViewController {
    
    typealias ReminderChangeAction = (Reminder) -> Void
    
    private var reminder: Reminder?
    // 存放编辑临时对象，以实现用户取消编辑则会复回原始数据对象。
    private var tempReminder: Reminder?
    private var dataSource: UITableViewDataSource?
    private var reminderEditAction: ReminderChangeAction?
    private var reminderAddAction: ReminderChangeAction?
    private var isNew = false

    //
    // 以下两种情况将会调用此方法对 ReminderDetailViewController 实例进行配置：
    // 情况一：用户点击提醒列表中的“单元格”（提供给 Segue 注入 Reminder [1]）
    // 情况二：用户点击提醒列表页面中的“新增”按钮。
    func configure(with reminder: Reminder, isNew: Bool = false, addAction: ReminderChangeAction? = nil, editAction: ReminderChangeAction? = nil) {
        self.reminder = reminder
        self.isNew = isNew
        self.reminderAddAction = addAction
        self.reminderEditAction = editAction
        
        if isViewLoaded {
            // MARK: 目前来看是没有意义的，因为在 viewDidLoad() 中有调用 setEditing(editing:, animated:)
            setEditing(isNew, animated: false)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 初始显示查看视图（因为是系统初始显示，而不是用户操作，所以关闭了动画。）
        setEditing(isNew, animated: false)
        
        // 在导航栏右上角添加一个系预定义的编辑按钮 // [3]
        navigationItem.setRightBarButton(editButtonItem, animated: false)
        
        // 为“提醒”编辑视图注册一个单元格，因为它只是一个普通的单元格，没有通过 IB 进行配置。
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: ReminderDetailEditDataSource.dateLabelIdentifier)
    }
    
    override func viewWillAppear(_ animated: Bool) { // [6]
        super.viewDidAppear(animated)
        if let navigationController = navigationController, !navigationController.isToolbarHidden {
            navigationController.setToolbarHidden(true, animated: false)
        }
    }
    
    private func transitionToViewMode(_ reminder: Reminder) {
        // 新增内容
        if isNew {
            // 如果没有编辑直接保存，则使用默认值。
            let reminder = tempReminder ?? reminder
            // 关闭模态
            dismiss(animated: true) {
                // 触发新增行为
                self.reminderAddAction?(reminder)
            }
            return
        }
        
        // 保存修改内容
        if let tempReminder = tempReminder {
            self.reminder = tempReminder
            self.tempReminder = nil
            self.reminderEditAction?(tempReminder)
            dataSource = ReminderDetailViewDataSource(reminder: tempReminder)
        } else {
            // 用户从列表进入，或在编辑模式下选择取消、或在未修改内容情况下点击保存
            dataSource = ReminderDetailViewDataSource(reminder: reminder)
        }
        
        // 处于视图模式下去除“取消按钮”
        navigationItem.leftBarButtonItem = nil
        
        // 处于视图模式下启用“编辑”按钮
        editButtonItem.isEnabled = true // TODO: 目前此设置无意义，因为它始终是可用状态。
        
        navigationItem.title = NSLocalizedString("View Reminder", comment: "view reminder nav title")
    }
    
    private func transitionToEditMode(_ reminder: Reminder) {
        dataSource = ReminderDetailEditDataSource(reminder: reminder) { reminder in
            // 内容被编辑后更新临时数据对象
            self.tempReminder = reminder
            self.editButtonItem.isEnabled = true // TODO: 目前此设置无意义，因为它始终是可用状态。
        }
        
        // 设置标题
        navigationItem.title = isNew ?
        NSLocalizedString("Add Reminder", comment: "add reminder nav title") :
        NSLocalizedString("Edit Reminder", comment: "edit reminder nav title") // [4]
        
        // 处于编辑模式下”取消按钮“
        navigationItem.leftBarButtonItem = .init(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonTrigger))
    }
    
    // 用户点击 editButtonItem 编辑按钮时系统自动会调用此方法，并且将 editing 参数传递为 true [2]
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        guard let reminder = reminder else {
            fatalError("No reminder found for detail view")
        }
        
        // 根据编辑状态来确定显示哪个视图
        if editing {
            transitionToEditMode(reminder)
            tableView.backgroundColor = UIColor(named: "EDIT_Background")
        } else {
            transitionToViewMode(reminder)
            tableView.backgroundColor = UIColor(named: "VIEW_Background")
        }
        
        tableView.dataSource = dataSource
        // 重新加载表格数据
        tableView.reloadData()
    }
    
    @objc // [5]
    private func cancelButtonTrigger() {
        if isNew {
            dismiss(animated: true)
        } else {
            tempReminder = nil
            setEditing(false, animated: true)
        }
    }
}

extension ReminderDetailViewController {
    
    // MARK: 为编辑视图和非编辑视图设置不同样式
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if isEditing {
            cell.backgroundColor = UIColor(named: "EDIT_TableRowBackground")
            
            // 设置编辑视图日期标签字体为蓝色
            guard let editSection = ReminderDetailEditDataSource.ReminderSection(rawValue: indexPath.section) else {
                return
            }
            // 设置字体样式
            if editSection == .dueDate && indexPath.row == 0 {
                cell.textLabel?.textColor = UIColor(named: "EDIT_DateLabelText")
                cell.textLabel?.font = .preferredFont(forTextStyle: .body)
            }
            
        } else {
            cell.backgroundColor = .systemBackground
            // 设置字体样式
            if let viewRow = ReminderDetailViewDataSource.ReminderRow(rawValue: indexPath.row), viewRow == .title {
                // [7]
                guard var configuration = cell.contentConfiguration as? UIListContentConfiguration else {
                    return
                }
                configuration.textProperties.font = .preferredFont(forTextStyle: .headline)
                cell.contentConfiguration = configuration
            } else {
                guard var configuration = cell.contentConfiguration as? UIListContentConfiguration else {
                    return
                }
                configuration.textProperties.font = .preferredFont(forTextStyle: .body)
                cell.contentConfiguration = configuration
            }
        }
    }
}

/*
 [1] Storyboard 初始化视图时，IOS 调用 init(coder:) 初始化器，configure 用于初始化后的配置。（比如在上一个视图使用 Segue 链接到此视图时，调用此方法设置本视图控制器需要的数据对象。）
 
 [2] 在用户点击编辑按钮（editButtonItem）时调用 editing 为 true，则应该显示为可编辑视图。
 
 [3] editButtonItem 会在导航栏添加一个编辑按钮，点击它将调用 setEditing(_:, animated:) 方法，可以重写它以提供自定义行为。
 
 [4] 本地化显示字符串
 
 [5] @objc属性将方法公开到Objective-C运行时。
 
 [6] 默认情况下 ToolBar 颜色是透明的，可能看不出此代码的意义，可以在 Storyboard 中的 Navigation Controller 中将其背景色设置为一个鲜明的颜色查看效果。 另外官方示例使用的是 viewDidAppear(animated:) 方法来实现，它会先显示一下 TollBar 然后再消失，我希望它在用户进入此视图前就消失，所以使用了 viewWillAppear(animated:) 方法。
 [7] 由于此单元格使用的是 cell.defaultContentConfiguration() 配置方式，而不是 cell.textLabel 配置方式，所以在设置其属性时与编辑视图中的 cell 有所不同。

  */
