//
//  EditNotesCell.swift
//  Today
//
//  Created by Liu Xuan on 2022/1/18.
//

import UIKit

class EditNotesCell: UITableViewCell {
    
    typealias NotesChangeAction = (String) -> Void
    
    @IBOutlet var notesTextView: UITextView!
    
    var notesChangeAction: NotesChangeAction?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        notesTextView.delegate = self
    }
    
    func configure(notes: String?, changeAction: @escaping NotesChangeAction) {
        self.notesTextView.text = notes
        self.notesChangeAction = changeAction
    }
}

extension EditNotesCell: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if let originText = textView.text {
            let text = (originText as NSString).replacingCharacters(in: range, with: text)
            self.notesChangeAction?(text)
        }
        return true
    }
}
