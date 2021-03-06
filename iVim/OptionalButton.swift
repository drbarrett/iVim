//
//  OptionalButton.swift
//  iVim
//
//  Created by Terry on 5/12/17.
//  Copyright © 2017 Boogaloo. All rights reserved.
//

import UIKit

extension UIDevice {
    var isPhone: Bool {
        return self.userInterfaceIdiom == .phone
    }
}

private let margin = CGFloat(3)

class OptionalButton: UIView {
    var info = [Int: OptionInfo]()
    var isSwitch = false
    var effectiveInfo: OptionInfo?
    var initTranslation: CGPoint?
    var startLocation: CGPoint!
    fileprivate(set) var isOn = false
    fileprivate var isHeld = false
    var primaryFontSize: CGFloat!
    var optionalFontSize: CGFloat!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.generalInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.generalInit()
    }
    
    private func generalInit() {
        self.setup()
    }
}

extension OptionalButton {
    fileprivate func setup() {
        self.layer.backgroundColor = UIColor.white.cgColor
        self.layer.cornerRadius = 4
    }
}

extension OptionalButton {
    func setOptions(_ options: [ButtonOption]) {
        let count = options.count
        guard count > 0 else { return }
        switch count {
        case 2: self.setKey(for: options[1], at: CGPoint(0.5, 0))
        case 4: self.setKey(for: options[3], at: CGPoint(0.5, 1))
        default: break
        }
        if count > 2 {
            self.setKey(for: options[1], at: CGPoint(0, 0))
            self.setKey(for: options[2], at: CGPoint(1, 0))
        }
        if count > 4 {
            self.setKey(for: options[3], at: CGPoint(0, 1))
            self.setKey(for: options[4], at: CGPoint(1, 1))
        }
        self.setPrimaryKey(for: options[0])
    }
    
    private func position(for anchorPoint: CGPoint) -> CGPoint {
        var x = anchorPoint.x * self.bounds.width
        var y = anchorPoint.y * self.bounds.height
        self.addMarginTo(&x, withAnchorInfo: anchorPoint.x)
        self.addMarginTo(&y, withAnchorInfo: anchorPoint.y)
        
        return CGPoint(x: x, y: y)
    }
    
    private func addMarginTo(_ p: inout CGFloat, withAnchorInfo ac: CGFloat) {
        if ac < 0.5 {
            p += margin
        } else if ac > 0.5 {
            p -= margin
        }
    }
    
    fileprivate func setFontSize(_ size: CGFloat, of layer: CATextLayer) {
        guard let title = layer.string as? String else { return }
        let font = UIFont.systemFont(ofSize: size)
        let contentSize = NSAttributedString(
            string: title,
            attributes: [.font: font]).size()
        let width = ceil(contentSize.width)
        let height = ceil(contentSize.height)
        layer.bounds = CGRect(x: 0, y: 0, width: width, height: height)
        layer.font = font.fontName as CFTypeRef
        layer.fontSize = size
    }
    
    private func addLayer(option: ButtonOption, color: UIColor, fontSize: CGFloat, anchorPoint: CGPoint) {
        let l = CATextLayer()
        l.contentsScale = UIScreen.main.scale
        l.string = option.title
        l.foregroundColor = color.cgColor
        l.anchorPoint = anchorPoint
        l.position = self.position(for: anchorPoint)
        l.alignmentMode = kCAAlignmentCenter
        self.setFontSize(fontSize, of: l)
        self.layer.addSublayer(l)
        let oi = OptionInfo(layer: l, action: option.action, isSticky: option.isSticky)
        self.info[anchorPoint.key] = oi
    }
    
    private func setKey(for option: ButtonOption, at anchorPoint: CGPoint) {
        self.addLayer(
            option: option,
            color: .gray,
            fontSize: optionalFontSize,
            anchorPoint: anchorPoint)
    }
    
    private func setPrimaryKey(for option: ButtonOption) {
        self.addLayer(
            option: option,
            color: .black,
            fontSize: primaryFontSize,
            anchorPoint: CGPoint(0.5, 0.5))
    }
}

extension OptionalButton {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let t = touches.first!
        self.startLocation = t.location(in: self)
        if self.isOn { return }
        self.layer.backgroundColor = UIColor.lightGray.cgColor
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.isOn { return }
        let tl = self.translation(for: touches.first!)
        self.scale(for: tl)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.doAction()
        if self.effectiveInfo?.isSticky ?? false {
            self.toggleHeld(with: touches.first!)
            self.toggleSticky()
        }
        if !self.isOn { self.restore() }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.restore()
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    private func translation(for touch: UITouch) -> CGPoint {
        let l = touch.location(in: self)
        
        return CGPoint(l.x - self.startLocation.x, l.y - self.startLocation.y)
    }
    
