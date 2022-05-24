//
//  EditTitleCell.swift
//  Today
//
//  Created by Liu Xuan on 2022/1/18.
//

import UIKit

class EditTitleCell: UITableViewCell {
    // 标题被改变时进行的操作
    typealias TitleChangeAction = (String) -> Void
    
    // [1]
    @IBOutlet var titleTextField: UITextField!
    
    private var titleChangeAction: TitleChangeAction?
    
    // [2]
    override func awakeFromNib() {
        super.awakeFromNib()
        // 配置 UITextFieldDelegate 委托对象为自己
        titleTextField.delegate = self
    }
    
    func configure(title: String, changeAction: @escaping TitleChangeAction) {
        self.titleTextField.text = title
        self.titleChangeAction = changeAction
    }
}

extension EditTitleCell: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let originText = textField.text {
            // 将原始字符串替换为编辑后的字符串（如果是删除字符，那么 string 参数将为空字符）
            let text = (originText as NSString).replacingCharacters(in: range, with: string)
            // 触发修改操作，并将修改后的“字符串”传递过去
            titleChangeAction?(text)
        }
        
        // 如果应该替换指定的范围的文本则返回 true，不替换则返回 false。
        return true
    }
}

/*
 [1] 使用自定义单元格类中的IBOutlet将故事板中的视图连接到此视图类，此连接使您的类可以引用单元格内的视图。（UIKit 初始化 Outlet 其中必须包含对视图的有效引用）
 
 [2] 当对象收到唤醒 awakeFromNib() 消息时，UIKit 它保证已经建立了所有 @Outlet 和 @Action 连接。 titleTextField 是一个 outlet，这应该是给它设置委托的最好时机。
 */
