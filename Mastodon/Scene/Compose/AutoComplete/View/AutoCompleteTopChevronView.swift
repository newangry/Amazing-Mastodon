//
//  AutoCompleteTopChevronView.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-5-14.
//

import UIKit

final class AutoCompleteTopChevronView: UIView {
    
    static let chevronSize = CGSize(width: 20, height: 12)
    
    private let shadowView = UIView()
    private let shadowLayer = CAShapeLayer()
    private let maskLayer = CAShapeLayer()
        
    var chevronMinX: CGFloat = 0
    var topViewBackgroundColor = Asset.Scene.Compose.background.color {
        didSet { setNeedsLayout() }
    }
    var bottomViewBackgroundColor = Asset.Colors.Background.systemBackground.color {
        didSet { setNeedsLayout() }
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

extension AutoCompleteTopChevronView {
    
    var standardizedChevronMinX: CGFloat {
        min(max(chevronMinX, 0), bounds.width - AutoCompleteTopChevronView.chevronSize.width)
    }
    
    var edgePoints: [CGPoint] {
        [
            CGPoint(x: standardizedChevronMinX, y: bounds.maxY),
            CGPoint(x: standardizedChevronMinX + 0.5 * AutoCompleteTopChevronView.chevronSize.width, y: bounds.maxY - AutoCompleteTopChevronView.chevronSize.height),
            CGPoint(x: standardizedChevronMinX + AutoCompleteTopChevronView.chevronSize.width, y: bounds.maxY),
            CGPoint(x: bounds.width, y: bounds.maxY),
        ]
    }
    
}

extension AutoCompleteTopChevronView {
    
    private func _init() {
        clipsToBounds = false
        backgroundColor = .clear
        isUserInteractionEnabled = false
        
        shadowView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(shadowView)
        NSLayoutConstraint.activate([
            shadowView.topAnchor.constraint(equalTo: topAnchor),
            shadowView.leadingAnchor.constraint(equalTo: leadingAnchor),
            shadowView.trailingAnchor.constraint(equalTo: trailingAnchor),
            shadowView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        shadowLayer.fillColor = topViewBackgroundColor.cgColor
        shadowView.layer.addSublayer(shadowLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // 1. setup shadow with chevron
        shadowLayer.path = {
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 0, y: bounds.maxY))
            // bottom edge
            for point in edgePoints {
                path.addLine(to: point)
            }
            // up egde
            path.addLine(to: CGPoint(x: bounds.maxX, y: 0))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.close()
            return path.cgPath
        }()
        shadowLayer.fillColor = topViewBackgroundColor.cgColor
        
        // 2. setup mask to clip shadow
        maskLayer.path = {
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 0, y: bounds.maxY))
            // up edge
            for point in edgePoints {
                path.addLine(to: CGPoint(x: point.x, y: point.y - 2))       // move up 2pt 
            }
            // bottom egde
            path.addLine(to: CGPoint(x: bounds.maxX, y: 2 * bounds.maxY))
            path.addLine(to: CGPoint(x: 0, y: 2 * bounds.maxY))
            path.close()
            return path.cgPath
        }()
        maskLayer.fillColor = UIColor.red.cgColor
        shadowView.layer.setupShadow(color: UIColor.black.withAlphaComponent(0.25))
        shadowView.layer.mask = maskLayer
        
        layer.mask = maskLayer
    }
    
}

extension AutoCompleteTopChevronView {
    func invertMask(in rect: CGRect) -> CAShapeLayer {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: bounds.maxY))
        // top edge
        for point in edgePoints {
            path.addLine(to: point)
        }
        // bottom edge
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: 0, y: rect.maxY))
        path.close()
        
        let mask = CAShapeLayer()
        mask.fillColor = UIColor.red.cgColor
        mask.path = path.cgPath
        
        return mask
    }
}


#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct AutoCompleteTopChevronView_Previews: PreviewProvider {
    
    static var previews: some View {
        Group {
            UIViewPreview(width: 375) {
                let view = AutoCompleteTopChevronView()
                view.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    view.widthAnchor.constraint(equalToConstant: 375),
                    view.heightAnchor.constraint(equalToConstant: 100),
                ])
                view.chevronMinX = 10
                return view
            }
            .background(Color(Asset.Scene.Compose.background.color))
            .padding(20)
            .previewLayout(.fixed(width: 375 + 40, height: 100 + 40))
            UIViewPreview(width: 375) {
                let view = AutoCompleteTopChevronView()
                view.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    view.widthAnchor.constraint(equalToConstant: 375),
                    view.heightAnchor.constraint(equalToConstant: 100),
                ])
                view.chevronMinX = 10
                return view
            }
            .background(Color(Asset.Scene.Compose.background.color))
            .preferredColorScheme(.dark)
            .padding(20)
            .previewLayout(.fixed(width: 375 + 40, height: 100 + 40))
        }
    }
    
}

#endif
