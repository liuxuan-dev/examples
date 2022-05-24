//
//  ReminderListViewController.swift
//  Today
//
//  Created by Liu Xuan on 2022/1/16.
//

import UIKit

class ReminderListViewController: UITableViewController {
    
    @IBOutlet var filterSegmentedControl: UISegmentedControl!
    // 提醒进度容器
    @IBOutlet var progressContainerView: UIView!
    @IBOutlet var precentIncompleteView: UIView!
    @IBOutlet var precentCompleteView: UIView!
    @IBOutlet var precentCompleteHeightConstraint: NSLayoutConstraint!
    
    static let showReminderDetailSegueIndentifer = "ShowReminderDetailSegue"
    static let storyboardName = "Main"
    static let reminderDetailViewControllerIdentifier = "ReminderDetailViewController"
    
    private var reminderListDataSource: ReminderListDataSource?
    private var filter: ReminderListDataSource.Filter {
        return .init(rawValue: filterSegmentedControl.selectedSegmentIndex) ?? .today
    }
    
    // 通知视图控制器即将执行 Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // 1. 利用 segue.identifier 确定是哪一个 Segue
        // 2. 利用 segue.destination 获取目标视图控制器对象
        // 3. 利用 sender 得到对应的单元格对象
        // 4. 利用 tableView 对象得到单元格索引
        // 5. 利用 indexPath.row 单元格索引从数据集中找到对应的数据对象
        // 6. 利用目标视图控制器提供的 configure(with:) 方法注入数据对象
        if segue.identifier == Self.showReminderDetailSegueIndentifer,
            let destination = segue.destination as? ReminderDetailViewController,
            let cell = sender as? UITableViewCell,
            let indexPath = tableView.indexPath(for: cell) {
            guard let reminder = reminderListDataSource?.reminder(at: indexPath.row) else {
                fatalError("Couldn't find data source for reminder list.")
            }
            destination.configure(with: reminder, editAction: { reminder in
                self.reminderListDataSource?.update(reminder, at: indexPath.row) { success in
                    if success {
                        DispatchQueue.main.async {
                            // 重新加载已更新内容的行
                            self.tableView.reloadRows(at: [indexPath], with: .automatic)
                            self.refreshProgressView()
                        }
                    } else {
                        // 更新失败提示
                        let alertTitle = NSLocalizedString("Can't Update Reminder", comment: "error updating reimider title")
                        let alertMessage = NSLocalizedString("An error occured while attempting to update the reminder.", comment: "error updating reminder message")
                        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
                        
                        let actionTitle = NSLocalizedString("OK", comment: "ok action title")
                        
                        alert.addAction(UIAlertAction(title: actionTitle, style: .default, handler: { _ in
                            self.dismiss(animated: true)
                        }))
                        
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            })
        }
    }
    
    // [1]
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.showsHorizontalScrollIndicator = false // [4]
        
        // 设置表格数据源
        reminderListDataSource = ReminderListDataSource(reminderCompletedAction: { row in
            DispatchQueue.main.async {
                self.tableView.reloadRows(at: [.init(row: row, section: 0)], with: .none)
                self.refreshProgressView()
            }
        }, reminderDeletedAction: { success in
            if success {
                self.refreshProgressView()
            } else {
                // 删除失败提示
                let alertTitle = NSLocalizedString("Can't Delete Reminder", comment: "error deleting reimider title")
                let alertMessage = NSLocalizedString("An error occured while attempting to add the reminder.", comment: "error deleting reminder message")
                let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
                
                let actionTitle = NSLocalizedString("OK", comment: "ok action title")
                
                alert.addAction(UIAlertAction(title: actionTitle, style: .default, handler: { _ in
                    self.dismiss(animated: true)
                }))
                
                self.present(alert, animated: true, completion: nil)
            }

        }, remindersChangedAction: {
            // 因为数据是在后台线程中加载的，所以需要切换回主线程更新界面。
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.refreshProgressView()
            }
        })
        
