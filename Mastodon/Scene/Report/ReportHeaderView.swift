//
//  ReportView.swift
//  Mastodon
//
//  Created by ihugo on 2021/4/20.
//

import UIKit

struct ReportView {
    static var horizontalMargin: CGFloat { return 12 }
    static var verticalMargin: CGFloat { return 22 }
    static var buttonHeight: CGFloat { return 46 }
    static var skipBottomMargin: CGFloat { return 8 }
    static var continuTopMargin: CGFloat { return 22 }
}

final class ReportHeaderView: UIView {
    enum Step: Int {
        case one
        case two
    }
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = Asset.Colors.Label.secondary.color
        label.font = UIFontMetrics(forTextStyle: .subheadline)
            .scaledFont(for: .systemFont(ofSize: 15, weight: .regular))
        label.numberOfLines = 0
        return label
    }()
    
    lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.textColor = Asset.Colors.Label.primary.color
        label.font = UIFontMetrics(forTextStyle: .title3)
            .scaledFont(for: .systemFont(ofSize: 20, weight: .semibold))
        label.numberOfLines = 0
        return label
    }()
    
    lazy var stackview: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.alignment = .leading
        view.spacing = 2
        return view
    }()
    
    var step: Step = .one {
        didSet {
            switch step {
            case .one:
                titleLabel.text = L10n.Scene.Report.step1
                contentLabel.text = L10n.Scene.Report.content1
            case .two:
                titleLabel.text = L10n.Scene.Report.step2
                contentLabel.text = L10n.Scene.Report.content2
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = Asset.Colors.Background.systemElevatedBackground.color
        stackview.addArrangedSubview(titleLabel)
        stackview.addArrangedSubview(contentLabel)
        addSubview(stackview)
        
        stackview.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackview.safeAreaLayoutGuide.topAnchor.constraint(
                equalTo: self.topAnchor,
                constant: ReportView.verticalMargin
            ),
            stackview.leadingAnchor.constraint(
                equalTo: self.readableContentGuide.leadingAnchor,
                constant: ReportView.horizontalMargin
            ),
            stackview.bottomAnchor.constraint(
                equalTo: self.bottomAnchor,
                constant: -1 * ReportView.verticalMargin
            ),
            stackview.trailingAnchor.constraint(
                equalTo: self.readableContentGuide.trailingAnchor,
                constant: -1 * ReportView.horizontalMargin
            )
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct ReportHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            UIViewPreview { () -> UIView in
                let view = ReportHeaderView()
                view.step = .one
                view.contentLabel.preferredMaxLayoutWidth = 335
                return view
            }
            .previewLayout(.fixed(width: 375, height: 110))
        }
    }
    
}

#endif
