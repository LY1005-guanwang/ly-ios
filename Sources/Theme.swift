//
//  Theme.swift — 设计系统（对标大厂：Apple HIG / Material 3 的层次与留白）
//  玻璃卡片 / 玻璃 TabBar / 药丸按钮 / 进度环 / 统计块 / 分组头 / 骨架
//

import UIKit

// MARK: - 设计令牌

enum DS {
    // 颜色
    static let bg      = UIColor(red: 0.949, green: 0.953, blue: 0.961, alpha: 1)   // #F6F7F8
    static let label   = UIColor(red: 0.06, green: 0.07, blue: 0.08, alpha: 1)
    static let label2  = UIColor(red: 0.36, green: 0.39, blue: 0.42, alpha: 1)
    static let label3  = UIColor(red: 0.60, green: 0.62, blue: 0.65, alpha: 1)
    static let accent  = UIColor(red: 0.10, green: 0.45, blue: 0.40, alpha: 1)      // 墨绿
    static let accentLo = UIColor(red: 0.85, green: 0.93, blue: 0.92, alpha: 1)
    static let danger  = UIColor(red: 0.74, green: 0.22, blue: 0.22, alpha: 1)
    static let ok      = UIColor(red: 0.16, green: 0.72, blue: 0.51, alpha: 1)
    static let hair    = UIColor(white: 0, alpha: 0.05)

    // 圆角 / 间距
    static let r: CGFloat = 26
    static let rSmall: CGFloat = 18
    static let pad: CGFloat = 20
    static let gap: CGFloat = 14

    // 字体
    static func h1(_ s: CGFloat = 34) -> UIFont { .systemFont(ofSize: s, weight: .bold) }
    static func h2(_ s: CGFloat = 22) -> UIFont { .systemFont(ofSize: s, weight: .semibold) }
    static func body(_ s: CGFloat = 16) -> UIFont { .systemFont(ofSize: s, weight: .regular) }
    static func mono(_ s: CGFloat = 22) -> UIFont { .monospacedDigitSystemFont(ofSize: s, weight: .semibold) }
    static func cap(_ s: CGFloat = 12) -> UIFont { .systemFont(ofSize: s, weight: .medium) }
}

// MARK: - 玻璃卡片（高斯模糊 + 渐变描边 + 内外高光）

final class GlassCard: UIView {
    private let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialLight))
    private let rim  = CAGradientLayer()
    private let sheen = CAGradientLayer()
    var radius: CGFloat = DS.r

    init(radius: CGFloat = DS.r, tint: CGFloat = 0.42) {
        super.init(frame: .zero)
        self.radius = radius
        backgroundColor = UIColor(white: 1, alpha: tint)
        layer.cornerRadius = radius
        layer.cornerCurve = .continuous
        layer.shadowColor = UIColor(red: 0.40, green: 0.45, blue: 0.52, alpha: 0.10).cgColor
        layer.shadowOpacity = 1
        layer.shadowRadius = 16
        layer.shadowOffset = CGSize(width: 0, height: 6)

        blur.layer.cornerRadius = radius
        blur.layer.cornerCurve = .continuous
        blur.clipsToBounds = true
        addSubview(blur)

        rim.colors = [UIColor(white: 1, alpha: 0.90).cgColor,
                      UIColor(white: 1, alpha: 0.10).cgColor,
                      UIColor(white: 1, alpha: 0.45).cgColor]
        rim.locations = [0, 0.55, 1]
        rim.startPoint = CGPoint(x: 0, y: 0)
        rim.endPoint = CGPoint(x: 1, y: 1)
        layer.addSublayer(rim)

        sheen.colors = [UIColor(white: 1, alpha: 0.32).cgColor,
                        UIColor(white: 1, alpha: 0).cgColor]
        sheen.startPoint = CGPoint(x: 0.5, y: 0)
        sheen.endPoint = CGPoint(x: 0.5, y: 0.4)
        layer.addSublayer(sheen)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        blur.frame = bounds
        rim.frame = bounds
        rim.borderWidth = 1
        let m = CAShapeLayer()
        m.path = UIBezierPath(roundedRect: bounds, cornerRadius: radius).cgPath
        rim.mask = m
        sheen.frame = bounds
        sheen.cornerRadius = radius
    }
}

