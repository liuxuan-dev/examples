//
//  ReminderListCell.swift
//  Today
//
//  Created by Liu Xuan on 2022/1/16.
//

import UIKit

class ReminderListCell: UITableViewCell {
    typealias DoneButtonAction = () -> Void // [1]
    
    @IBOutlet var title: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var doneButton: UIButton!
    
    private var doneButtonAction: DoneButtonAction?
    
    // [2]
    @IBAction func doneButtonTriggered(_ sender: UIButton) {
        doneButtonAction?()
    }
    
    // 对外提供一个配置 ReminderListCell 的方法
    func configure(title: String, dateText: String, isDone: Bool, doneButtonAction: @escaping DoneButtonAction) { // [3]
        self.title.text = title
        self.dateLabel.text = dateText
        let image = isDone ? UIImage(systemName: "circle.fill") : UIImage(systemName: "circle")
        self.doneButton.setBackgroundImage(image, for: .normal) // [4]
        self.doneButtonAction = doneButtonAction
    }
}

/*
 [1] 使用类型别名增强可读性
 [2] @IBAction 标识的实例方法将会被视为视图的 Action 操作。
 [3] 当闭包被存储在函数放回后执行时，闭包参数需要被声明为逃逸闭包 @escaping
 [4] 要让设置生效，必须在 IB 的 Attributes Inspector 面板中将 Button 的 style 属性值设为 default。
 */
