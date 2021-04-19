//
//  SettingsLinkTableViewCell.swift
//  Mastodon
//
//  Created by ihugo on 2021/4/8.
//

import UIKit

class SettingsLinkTableViewCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        textLabel?.alpha = highlighted ? 0.6 : 1.0
    }
    
    // MARK: - Methods
    func update(with data: SettingsItem.Link) {
        textLabel?.text = data.title
        textLabel?.textColor = data.color
    }
}
