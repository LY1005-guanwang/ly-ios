//
//  Widgets.swift — 增强组件：进度环 / 渐变按钮 / 图标输入框 / 统计格 / Toast / 悬浮状态条
//  与 App.swift 中的 GlassCard / LyButton 并存（类型名不冲突）
//

import UIKit

// MARK: - 主题补充

enum LyTheme {
    static let ink    = UIColor(red: 0.078, green: 0.086, blue: 0.098, alpha: 1)
    static let ink2   = UIColor(red: 0.361, green: 0.386, blue: 0.416, alpha: 1)
    static let ink3   = UIColor(red: 0.596, green: 0.620, blue: 0.651, alpha: 1)
    static let teal   = UIColor(red: 0.165, green: 0.435, blue: 0.400, alpha: 1)
    static let tealSoft = UIColor(red: 0.847, green: 0.918, blue: 0.906, alpha: 1)
    static let danger = UIColor(red: 0.729, green: 0.235, blue: 0.235, alpha: 1)
}

// MARK: - 剩余时间进度环

final class RingView: UIView {
    private let track = CAShapeLayer()
    private let prog = CAShapeLayer()
    private let grad = CAGradientLayer()
    private let center = UILabel()
    private let caption = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear

        track.fillColor = UIColor.clear.cgColor
        track.strokeColor = UIColor(white: 0.905, alpha: 1).cgColor
        track.lineWidth = 11
        track.lineCap = .round
        layer.addSublayer(track)

        prog.fillColor = UIColor.clear.cgColor
        prog.strokeColor = LyTheme.teal.cgColor
        prog.lineWidth = 11
        prog.lineCap = .round
        prog.strokeEnd = 0
        layer.addSublayer(prog)

        grad.colors = [LyTheme.teal.withAlphaComponent(0.45).cgColor,
                       LyTheme.teal.cgColor,
                       UIColor(red: 0.32, green: 0.64, blue: 0.57, alpha: 1).cgColor]
        grad.startPoint = CGPoint(x: 0, y: 0)
        grad.endPoint = CGPoint(x: 1, y: 1)
        layer.addSublayer(grad)

        center.font = .monospacedDigitSystemFont(ofSize: 26, weight: .semibold)
        center.textColor = LyTheme.ink
        center.textAlignment = .center
        center.text = "—"
        addSubview(center)

        caption.font = .systemFont(ofSize: 11, weight: .medium)
        caption.textColor = LyTheme.ink3
        caption.textAlignment = .center
        caption.text = "剩余"
        addSubview(caption)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        let r = min(bounds.width, bounds.height) / 2 - 8
        let c = CGPoint(x: bounds.midX, y: bounds.midY)
        let p = UIBezierPath(arcCenter: c, radius: r,
                             startAngle: -.pi / 2, endAngle: .pi * 1.5, clockwise: true)
        track.path = p.cgPath
        prog.path = p.cgPath
        prog.frame = bounds
        grad.frame = bounds
        grad.mask = prog
        center.frame = CGRect(x: 0, y: bounds.midY - 24, width: bounds.width, height: 30)
        caption.frame = CGRect(x: 0, y: bounds.midY + 6, width: bounds.width, height: 16)
    }

    func set(ratio: CGFloat, text: String, sub: String) {
        let r = max(0, min(1, ratio))
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.45)
        prog.strokeEnd = r
        CATransaction.commit()
        center.text = text
        center.textColor = r <= 0.001 ? LyTheme.danger : LyTheme.ink
        caption.text = sub
    }
}

// MARK: - 图标输入框

final class IconField: UIView, UITextFieldDelegate {
    let field = UITextField()
    private let icon = UIImageView()

    init(symbol: String, placeholder: String, secure: Bool = false) {
        super.init(frame: .zero)
        backgroundColor = UIColor(white: 1, alpha: 0.86)
        layer.cornerRadius = 16
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = UIColor(white: 0.92, alpha: 1).cgColor

        icon.image = UIImage(systemName: symbol)
        icon.tintColor = LyTheme.ink3
        icon.contentMode = .scaleAspectFit
        addSubview(icon)

        field.font = .systemFont(ofSize: 16)
        field.textColor = LyTheme.ink
        field.placeholder = placeholder
        field.isSecureTextEntry = secure
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.delegate = self
        addSubview(field)

        icon.translatesAutoresizingMaskIntoConstraints = false
        field.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 54),
            icon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            icon.centerYAnchor.constraint(equalTo: centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 19),
            icon.heightAnchor.constraint(equalToConstant: 19),
            field.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 12),
            field.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            field.centerYAnchor.constraint(equalTo: centerYAnchor),
            field.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func textFieldDidBeginEditing(_ t: UITextField) {
        layer.borderColor = LyTheme.teal.withAlphaComponent(0.55).cgColor
        backgroundColor = .white
    }
    func textFieldDidEndEditing(_ t: UITextField) {
        layer.borderColor = UIColor(white: 0.92, alpha: 1).cgColor
        backgroundColor = UIColor(white: 1, alpha: 0.86)
    }
}

