//
//  TouchIndicatorView.swift
//  TouchIndicator
//
//  The circle drawn under one finger.
//

import UIKit

final class TouchIndicatorView: UIView {

    private let configuredColor: UIColor?

    init(configuration: TouchIndicator.Configuration) {
        configuredColor = configuration.color
        let diameter = configuration.diameter
        super.init(frame: CGRect(x: 0, y: 0, width: diameter, height: diameter))
        // Must never intercept the touch it is drawn under.
        isUserInteractionEnabled = false
        layer.cornerRadius = diameter / 2
        layer.borderWidth = 2
        layer.borderColor = configuration.borderColor.cgColor
        alpha = 0
        transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        // `tintColor` only resolves to the host's accent once we are in a
        // window, so the fill is applied here rather than in init.
        backgroundColor = (configuredColor ?? tintColor).withAlphaComponent(0.6)
    }

    func appear(at point: CGPoint) {
        center = point
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut, .beginFromCurrentState]) {
            self.alpha = 1
            self.transform = .identity
        }
    }

    func move(to point: CGPoint) {
        center = point
    }

    func dismiss() {
        UIView.animate(withDuration: 0.4, delay: 0, options: [.curveEaseOut, .beginFromCurrentState]) {
            self.alpha = 0
            self.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        } completion: { _ in
            self.removeFromSuperview()
        }
    }
}