        tableView.dataSource = reminderListDataSource
    }
    
    // 由于在 ReminderDetailViewController 中将其隐藏了，所以需要在进入此页面前重新设置 ToolBar 为显示状态
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 显示底部工具栏（新增按钮）
        if let navigationController = navigationController, navigationController.isToolbarHidden {
            navigationController.setToolbarHidden(false, animated: false)
        }
        
        // 为进度容器视图设置一个圆形遮罩
        // 提示：progressContainerView 是父容器宽度的 70 % 所以后面乘以 0.7
        let radius = view.bounds.width * 0.5 * 0.7 // [3]
        progressContainerView.layer.cornerRadius = radius
        // 默认情况下子视图超出父视图边界不会被裁剪，此处设置为 true 表示要裁剪。
        progressContainerView.layer.masksToBounds = true
        
        // 刷新背景色
        refreshBackground()
    }
    
    // 监听过滤条件的变更
    @IBAction func segmentedControlChanged(_ sender: UISegmentedControl) {
        reminderListDataSource?.filter = filter
        // 重新加载表格数据
        tableView.reloadData()
        // 刷新进度视图
        refreshProgressView()
        // 刷新背景色
        refreshBackground()
    }
    
    @IBAction func addButtonTriggered(_ sender: UIBarButtonItem) {
        addReminder()
    }
    
    private func addReminder() {
        
        // 创建一个 Storyboard 实例
        // MARK: 不使用 self.storyboard 是因为 addReminder() 方法假设不在拥有导航控制器的对象中则无法使用？
        let storyboard = UIStoryboard(name: Self.storyboardName, bundle: nil)
        
        // 利用故事板标识符和故事板对象以编程方式创建 ReminderDetailViewController 实例
        let detailViewController: ReminderDetailViewController = storyboard.instantiateViewController(identifier: Self.reminderDetailViewControllerIdentifier)
        
        // 创建并配置一个导航控制器 [2]
        let navigationController = UINavigationController(rootViewController: detailViewController)
        
        // 配置详情控制器
        let reminder = Reminder(id: UUID().uuidString, title: "New Reminder", dueDate: Date())
        detailViewController.configure(with: reminder, isNew: true, addAction:  { reminder in
            self.reminderListDataSource?.add(reminder) { success, index in
                if success {
                    if let index = index {
                        self.tableView.insertRows(at: [.init(row: index, section: 0)], with: .automatic)
                        // 刷新进度视图
                        self.refreshProgressView()
                    }
                } else {
                    // 新增失败提示
                    let alertTitle = NSLocalizedString("Can't Add Reminder", comment: "error adding reimider title")
                    let alertMessage = NSLocalizedString("An error occured while attempting to add the reminder.", comment: "error adding reminder message")
                    let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
                    
                    let actionTitle = NSLocalizedString("OK", comment: "ok action title")
                    
                    alert.addAction(UIAlertAction(title: actionTitle, style: .default, handler: { _ in
                        self.dismiss(animated: true)
                    }))
                    
                    self.present(alert, animated: true, completion: nil)
                }
            }
        })

        // 以模态形式显示视图
        present(navigationController, animated: true, completion: nil)
    }
    
    // 刷新进度视图
    private func refreshProgressView() {
        guard let percentComplete = reminderListDataSource?.percentComplete else {
            return
        }
        // 更新完成视图
        precentCompleteHeightConstraint.constant = progressContainerView.bounds.height * CGFloat(percentComplete)
        // 使用设置的约束来确定任何子视图的大小和位置，并且添加动画效果。
        UIView.animate(withDuration: 0.2) {
            self.progressContainerView.layoutSubviews()
        }
    }
    
    /// 刷新背景视图
    /// 根据 Filter 过滤条件提供对应的背景视图
    private func refreshBackground() {
        tableView.backgroundView = nil
        let backgroundView = UIView()
        if let backgroundColors = filter.backgroundColors {
            // 在背景颜色上绘制渐变
            let gradientBackgroundLayer = CAGradientLayer()
            gradientBackgroundLayer.colors = backgroundColors
            gradientBackgroundLayer.frame = tableView.frame
            backgroundView.layer.addSublayer(gradientBackgroundLayer)
            
        } else {
            // 没有成功设置渐变色则分配一个代替背景颜色
            backgroundView.backgroundColor = filter.subtitueBackgroundColor
        }
        
        tableView.backgroundView = backgroundView
    }
}

// MARK: 创建背景渐变色
extension ReminderListDataSource.Filter {
    
    var gradientBeginColor: UIColor? {
        switch self {
        case .today:
            return .init(named: "LIST_GradientTodayBegin")
        case .future:
            return .init(named: "LIST_GradientFutureBegin")
        case .all:
            return .init(named: "LIST_GradientAllBegin")
        }
    }
    
    var gradientEndColor: UIColor? {
        switch self {
        case .today:
            return .init(named: "LIST_GradientTodayEnd")
        case .future:
            return .init(named: "LIST_GradientFutureEnd")
        case .all:
            return .init(named: "LIST_GradientAllEnd")
        }
    }
    
    //MARK: 为何要返回为 CGColor 类型？
    var backgroundColors: [CGColor]? {
        guard let beginColor = gradientBeginColor, let endColor = gradientEndColor else {
            return nil
        }
        return [beginColor.cgColor, endColor.cgColor]
    }
    
    var subtitueBackgroundColor: UIColor {
        return gradientBeginColor ?? UIColor.tertiarySystemBackground
    }
    
}

/*
 [1] 视图控制器将视图加入到内存中，然后就执行 loadView() 方法。
 [2] 因为以模态显示详情视图控制器，它不属于现有导航的一部分。想要包含导航标题和按钮，需要创建一个新的导航
 [3] 不使用 progressContainerView.bround.width * 0.5 计算半径是因为采用了自动布局后，直接获取的尺寸信息肯能还是 IB 界面中设置的，需要显示调用 progressContainerView.layer.layoutIfNeeded() 重新计算后才能获取到自动布局计算后的尺寸。 所以此处直接根据父视图宽度来计算（相当于在代码中写了一套和自动布局计算一样的规则来算出对应的尺寸。） 关于这个问题的讨论：https://stackoverflow.com/questions/13446920/how-can-i-get-a-views-current-width-and-height-when-using-autolayout-constraint
 [4] 首次启动应用时短暂出现横向滚动条，但暂未找到具体原因，所以此处将其隐藏。

 */