// MARK: - 药丸按钮

final class PillButton: UIControl {
    enum Kind { case primary, secondary, danger, plain }
    private let grad = CAGradientLayer()
    private let lbl = UILabel()
    private let ico = UIImageView()
    private var kind: Kind = .primary

    init(_ title: String, symbol: String? = nil, kind: Kind = .primary, height: CGFloat = 52) {
        super.init(frame: .zero)
        self.kind = kind
        layer.cornerRadius = height / 2
        layer.cornerCurve = .continuous
        layer.masksToBounds = false

        switch kind {
        case .primary:
            grad.colors = [UIColor(red: 0.13, green: 0.50, blue: 0.44, alpha: 1).cgColor,
                           UIColor(red: 0.07, green: 0.36, blue: 0.33, alpha: 1).cgColor]
            grad.startPoint = CGPoint(x: 0, y: 0)
            grad.endPoint = CGPoint(x: 1, y: 1)
            grad.cornerRadius = height / 2
            layer.insertSublayer(grad, at: 0)
            layer.shadowColor = DS.accent.withAlphaComponent(0.35).cgColor
            layer.shadowOpacity = 1
            layer.shadowRadius = 14
            layer.shadowOffset = CGSize(width: 0, height: 6)
            lbl.textColor = .white
        case .secondary:
            backgroundColor = UIColor(white: 1, alpha: 0.88)
            layer.borderWidth = 1
            layer.borderColor = UIColor(white: 0.88, alpha: 1).cgColor
            lbl.textColor = DS.accent
        case .danger:
            backgroundColor = DS.danger.withAlphaComponent(0.10)
            lbl.textColor = DS.danger
        case .plain:
            backgroundColor = .clear
            lbl.textColor = DS.accent
        }

        lbl.text = title
        lbl.font = .systemFont(ofSize: 16, weight: .semibold)
        lbl.textAlignment = .center
        lbl.isUserInteractionEnabled = false
        addSubview(lbl)

        if let s = symbol {
            ico.image = UIImage(systemName: s, withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold))
            ico.tintColor = lbl.textColor
            ico.contentMode = .scaleAspectFit
            addSubview(ico)
            ico.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                ico.centerYAnchor.constraint(equalTo: centerYAnchor),
                ico.widthAnchor.constraint(equalToConstant: 18),
                ico.heightAnchor.constraint(equalToConstant: 18)
            ])
        }
        lbl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: height),
            lbl.centerYAnchor.constraint(equalTo: centerYAnchor),
            lbl.centerXAnchor.constraint(equalTo: centerXAnchor, constant: symbol == nil ? 0 : 12)
        ])
        if let i = ico.superview {
            NSLayoutConstraint.activate([ico.trailingAnchor.constraint(equalTo: lbl.leadingAnchor, constant: -8)])
            _ = i
        }
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        grad.frame = bounds
    }
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.14, delay: 0, options: [.allowUserInteraction]) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.97, y: 0.97) : .identity
                self.alpha = self.isHighlighted ? 0.92 : 1
            }
        }
    }
    override var isEnabled: Bool { didSet { alpha = isEnabled ? 1 : 0.38 } }
    func setTitle(_ t: String) { lbl.text = t }
}

// MARK: - 进度环