// MARK: - 渐变按钮

final class GradButton: UIControl {
    private let grad = CAGradientLayer()
    private let label = UILabel()
    private var ghost = false

    init(title: String, ghost: Bool = false) {
        super.init(frame: .zero)
        self.ghost = ghost
        layer.cornerRadius = 17
        layer.cornerCurve = .continuous

        if ghost {
            backgroundColor = UIColor(white: 1, alpha: 0.9)
            layer.borderWidth = 1
            layer.borderColor = UIColor(white: 0.90, alpha: 1).cgColor
        } else {
            grad.colors = [UIColor(red: 0.20, green: 0.49, blue: 0.44, alpha: 1).cgColor,
                           UIColor(red: 0.13, green: 0.38, blue: 0.35, alpha: 1).cgColor]
            grad.startPoint = CGPoint(x: 0, y: 0)
            grad.endPoint = CGPoint(x: 1, y: 1)
            grad.cornerRadius = 17
            layer.insertSublayer(grad, at: 0)
            layer.shadowColor = LyTheme.teal.withAlphaComponent(0.35).cgColor
            layer.shadowOpacity = 1
            layer.shadowRadius = 12
            layer.shadowOffset = CGSize(width: 0, height: 5)
        }

        label.text = title
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = ghost ? LyTheme.teal : .white
        label.textAlignment = .center
        label.isUserInteractionEnabled = false
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 54),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        grad.frame = bounds
    }
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.12) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.975, y: 0.975) : .identity
                self.alpha = self.isHighlighted ? 0.92 : 1
            }
        }
    }
    override var isEnabled: Bool { didSet { alpha = isEnabled ? 1 : 0.4 } }
}

// MARK: - 统计格子

final class StatCell: UIView {
    private let v = UILabel()
    private let k = UILabel()
    init(key: String) {
        super.init(frame: .zero)
        backgroundColor = UIColor(white: 1, alpha: 0.72)
        layer.cornerRadius = 14
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = UIColor(white: 0.95, alpha: 1).cgColor

        v.font = .monospacedDigitSystemFont(ofSize: 16, weight: .semibold)
        v.textColor = LyTheme.ink
        v.text = "0"
        v.textAlignment = .center
        k.font = .systemFont(ofSize: 11)
        k.textColor = LyTheme.ink3
        k.text = key
        k.textAlignment = .center

        let s = UIStackView(arrangedSubviews: [v, k])
        s.axis = .vertical
        s.spacing = 1
        addSubview(s)
        s.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            s.centerXAnchor.constraint(equalTo: centerXAnchor),
            s.centerYAnchor.constraint(equalTo: centerYAnchor),
            heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
    func set(_ n: Int) { v.text = n > 9999 ? "\(n / 1000)k" : "\(n)" }
}

// MARK: - Toast

enum Toast {
    static func show(_ msg: String, ok: Bool = true) {
        DispatchQueue.main.async {
            guard let win = UIApplication.shared.windows.first else { return }
            let box = UIView()
            box.backgroundColor = UIColor(white: 0.10, alpha: 0.93)
            box.layer.cornerRadius = 16
            box.layer.cornerCurve = .continuous
            box.alpha = 0

            let dot = UIView()
            dot.backgroundColor = ok ? UIColor(red: 0.36, green: 0.85, blue: 0.66, alpha: 1)
                                     : UIColor(red: 0.98, green: 0.52, blue: 0.52, alpha: 1)
            dot.layer.cornerRadius = 4

            let l = UILabel()
            l.text = msg
            l.textColor = .white
            l.font = .systemFont(ofSize: 14)
            l.numberOfLines = 2

            box.addSubview(dot); box.addSubview(l)
            win.addSubview(box)
            box.translatesAutoresizingMaskIntoConstraints = false
            dot.translatesAutoresizingMaskIntoConstraints = false
            l.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                box.centerXAnchor.constraint(equalTo: win.centerXAnchor),
                box.bottomAnchor.constraint(equalTo: win.safeAreaLayoutGuide.bottomAnchor, constant: -88),
                box.widthAnchor.constraint(lessThanOrEqualTo: win.widthAnchor, constant: -48),
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                UIView.animate(withDuration: 0.25) { box.alpha = 0 } completion: { _ in box.removeFromSuperview() }
            }
        }
    }
}

// MARK: - 底部悬浮状态条（可拖动 / 可点击回到顶部）

