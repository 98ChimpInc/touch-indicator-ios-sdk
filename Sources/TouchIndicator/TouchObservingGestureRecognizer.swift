//
//  TouchObservingGestureRecognizer.swift
//  TouchIndicator
//
//  Observes every touch on a window and draws an indicator under it. It must
//  never consume, delay, or compete with the host app's own touch handling,
//  so it stays in `.possible` for its whole life and opts out of the
//  prevention system entirely.
//

import UIKit

final class TouchObservingGestureRecognizer: UIGestureRecognizer, UIGestureRecognizerDelegate {

    private let configuration: TouchIndicator.Configuration
    private var indicators: [UITouch: TouchIndicatorView] = [:]

    init(configuration: TouchIndicator.Configuration) {
        self.configuration = configuration
        super.init(target: nil, action: nil)
        cancelsTouchesInView = false
        delaysTouchesBegan = false
        delaysTouchesEnded = false
        delegate = self
    }

    // MARK: - Touch observation

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        guard let window = view else { return }
        for touch in touches {
            let indicator = TouchIndicatorView(configuration: configuration)
            window.addSubview(indicator)
            indicator.appear(at: touch.location(in: window))
            indicators[touch] = indicator
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        guard let window = view else { return }
        for touch in touches {
            indicators[touch]?.move(to: touch.location(in: window))
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        release(touches)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        release(touches)
    }

    override func reset() {
        // UIKit resets a `.possible` recogniser once its last touch ends.
        // Anything still tracked here belongs to a touch we never saw end.
        indicators.values.forEach { $0.dismiss() }
        indicators.removeAll()
    }

    private func release(_ touches: Set<UITouch>) {
        for touch in touches {
            indicators.removeValue(forKey: touch)?.dismiss()
        }
    }

    // MARK: - Never compete with other recognisers

    override func canPrevent(_ preventedGestureRecognizer: UIGestureRecognizer) -> Bool { false }

    override func canBePrevented(by preventingGestureRecognizer: UIGestureRecognizer) -> Bool { false }

    override func shouldRequireFailure(of otherGestureRecognizer: UIGestureRecognizer) -> Bool { false }

    override func shouldBeRequiredToFail(by otherGestureRecognizer: UIGestureRecognizer) -> Bool { false }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}