final class RingView: UIView {
    private let track = CAShapeLayer()
    private let arc = CAShapeLayer()
    private let grad = CAGradientLayer()
    private let big = UILabel()
    private let small = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        for l in [track, arc] {
            l.fillColor = UIColor.clear.cgColor
            l.lineWidth = 12
            l.lineCap = .round
            layer.addSublayer(l)
        }
        track.strokeColor = UIColor(white: 0.90, alpha: 1).cgColor
        arc.strokeColor = DS.accent.cgColor
        arc.strokeEnd = 0
        grad.colors = [DS.accent.withAlphaComponent(0.45).cgColor,
                       DS.accent.cgColor,
                       UIColor(red: 0.30, green: 0.66, blue: 0.58, alpha: 1).cgColor]
        grad.startPoint = CGPoint(x: 0, y: 0)
        grad.endPoint = CGPoint(x: 1, y: 1)
        layer.addSublayer(grad)

        big.font = DS.mono(30)
        big.textColor = DS.label
        big.textAlignment = .center
        big.text = "—"
        addSubview(big)
        small.font = DS.cap(11)
        small.textColor = DS.label3
        small.textAlignment = .center
        small.text = "剩余"
        addSubview(small)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        let r = min(bounds.width, bounds.height) / 2 - 8
        let c = CGPoint(x: bounds.midX, y: bounds.midY)
        let p = UIBezierPath(arcCenter: c, radius: r, startAngle: -.pi / 2, endAngle: .pi * 1.5, clockwise: true)
        track.path = p.cgPath
        arc.path = p.cgPath
        arc.frame = bounds
        grad.frame = bounds
        grad.mask = arc
        big.frame = CGRect(x: 0, y: bounds.midY - 26, width: bounds.width, height: 34)
        small.frame = CGRect(x: 0, y: bounds.midY + 6, width: bounds.width, height: 16)
    }

    func set(ratio: CGFloat, text: String, sub: String) {
        let r = max(0, min(1, ratio))
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.5)
        arc.strokeEnd = r
        CATransaction.commit()
        big.text = text
        big.textColor = r <= 0.001 ? DS.danger : DS.label
        small.text = sub
    }
}

// MARK: - 统计块

final class StatTile: UIView {
    private let v = UILabel()
    private let k = UILabel()
    init(key: String, symbol: String) {
        super.init(frame: .zero)
        backgroundColor = UIColor(white: 1, alpha: 0.72)
        layer.cornerRadius = DS.rSmall
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = UIColor(white: 0.95, alpha: 1).cgColor

        let ic = UIImageView(image: UIImage(systemName: symbol,
                                           withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)))
        ic.tintColor = DS.accent
        ic.contentMode = .scaleAspectFit

        v.font = DS.mono(20)
        v.textColor = DS.label
        v.text = "0"
        v.textAlignment = .center
        k.font = DS.cap(11)
        k.textColor = DS.label3
        k.text = key
        k.textAlignment = .center

        let s = UIStackView(arrangedSubviews: [ic, v, k])
        s.axis = .vertical
        s.spacing = 3
        s.alignment = .center
        addSubview(s)
        s.translatesAutoresizingMaskIntoConstraints = false
        ic.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            s.centerXAnchor.constraint(equalTo: centerXAnchor),
            s.centerYAnchor.constraint(equalTo: centerYAnchor),
            ic.heightAnchor.constraint(equalToConstant: 14),
            heightAnchor.constraint(equalToConstant: 84)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
    func set(_ n: Int) { v.text = n > 9999 ? "\(n / 1000)k" : "\(n)" }
}

// MARK: - 玻璃 TabBar