    private func toggleHeld(with touch: UITouch) {
        if self.isHeld {
            self.isHeld = false
            return
        }
        guard self.isOn,
            let key = self.key(for: self.translation(for: touch)),
            self.info[key]?.layer == self.effectiveInfo?.layer else { return }
        self.isHeld = true
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.layer.backgroundColor = UIColor.darkGray.cgColor
        self.effectiveInfo?.layer.foregroundColor = UIColor.white.cgColor
        CATransaction.commit()
    }
    
    private func toggleSticky() {
        guard !self.isHeld else { return }
        self.isOn = !self.isOn
    }
    
    fileprivate var primaryInfo: OptionInfo? {
        return self.info[CGPoint(0.5, 0.5).key]
    }
    
    private func key(for translation: CGPoint) -> Int? {
        let count = self.info.count
        var x: CGFloat?
        var y: CGFloat?
        if translation.y > 0 {
            y = 0
            x = count == 2 ? 0.5 : (translation.x < 0 ? 1 : 0)
        } else if translation.y < 0 {
            y = 1
            x = count == 4 ? 0.5 : (translation.x < 0 ? 1 : 0)
        }
        guard let xx = x, let yy = y else { return nil }
        
        return CGPoint(xx, yy).key
    }
    
    fileprivate func transform(layer: CATextLayer, scale: CGFloat) {
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.setAffineTransform(transform)
        layer.contentsScale = UIScreen.main.scale * scale
        CATransaction.commit()
    }
    
    private func initInfo(for translation: CGPoint) -> OptionInfo? {
        guard let k = self.key(for: translation) else { return nil }
        let i = self.info[k]
        self.effectiveInfo = i
        self.initTranslation = translation
        self.updateLayers(reset: false)
        
        return i
    }
    
    private func reset() {
        guard let i = self.effectiveInfo else { return }
        self.transform(layer: i.layer, scale: 1)
        self.updateLayers(reset: true)
        self.effectiveInfo = nil
        self.initTranslation = nil
    }
    
    private func restore() {
        self.layer.backgroundColor = UIColor.white.cgColor
        self.reset()
    }
    
    func isOn(withTitle title: String) -> Bool {
        return self.isOn && (self.effectiveInfo?.layer.string as? String) == title
    }
    
    func tryRestore() {
        guard !self.isHeld else { return }
        self.isOn = false
        self.restore()
    }
    
    private func info(for translation: CGPoint) -> OptionInfo? {
        guard let t = self.initTranslation else {
            return self.initInfo(for: translation)
        }
        let i: OptionInfo?
        if t.isInSamePhase(of: translation) {
            i = self.effectiveInfo
        } else {
            self.reset()
            i = self.initInfo(for: translation)
        }
        
        return i
    }
    
    private func updateLayers(reset: Bool) {
        guard let ei = self.effectiveInfo else { return }
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.18)
        let color: UIColor = reset ? .gray : .black
        ei.layer.foregroundColor = color.cgColor
        for l in self.info.values where l.layer !== ei.layer {
            l.layer.opacity = reset ? 1 : 0
        }
        CATransaction.commit()
    }
    
    private func scale(for translation: CGPoint) {
        guard let info = self.info(for: translation),
            info.layer.affineTransform().isIdentity else { return }
        let scale = primaryFontSize / optionalFontSize
        self.transform(layer: info.layer, scale: scale)
    }
    
    private func doAction() {
        let i = self.effectiveInfo ?? self.primaryInfo
        i?.action?(self)
    }
}

private extension CGPoint {
    var key: Int {
        return Int(self.x * 100 + self.y * 10)
    }
    
    init(_ x: CGFloat, _ y: CGFloat) {
        self.init(x: x, y: y)
    }
    
    var distance: CGFloat {
        return sqrt(pow(self.x, 2) + pow(self.y, 2))
    }
    
    func isInSamePhase(of point: CGPoint) -> Bool {
        return self.x * point.x > 0 && self.y * point.y > 0
    }
}

typealias Action = (OptionalButton) -> Void
struct ButtonOption {
    let title: String
    let action: Action?
    let isSticky: Bool
    
    init(title: String, action: Action?, isSticky: Bool = false) {
        self.title = title
        self.action = action
        self.isSticky = isSticky
    }
}

struct OptionInfo {
    let layer: CATextLayer
    let action: Action?
    let isSticky: Bool
}
