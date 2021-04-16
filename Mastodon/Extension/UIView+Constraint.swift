//
//  UIView+Constraint.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/3/31.
//

import UIKit

enum Dimension {
    case width
    case height

    var layoutAttribute: NSLayoutConstraint.Attribute {
        switch self {
        case .width:
            return .width
        case .height:
            return .height
        }
    }

}

extension UIView {

    func constrain(toSuperviewEdges: UIEdgeInsets?) {
        guard let view = superview else { assert(false, "Superview cannot be nil when adding contraints"); return}
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
                NSLayoutConstraint(item: self,
                                   attribute: .leading,
                                   relatedBy: .equal,
                                   toItem: view,
                                   attribute: .leading,
                                   multiplier: 1.0,
                                   constant: toSuperviewEdges?.left ?? 0.0),
                NSLayoutConstraint(item: self,
                                   attribute: .top,
                                   relatedBy: .equal,
                                   toItem: view,
                                   attribute: .top,
                                   multiplier: 1.0,
                                   constant: toSuperviewEdges?.top ?? 0.0),
                NSLayoutConstraint(item: view,
                                   attribute: .trailing,
                                   relatedBy: .equal,
                                   toItem: self,
                                   attribute: .trailing,
                                   multiplier: 1.0,
                                   constant: toSuperviewEdges?.right ?? 0.0),
                NSLayoutConstraint(item: view,
                                   attribute: .bottom,
                                   relatedBy: .equal,
                                   toItem: self,
                                   attribute: .bottom,
                                   multiplier: 1.0,
                                   constant: toSuperviewEdges?.bottom ?? 0.0)
            ])
    }

    func constrain(_ constraints: [NSLayoutConstraint?]) {
        guard superview != nil else { assert(false, "Superview cannot be nil when adding contraints"); return }
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(constraints.compactMap { $0 })
    }

    func constraint(_ attribute: NSLayoutConstraint.Attribute, toView: UIView, constant: CGFloat?) -> NSLayoutConstraint? {
        guard superview != nil else { assert(false, "Superview cannot be nil when adding contraints"); return nil}
        translatesAutoresizingMaskIntoConstraints = false
        return NSLayoutConstraint(item: self, attribute: attribute, relatedBy: .equal, toItem: toView, attribute: attribute, multiplier: 1.0, constant: constant ?? 0.0)
    }

    func constraint(_ attribute: NSLayoutConstraint.Attribute, toView: UIView) -> NSLayoutConstraint? {
        guard superview != nil else { assert(false, "Superview cannot be nil when adding contraints"); return nil}
        translatesAutoresizingMaskIntoConstraints = false
        return NSLayoutConstraint(item: self, attribute: attribute, relatedBy: .equal, toItem: toView, attribute: attribute, multiplier: 1.0, constant: 0.0)
    }

    func constraint(_ dimension: Dimension, constant: CGFloat) -> NSLayoutConstraint? {
        guard superview != nil else { assert(false, "Superview cannot be nil when adding contraints"); return nil }
        translatesAutoresizingMaskIntoConstraints = false
        return NSLayoutConstraint(item: self,
                                  attribute: dimension.layoutAttribute,
                                  relatedBy: .equal,
                                  toItem: nil,
                                  attribute: .notAnAttribute,
                                  multiplier: 1.0,
                                  constant: constant)
    }

    func constrainTopCorners(sidePadding: CGFloat, topPadding: CGFloat, topLayoutGuide: UILayoutSupport) {
        guard let view = superview else { assert(false, "Superview cannot be nil when adding contraints"); return }
        translatesAutoresizingMaskIntoConstraints = false
        constrain([
                constraint(.leading, toView: view, constant: sidePadding),
                NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: topLayoutGuide, attribute: .bottom, multiplier: 1.0, constant: topPadding),
                constraint(.trailing, toView: view, constant: -sidePadding)
            ])
    }

    func constrainTopCorners(sidePadding: CGFloat, topPadding: CGFloat) {
        guard let view = superview else { assert(false, "Superview cannot be nil when adding contraints"); return }
        translatesAutoresizingMaskIntoConstraints = false
        constrain([
                constraint(.leading, toView: view, constant: sidePadding),
                constraint(.top, toView: view, constant: topPadding),
                constraint(.trailing, toView: view, constant: -sidePadding)
            ])
    }

    func constrainTopCorners(height: CGFloat) {
        guard let view = superview else { assert(false, "Superview cannot be nil when adding contraints"); return }
        translatesAutoresizingMaskIntoConstraints = false
        constrain([
                constraint(.leading, toView: view),
                constraint(.top, toView: view),
                constraint(.trailing, toView: view),
                constraint(.height, constant: height)
            ])
    }

    func constrainBottomCorners(sidePadding: CGFloat, bottomPadding: CGFloat) {
        guard let view = superview else { assert(false, "Superview cannot be nil when adding contraints"); return }
        translatesAutoresizingMaskIntoConstraints = false
        constrain([
                constraint(.leading, toView: view, constant: sidePadding),
                constraint(.bottom, toView: view, constant: -bottomPadding),
                constraint(.trailing, toView: view, constant: -sidePadding)
            ])
    }

    func constrainBottomCorners(height: CGFloat) {
        guard let view = superview else { assert(false, "Superview cannot be nil when adding contraints"); return }
        translatesAutoresizingMaskIntoConstraints = false
        constrain([
                constraint(.leading, toView: view),
                constraint(.bottom, toView: view),
                constraint(.trailing, toView: view),
                constraint(.height, constant: height)
            ])
    }

    func constrainLeadingCorners() {
        guard let view = superview else { assert(false, "Superview cannot be nil when adding contraints"); return }
        translatesAutoresizingMaskIntoConstraints = false
        constrain([
                constraint(.top, toView: view),
                constraint(.leading, toView: view),
                constraint(.bottom, toView: view)
            ])
    }

    func constrainTrailingCorners() {
        guard let view = superview else { assert(false, "Superview cannot be nil when adding contraints"); return }
        translatesAutoresizingMaskIntoConstraints = false
        constrain([
                constraint(.top, toView: view),
                constraint(.trailing, toView: view),
                constraint(.bottom, toView: view)
            ])
    }

    func constrainToCenter() {
        guard let view = superview else { assert(false, "Superview cannot be nil when adding contraints"); return }
        translatesAutoresizingMaskIntoConstraints = false
        constrain([
            constraint(.centerX, toView: view),
            constraint(.centerY, toView: view)
        ])
    }

    func pin(toSize: CGSize) {
        guard superview != nil else { assert(false, "Superview cannot be nil when adding contraints"); return }
        translatesAutoresizingMaskIntoConstraints = false
        constrain([
            widthAnchor.constraint(equalToConstant: toSize.width).priority(.required - 1),
            heightAnchor.constraint(equalToConstant: toSize.height).priority(.required - 1)
        ])
    }

    func pin(top: CGFloat?,left: CGFloat?,bottom: CGFloat?, right: CGFloat?) {
        guard let view = superview else { assert(false, "Superview cannot be nil when adding contraints"); return }
        translatesAutoresizingMaskIntoConstraints = false
        var constraints = [NSLayoutConstraint]()
        if let topConstant = top {
            constraints.append(topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant))
        }
        if let leftConstant = left {
            constraints.append(leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: leftConstant))
        }
        if let bottomConstant = bottom {
            constraints.append(view.bottomAnchor.constraint(equalTo: bottomAnchor, constant: bottomConstant))
        }
        if let rightConstant = right {
            constraints.append(view.trailingAnchor.constraint(equalTo: trailingAnchor, constant: rightConstant))
        }
        constrain(constraints)

    }
    func pinTopLeft(padding: CGFloat) {
        guard let view = superview else { assert(false, "Superview cannot be nil when adding contraints"); return }
        translatesAutoresizingMaskIntoConstraints = false
        constrain([
            leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            topAnchor.constraint(equalTo: view.topAnchor, constant: padding)])
    }
    
    func pinTopLeft(top: CGFloat, left: CGFloat) {
        guard let view = superview else { assert(false, "Superview cannot be nil when adding contraints"); return }
        translatesAutoresizingMaskIntoConstraints = false
        constrain([
            leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: left),
            topAnchor.constraint(equalTo: view.topAnchor, constant: top)])
    }
    
    func pinTopRight(padding: CGFloat) {
        guard let view = superview else { assert(false, "Superview cannot be nil when adding contraints"); return }
        translatesAutoresizingMaskIntoConstraints = false
        constrain([
            view.trailingAnchor.constraint(equalTo: trailingAnchor, constant: padding),
            topAnchor.constraint(equalTo: view.topAnchor, constant: padding)])
    }
    
    func pinTopRight(top: CGFloat, right: CGFloat) {
        guard let view = superview else { assert(false, "Superview cannot be nil when adding contraints"); return }
        translatesAutoresizingMaskIntoConstraints = false
        constrain([
            view.trailingAnchor.constraint(equalTo: trailingAnchor, constant: right),
            topAnchor.constraint(equalTo: view.topAnchor, constant: top)])
    }

    func pinTopLeft(toView: UIView, topPadding: CGFloat) {
        guard superview != nil else { assert(false, "Superview cannot be nil when adding contraints"); return }
        translatesAutoresizingMaskIntoConstraints = false
        constrain([
            leadingAnchor.constraint(equalTo: toView.leadingAnchor),
            topAnchor.constraint(equalTo: toView.bottomAnchor, constant: topPadding)])
    }
    
    /// Cross-fades between two views by animating their alpha then setting one or the other hidden.
    /// - parameters:
    ///     - lhs: left view
    ///     - rhs: right view
    ///     - toRight: fade to the right view if true, fade to the left view if false
    ///     - duration: animation duration
    ///
    static func crossfade(_ lhs: UIView, _ rhs: UIView, toRight: Bool, duration: TimeInterval) {
        lhs.alpha = toRight ? 1.0 : 0.0
        rhs.alpha = toRight ? 0.0 : 1.0
        lhs.isHidden = false
        rhs.isHidden = false
        
        UIView.animate(withDuration: duration, animations: {
            lhs.alpha = toRight ? 0.0 : 1.0
            rhs.alpha = toRight ? 1.0 : 0.0
        }, completion: { _ in
            lhs.isHidden = toRight
            rhs.isHidden = !toRight
        })
    }
}