final class GlassTabBar: UIView {
    private let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterialLight))
    private let hline = UIView()
    var onSelect: ((Int) -> Void)?
    private var items: [UIControl] = []
    private var indicator = UIView()
    private(set) var current = 0

    init(titles: [String], symbols: [String]) {
        super.init(frame: .zero)
        backgroundColor = UIColor(white: 1, alpha: 0.62)
        addSubview(blur)
        hline.backgroundColor = UIColor(white: 0, alpha: 0.06)
        addSubview(hline)

        indicator.backgroundColor = DS.accent.withAlphaComponent(0.10)
        indicator.layer.cornerRadius = 16
        indicator.layer.cornerCurve = .continuous
        addSubview(indicator)

        let row = UIStackView()
        row.axis = .horizontal
        row.distribution = .fillEqually
        addSubview(row)

        for (i, t) in titles.enumerated() {
            let item = UIControl()
            item.tag = i
            item.addTarget(self, action: #selector(tapItem(_:)), for: .touchUpInside)

            let iv = UIImageView(image: UIImage(systemName: symbols[min(i, symbols.count - 1)],
                                               withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)))
            iv.contentMode = .scaleAspectFit
            iv.tintColor = DS.label3

            let lb = UILabel()
            lb.text = t
            lb.font = .systemFont(ofSize: 10, weight: .semibold)
            lb.textColor = DS.label3
            lb.textAlignment = .center

            let col = UIStackView(arrangedSubviews: [iv, lb])
            col.axis = .vertical
            col.spacing = 4
            col.alignment = .center
            col.isUserInteractionEnabled = false
            item.addSubview(col)
            col.translatesAutoresizingMaskIntoConstraints = false
            iv.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                col.centerXAnchor.constraint(equalTo: item.centerXAnchor),
                col.centerYAnchor.constraint(equalTo: item.centerYAnchor),
                iv.widthAnchor.constraint(equalToConstant: 20),
                iv.heightAnchor.constraint(equalToConstant: 20)
            ])
            items.append(item)
            row.addArrangedSubview(item)
        }

        blur.translatesAutoresizingMaskIntoConstraints = false
        hline.translatesAutoresizingMaskIntoConstraints = false
        row.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            blur.leadingAnchor.constraint(equalTo: leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: trailingAnchor),
            blur.topAnchor.constraint(equalTo: topAnchor),
            blur.bottomAnchor.constraint(equalTo: bottomAnchor),
            hline.leadingAnchor.constraint(equalTo: leadingAnchor),
            hline.trailingAnchor.constraint(equalTo: trailingAnchor),
            hline.topAnchor.constraint(equalTo: topAnchor),
            hline.heightAnchor.constraint(equalToConstant: 0.5),
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            row.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6)
        ])
        select(0, animated: false)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        blur.frame = bounds
        guard !items.isEmpty else { return }
        let w = bounds.width / CGFloat(items.count)
        let b = items[current]
        indicator.frame = CGRect(x: b.frame.midX - 26, y: 2, width: 52, height: bounds.height - 4)
    }

    @objc private func tapItem(_ s: UIControl) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        select(s.tag, animated: true)
        onSelect?(s.tag)
    }

    func select(_ i: Int, animated: Bool) {
        current = i
        for (idx, v) in items.enumerated() {
            let on = idx == i
            for sub in v.subviews {
                if let col = sub as? UIStackView {
                    for e in col.arrangedSubviews {
                        if let iv = e as? UIImageView { iv.tintColor = on ? DS.accent : DS.label3 }
                        if let lb = e as? UILabel { lb.textColor = on ? DS.accent : DS.label3 }
                    }
                }
            }
        }
        let apply = { self.setNeedsLayout(); self.layoutIfNeeded() }
        if animated { UIView.animate(withDuration: 0.28, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, animations: apply) }
        else { apply() }
    }
}

// MARK: - 分组标题

final class SectionHeader: UIView {
    init(_ title: String, subtitle: String? = nil) {
        super.init(frame: .zero)
        let t = UILabel()
        t.text = title
        t.font = DS.cap(12)
        t.textColor = DS.label3
        addSubview(t)
        t.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            t.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            t.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            t.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            heightAnchor.constraint(equalToConstant: 30)
        ])
        if let s = subtitle {
            let r = UILabel()
            r.text = s
            r.font = DS.cap(12)
            r.textColor = DS.label3
            r.textAlignment = .right
            addSubview(r)
            r.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                r.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
                r.centerYAnchor.constraint(equalTo: t.centerYAnchor)
            ])
        }
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - 提示（Toast）

