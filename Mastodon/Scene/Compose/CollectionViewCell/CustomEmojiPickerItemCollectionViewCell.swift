//
//  CustomEmojiPickerItemCollectionViewCell.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-24.
//

import UIKit

final class CustomEmojiPickerItemCollectionViewCell: UICollectionViewCell {
    
    static let itemSize = CGSize(width: 44, height: 44)
    
    let emojiImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    override var isHighlighted: Bool {
        didSet {
            emojiImageView.alpha = isHighlighted ? 0.5 : 1.0
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension CustomEmojiPickerItemCollectionViewCell {
    
    private func _init() {
        emojiImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(emojiImageView)
        NSLayoutConstraint.activate([
            emojiImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            emojiImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            emojiImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            emojiImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }
    
}
