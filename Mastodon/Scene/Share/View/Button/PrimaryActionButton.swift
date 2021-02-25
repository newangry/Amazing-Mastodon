//
//  PrimaryActionButton.swift
//  Mastodon
//
//  Created by BradGao on 2021/2/20.
//

import UIKit

class PrimaryActionButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
}

extension PrimaryActionButton {
    private func _init() {
        titleLabel?.font = .preferredFont(forTextStyle: .headline)
        setTitleColor(Asset.Colors.lightWhite.color, for: .normal)
        setBackgroundImage(UIImage.placeholder(color: Asset.Colors.lightBrandBlue.color), for: .normal)
        setBackgroundImage(UIImage.placeholder(color: Asset.Colors.lightDisabled.color), for: .disabled)
        applyCornerRadius(radius: 10)
        setInsets(forContentPadding: UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0), imageTitlePadding: 0)
    }
}
