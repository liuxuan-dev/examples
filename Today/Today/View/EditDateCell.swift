//
//  EditDateCell.swift
//  Today
//
//  Created by Liu Xuan on 2022/1/18.
//

import UIKit

class EditDateCell: UITableViewCell {
    typealias DateChangeAction = (Date) -> Void
    
    @IBOutlet var datePicker: UIDatePicker!
    
    private var dateChangeAction: DateChangeAction?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        datePicker.addTarget(self, action: #selector(Self.dateChanged(_:)), for: .valueChanged)
    }
    
    func configure(date: Date, changeAction: @escaping DateChangeAction) {
        self.datePicker.date = date
        self.dateChangeAction = changeAction
    }
    
    // 日期被更改
    @objc
    func dateChanged(_ datePicker: UIDatePicker) {
        self.datePicker.date = datePicker.date
        self.dateChangeAction?(self.datePicker.date)
    }
}
