//
//  Reminder.swift
//  Today
//
//  Created by Liu Xuan on 2022/1/16.
//

import Foundation

/// 提醒事项
struct Reminder {
    var id: String
    var title: String
    var dueDate: Date
    var notes: String? = nil
    var isComplete: Bool = false
}
