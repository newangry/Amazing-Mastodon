//
//  PickServerCell.swift
//  Mastodon
//
//  Created by BradGao on 2021/2/24.
//

import os.log
import UIKit
import Combine
import MastodonSDK
import AlamofireImage
import Kanna
import MastodonAsset
import MastodonLocalization

class PickServerCell: UITableViewCell {
    
    var disposeBag = Set<AnyCancellable>()
        
    let containerView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 4
        return view
    }()
    
    let domainLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 20, weight: .semibold))
        label.textColor = Asset.Colors.Label.primary.color
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let checkbox: UIImageView = {
        let imageView = UIImageView()
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .body)
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .caption1).scaledFont(for: .systemFont(ofSize: 13, weight: .regular))
        label.numberOfLines = 0
        label.textColor = Asset.Colors.Label.primary.color
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var collapseConstraints: [NSLayoutConstraint] = []
    private var expandConstraints: [NSLayoutConstraint] = []
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag.removeAll()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

// MARK: - Methods to configure appearance
extension PickServerCell {
    private func _init() {
        selectionStyle = .none
        backgroundColor = Asset.Scene.Onboarding.background.color
                
        checkbox.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(checkbox)
        NSLayoutConstraint.activate([
            contentView.readableContentGuide.trailingAnchor.constraint(equalTo: checkbox.trailingAnchor, constant: 16),
            checkbox.heightAnchor.constraint(equalToConstant: 20),
            checkbox.widthAnchor.constraint(equalTo: checkbox.heightAnchor),
        ])
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 11),
            containerView.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor, constant: 16),
            checkbox.leadingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 16),
            contentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 11),
            checkbox.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
        ])
        
        containerView.addArrangedSubview(domainLabel)
        containerView.addArrangedSubview(descriptionLabel)
        containerView.setCustomSpacing(6, after: descriptionLabel)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            checkbox.image = UIImage(systemName: "checkmark")
            checkbox.tintColor = Asset.Colors.brand.color
        } else {
            checkbox.image = nil
        }
    }

}

