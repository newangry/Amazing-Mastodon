//
//  SearchRecommendAccountsCollectionViewCell.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/1.
//

import Combine
import CoreDataStack
import Foundation
import MastodonSDK
import UIKit

protocol SearchRecommendAccountsCollectionViewCellDelegate: NSObject {
    func followButtonDidPressed(clickedUser: MastodonUser)
    
    func configFollowButton(with mastodonUser: MastodonUser, followButton: HighlightDimmableButton)
}

class SearchRecommendAccountsCollectionViewCell: UICollectionViewCell {
    var disposeBag = Set<AnyCancellable>()
    
    weak var delegate: SearchRecommendAccountsCollectionViewCellDelegate?
    
    let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 8.4
        imageView.clipsToBounds = true
        return imageView
    }()
    
    let headerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 10
        imageView.clipsToBounds = true
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = Asset.Colors.Border.searchCard.color.cgColor
        return imageView
    }()
    
    let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
    
    let displayNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let acctLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .preferredFont(forTextStyle: .body)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let followButton: HighlightDimmableButton = {
        let button = HighlightDimmableButton(type: .custom)
        button.setTitleColor(.white, for: .normal)
        button.setTitle(L10n.Scene.Search.Recommend.Accounts.follow, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.white.cgColor
        return button
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        headerImageView.af.cancelImageRequest()
        avatarImageView.af.cancelImageRequest()
        visualEffectView.removeFromSuperview()
        disposeBag.removeAll()
    }
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
}

extension SearchRecommendAccountsCollectionViewCell {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        headerImageView.layer.borderColor = Asset.Colors.Border.searchCard.color.cgColor
        applyShadow(color: Asset.Colors.Shadow.searchCard.color, alpha: 0.1, x: 0, y: 3, blur: 12, spread: 0)
    }
    
    private func configure() {
        headerImageView.backgroundColor = Asset.Colors.brandBlue.color
        layer.cornerRadius = 10
        clipsToBounds = false
        applyShadow(color: Asset.Colors.Shadow.searchCard.color, alpha: 0.1, x: 0, y: 3, blur: 12, spread: 0)
        contentView.addSubview(headerImageView)
        headerImageView.pin(top: 16, left: 0, bottom: 0, right: 0)
        
        contentView.addSubview(avatarImageView)
        avatarImageView.pin(toSize: CGSize(width: 88, height: 88))
        avatarImageView.constrain([
            avatarImageView.constraint(.top, toView: contentView),
            avatarImageView.constraint(.centerX, toView: contentView)
        ])
        
        contentView.addSubview(displayNameLabel)
        displayNameLabel.constrain([
            displayNameLabel.constraint(.top, toView: contentView, constant: 108),
            displayNameLabel.constraint(.leading, toView: contentView),
            displayNameLabel.constraint(.trailing, toView: contentView),
            displayNameLabel.constraint(.centerX, toView: contentView)
        ])
        
        contentView.addSubview(acctLabel)
        acctLabel.constrain([
            acctLabel.constraint(.top, toView: contentView, constant: 132),
            acctLabel.constraint(.leading, toView: contentView),
            acctLabel.constraint(.trailing, toView: contentView),
            acctLabel.constraint(.centerX, toView: contentView)
        ])
        
        contentView.addSubview(followButton)
        followButton.pin(toSize: CGSize(width: 76, height: 24))
        followButton.constrain([
            followButton.constraint(.top, toView: contentView, constant: 159),
            followButton.constraint(.centerX, toView: contentView)
        ])
    }
    
    func config(with mastodonUser: MastodonUser) {
        displayNameLabel.text = mastodonUser.displayName.isEmpty ? mastodonUser.username : mastodonUser.displayName
        acctLabel.text = mastodonUser.acct
        avatarImageView.af.setImage(
            withURL: URL(string: mastodonUser.avatar)!,
            placeholderImage: UIImage.placeholder(color: .systemFill),
            imageTransition: .crossDissolve(0.2)
        )
        headerImageView.af.setImage(
            withURL: URL(string: mastodonUser.header)!,
            placeholderImage: UIImage.placeholder(color: .systemFill),
            imageTransition: .crossDissolve(0.2)
        ) { [weak self] _ in
            guard let self = self else { return }
            self.headerImageView.addSubview(self.visualEffectView)
            self.visualEffectView.pin(top: 0, left: 0, bottom: 0, right: 0)
        }
        delegate?.configFollowButton(with: mastodonUser, followButton: followButton)
        followButton.publisher(for: .touchUpInside)
            .sink { [weak self] _ in
                self?.followButtonDidPressed(mastodonUser: mastodonUser)
            }
            .store(in: &disposeBag)
    }
    
    func followButtonDidPressed(mastodonUser: MastodonUser) {
        delegate?.followButtonDidPressed(clickedUser: mastodonUser)
    }
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct SearchRecommendAccountsCollectionViewCell_Previews: PreviewProvider {
    static var controls: some View {
        Group {
            UIViewPreview {
                let cell = SearchRecommendAccountsCollectionViewCell()
                cell.avatarImageView.backgroundColor = .white
                cell.headerImageView.backgroundColor = .red
                cell.displayNameLabel.text = "sunxiaojian"
                cell.acctLabel.text = "sunxiaojian@mastodon.online"
                return cell
            }
            .previewLayout(.fixed(width: 257, height: 202))
        }
    }
    
    static var previews: some View {
        Group {
            controls.colorScheme(.light)
            controls.colorScheme(.dark)
        }
        .background(Color.gray)
    }
}

#endif