enum HUD {
    static func toast(_ msg: String, ok: Bool = true) {
        DispatchQueue.main.async {
            guard let win = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) ?? UIApplication.shared.windows.first else { return }
            let box = UIView()
            box.backgroundColor = UIColor(white: 0.09, alpha: 0.92)
            box.layer.cornerRadius = 16
            box.layer.cornerCurve = .continuous
            box.alpha = 0

            let dot = UIView()
            dot.backgroundColor = ok ? DS.ok : UIColor(red: 0.98, green: 0.45, blue: 0.45, alpha: 1)
            dot.layer.cornerRadius = 4

            let l = UILabel()
            l.text = msg
            l.textColor = .white
            l.font = .systemFont(ofSize: 14, weight: .medium)
            l.numberOfLines = 2

            box.addSubview(dot); box.addSubview(l)
            win.addSubview(box)
            box.translatesAutoresizingMaskIntoConstraints = false
            dot.translatesAutoresizingMaskIntoConstraints = false
            l.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                box.centerXAnchor.constraint(equalTo: win.centerXAnchor),
                box.bottomAnchor.constraint(equalTo: win.safeAreaLayoutGuide.bottomAnchor, constant: -104),
                box.widthAnchor.constraint(lessThanOrEqualTo: win.widthAnchor, constant: -56),
                dot.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 14),
                dot.centerYAnchor.constraint(equalTo: box.centerYAnchor),
                dot.widthAnchor.constraint(equalToConstant: 8),
                dot.heightAnchor.constraint(equalToConstant: 8),
                l.leadingAnchor.constraint(equalTo: dot.trailingAnchor, constant: 10),
                l.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -16),
                l.topAnchor.constraint(equalTo: box.topAnchor, constant: 12),
                l.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -12)
            ])
            UIView.animate(withDuration: 0.2) { box.alpha = 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
                UIView.animate(withDuration: 0.25) { box.alpha = 0 } completion: { _ in box.removeFromSuperview() }
            }
        }
    }
}

// MARK: - 工具

enum Fmt {
    static func date(_ ms: Int64) -> String {
        guard ms > 0 else { return "—" }
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f.string(from: Date(timeIntervalSince1970: Double(ms) / 1000))
    }
    static func left(_ leftMs: Int64) -> String {
        let sec = Int(max(0, leftMs) / 1000)
        let d = sec / 86400
        if d > 0 { return "\(d)" }
        let h = sec / 3600
        if h > 0 { return "\(h)" }
        return "\(sec / 60)"
    }
    static func leftUnit(_ leftMs: Int64) -> String {
        let sec = Int(max(0, leftMs) / 1000)
        if sec / 86400 > 0 { return "天" }
        if sec / 3600 > 0 { return "时" }
        return "分"
    }
}

// MARK: - 规则统计

enum RuleStats {
    struct R { var ip = 0; var port = 0; var dom = 0; var kw = 0 }

    static func parse(_ text: String) -> R {
        var r = R()
        var sec = ""
        // 去掉可能存在的 BOM，并统一换行
        var t = text
        if t.hasPrefix("\u{FEFF}") { t = String(t.dropFirst()) }
        t = t.replacingOccurrences(of: "\r\n", with: "\n")
        t = t.replacingOccurrences(of: "\r", with: "\n")

        for raw in t.components(separatedBy: "\n") {
            let l = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if l.isEmpty { continue }
            if l.hasPrefix("#") {
                sec = String(l.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                continue
            }
            switch sec {
            case "V4", "V6":
                r.ip += 1
            case "PORTS":
                r.port += l.split(separator: ",").filter { !$0.isEmpty }.count
            case "DOMAINS":
                r.dom += 1
            case "KW":
                r.kw += 1
            default:
                break
            }
        }
        return r
    }
}
}