final class FloatingPill: UIView {
    private let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterialLight))
    private let dot = UIView()
    private let title = UILabel()
    private let sub = UILabel()
    private let chevron = UIImageView()
    var onTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 27
        layer.cornerCurve = .continuous
        layer.shadowColor = UIColor(red: 0.35, green: 0.40, blue: 0.46, alpha: 0.26).cgColor
        layer.shadowOpacity = 1
        layer.shadowRadius = 20
        layer.shadowOffset = CGSize(width: 0, height: 8)
        layer.borderWidth = 1
        layer.borderColor = UIColor(white: 1, alpha: 0.9).cgColor

        blur.layer.cornerRadius = 27
        blur.layer.cornerCurve = .continuous
        blur.clipsToBounds = true
        addSubview(blur)

        dot.layer.cornerRadius = 5
        dot.backgroundColor = LyTheme.ink3
        addSubview(dot)

        title.font = .systemFont(ofSize: 14, weight: .semibold)
        title.textColor = LyTheme.ink
        title.text = "LY 运行状态"
        addSubview(title)

        sub.font = .systemFont(ofSize: 11)
        sub.textColor = LyTheme.ink3
        sub.text = "未运行"
        addSubview(sub)

        chevron.image = UIImage(systemName: "chevron.up")
        chevron.tintColor = LyTheme.ink3
        chevron.contentMode = .scaleAspectFit
        addSubview(chevron)

        let all = [blur, dot, title, sub, chevron]
        all.forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            blur.leadingAnchor.constraint(equalTo: leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: trailingAnchor),
            blur.topAnchor.constraint(equalTo: topAnchor),
            blur.bottomAnchor.constraint(equalTo: bottomAnchor),

            dot.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            dot.centerYAnchor.constraint(equalTo: centerYAnchor),
            dot.widthAnchor.constraint(equalToConstant: 10),
            dot.heightAnchor.constraint(equalToConstant: 10),

            title.leadingAnchor.constraint(equalTo: dot.trailingAnchor, constant: 10),
            title.topAnchor.constraint(equalTo: topAnchor, constant: 9),

            sub.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            sub.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 1),
            sub.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -9),

            chevron.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            chevron.centerYAnchor.constraint(equalTo: centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 13),
            chevron.heightAnchor.constraint(equalToConstant: 13)
        ])

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tap)))
        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(pan(_:))))
    }
    required init?(coder: NSCoder) { fatalError() }

    func update(on: Bool, days: Int64, expired: Bool) {
        if expired {
            dot.backgroundColor = LyTheme.danger
            sub.text = "已到期 · 拦截关闭"
        } else if on {
            dot.backgroundColor = UIColor(red: 0.24, green: 0.78, blue: 0.58, alpha: 1)
            sub.text = "拦截运行中 · 剩余 \(days) 天"
        } else {
            dot.backgroundColor = LyTheme.ink3
            sub.text = "待启动 · 剩余 \(days) 天"
        }
        pulse(on && !expired)
    }

    private func pulse(_ b: Bool) {
        dot.layer.removeAllAnimations()
        guard b else { dot.transform = .identity; dot.alpha = 1; return }
        UIView.animate(withDuration: 1.1, delay: 0,
                       options: [.repeat, .autoreverse, .allowUserInteraction]) {
            self.dot.transform = CGAffineTransform(scaleX: 1.35, y: 1.35)
            self.dot.alpha = 0.6
        }
    }

    @objc private func tap() { onTap?() }

    @objc private func pan(_ g: UIPanGestureRecognizer) {
        guard let sv = superview else { return }
        let t = g.translation(in: sv)
        center = CGPoint(x: center.x + t.x, y: center.y + t.y)
        g.setTranslation(.zero, in: sv)
        if g.state == .ended {
            let bottom = sv.bounds.height - sv.safeAreaInsets.bottom - 64
            let x = min(max(center.x, 84), sv.bounds.width - 84)
            UIView.animate(withDuration: 0.32, delay: 0, usingSpringWithDamping: 0.75,
                           initialSpringVelocity: 0.4) {
                self.center = CGPoint(x: x, y: min(max(self.center.y, 100), bottom))
            }
        }
    }
}

// MARK: - 规则统计

enum RuleStats {
    struct R { var v4 = 0; var ports = 0; var domains = 0; var kw = 0 }
    static func parse(_ t: String) -> R {
        var r = R(); var sec = ""
        for raw in t.components(separatedBy: "\n") {
            let l = raw.trimmingCharacters(in: .whitespaces)
            if l.isEmpty { continue }
            if l.hasPrefix("#") { sec = String(l.dropFirst()).uppercased(); continue }
            switch sec {
            case "V4", "V6": r.v4 += 1
            case "PORTS": r.ports += l.split(separator: ",").count
            case "DOMAINS": r.domains += 1
            case "KW": r.kw += 1
            default: break
            }
        }
        return r
    }
}

enum LyFmt2 {
    static func date(_ ms: Int64) -> String {
        guard ms > 0 else { return "—" }
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f.string(from: Date(timeIntervalSince1970: Double(ms) / 1000))
    }
    static func bigDays(_ leftMs: Int64) -> String {
        let sec = Int(max(0, leftMs) / 1000)
        let d = sec / 86400
        if d > 0 { return "\(d)天" }
        let h = sec / 3600
        if h > 0 { return "\(h)时" }
        return "\(sec / 60)分"
    }
}
