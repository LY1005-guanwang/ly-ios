//
//  App.swift 閳?LY閸愬懘鍎?iOS 璺?閸忋劍鏌婇妴灞炬伀閹胶骞撻悹?璺?閻у€熷鐠嬪啨鈧硨I
//  iOS 14+ / UIKit 缁绢垯鍞惍?/ 閺?Storyboard
//

import UIKit

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ app: UIApplication,
                     didFinishLaunchingWithOptions opt: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        w.rootViewController = LyHomeViewController()
        w.makeKeyAndVisible()
        window = w
        return true
    }
}

// MARK: - 閻滆崵鎷戦崡锛勫

final class GlassCard: UIView {
    private let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialLight))
    private let border = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(white: 1, alpha: 0.55)
        layer.cornerRadius = 22
        layer.cornerCurve = .continuous
        layer.masksToBounds = false
        layer.shadowColor = UIColor(white: 0.55, alpha: 0.18).cgColor
        layer.shadowOpacity = 1
        layer.shadowRadius = 18
        layer.shadowOffset = CGSize(width: 0, height: 8)

        blur.layer.cornerRadius = 22
        blur.layer.cornerCurve = .continuous
        blur.clipsToBounds = true
        addSubview(blur)

        border.colors = [UIColor(white: 1, alpha: 0.95).cgColor,
                         UIColor(white: 1, alpha: 0.25).cgColor]
        border.startPoint = CGPoint(x: 0, y: 0)
        border.endPoint = CGPoint(x: 1, y: 1)
        border.cornerRadius = 22
        layer.addSublayer(border)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        blur.frame = bounds
        border.frame = bounds
        border.borderWidth = 1
        let mask = CAShapeLayer()
        mask.path = UIBezierPath(roundedRect: bounds, cornerRadius: 22).cgPath
        border.mask = mask
    }
}

// MARK: - 娑撹崵鏅棃?
final class LyHomeViewController: UIViewController, UIScrollViewDelegate {

    // 娑撳顣介懝璇х礄閻у€熺殶 + 婢с劎璞㈤悙鍦磻閿?    private let ink    = UIColor(red: 0.09, green: 0.10, blue: 0.11, alpha: 1)
    private let teal   = UIColor(red: 0.18, green: 0.44, blue: 0.40, alpha: 1)
    private let danger = UIColor(red: 0.72, green: 0.24, blue: 0.24, alpha: 1)

    private let scroll = UIScrollView()
    private let stack  = UIStackView()

    private let hero   = GlassCard()
    private let heroImg = UIImageView()
    private let titleLB = UILabel()
    private let subLB   = UILabel()

    private let statusCard = GlassCard()
    private let ring = RingView()
    private var pill: FloatingPill!
    private let remainLB   = UILabel()
    private let detailLB   = UILabel()

    private let accountCard = GlassCard()
    private let userTF  = UITextField()
    private let passTF  = UITextField()
    private let cardTF  = UITextField()

    private let btnLogin  = LyButton(title: "閻ц缍?, style: .primary)
    private let btnReg    = LyButton(title: "濞夈劌鍞介敍鍫ユ付閸椻€崇槕閿?, style: .ghost)
    private let btnRenew  = LyButton(title: "閻劌宕辩€靛棛鐢婚張?, style: .primary)
    private let btnLogout = LyButton(title: "闁偓閸戣櫣娅ヨぐ?/ 閸掑洦宕茬拹锕€褰?, style: .ghost)

    private let ruleCard = GlassCard()
    private let ruleLB   = UILabel()
    private let btnRules = LyButton(title: "閹峰褰囨禍鎴狀伂鐟欏嫬鍨?, style: .ghost)

    private let btnVPN   = LyButton(title: "瀵偓閸氼垳缍夌紒婊勫閹?, style: .primary)
    private let tipLB    = UILabel()

    private var busy = false

    // MARK: 閻㈢喎鎳￠崨銊︽埂

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.975, alpha: 1)

        // 閼冲本娅欓崗澶嬫閿涘牊鎭幀浣哄箵閻犲啳宸濋幇鐕傜礆
        let g1 = CAGradientLayer()
        g1.colors = [UIColor(red: 0.86, green: 0.93, blue: 0.92, alpha: 1).cgColor,
                     UIColor(white: 1, alpha: 0).cgColor]
        g1.startPoint = CGPoint(x: 0.1, y: 0)
        g1.endPoint = CGPoint(x: 0.9, y: 0.45)
        g1.frame = CGRect(x: -80, y: -140, width: view.bounds.width + 160, height: 460)
        view.layer.addSublayer(g1)

        let g2 = CAGradientLayer()
        g2.colors = [UIColor(red: 0.93, green: 0.94, blue: 0.97, alpha: 1).cgColor,
                     UIColor(white: 1, alpha: 0).cgColor]
        g2.startPoint = CGPoint(x: 1, y: 1)
        g2.endPoint = CGPoint(x: 0.2, y: 0.4)
        g2.frame = CGRect(x: -60, y: view.bounds.height - 420, width: view.bounds.width + 120, height: 480)
        view.layer.addSublayer(g2)

        buildUI()
        refresh()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scroll.frame = view.bounds
        stack.frame = CGRect(x: 18, y: 0, width: view.bounds.width - 36,
                             height: stack.systemLayoutSizeFitting(
                                CGSize(width: view.bounds.width - 36, height: .greatestFiniteMagnitude)).height)
        scroll.contentSize = CGSize(width: view.bounds.width, height: stack.frame.height + 60)
    }

    // MARK: 閺嬪嫬缂?
    private func buildUI() {
        scroll.delegate = self
        scroll.alwaysBounceVertical = true
        scroll.showsVerticalScrollIndicator = false
        view.addSubview(scroll)

        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        scroll.addSubview(stack)

        // ---- Hero
        hero.translatesAutoresizingMaskIntoConstraints = false
        hero.heightAnchor.constraint(equalToConstant: 210).isActive = true
        stack.addArrangedSubview(hero)

        heroImg.image = UIImage(named: "hero") ?? UIImage(systemName: "shield.lefthalf.filled")
        heroImg.contentMode = .scaleAspectFill
        heroImg.clipsToBounds = true
        heroImg.layer.cornerRadius = 22
        heroImg.layer.cornerCurve = .continuous
        heroImg.alpha = 0.92
        hero.addSubview(heroImg)

        titleLB.text = "LY 閸愬懘鍎?
        titleLB.font = .systemFont(ofSize: 34, weight: .semibold)
        titleLB.textColor = ink
        titleLB.textAlignment = .center
        hero.addSubview(titleLB)

        subLB.text = "缂?缂?鐏?璺?闂?姒?閹?閹?
        subLB.font = .systemFont(ofSize: 13, weight: .regular)
        subLB.textColor = UIColor(white: 0.45, alpha: 1)
        subLB.textAlignment = .center
        hero.addSubview(subLB)

        // ---- 閻樿埖鈧?        stack.addArrangedSubview(statusCard)
        statusCard.translatesAutoresizingMaskIntoConstraints = false
        statusCard.heightAnchor.constraint(equalToConstant: 124).isActive = true
        remainLB.font = .systemFont(ofSize: 26, weight: .semibold)
        remainLB.textColor = teal
        detailLB.font = .systemFont(ofSize: 13)
        detailLB.textColor = UIColor(white: 0.45, alpha: 1)
        let sStack = UIStackView(arrangedSubviews: [remainLB, detailLB])
        sStack.axis = .vertical
        sStack.spacing = 6
        statusCard.addSubview(sStack)

        // 鏉╂稑瀹抽悳顖ょ礄閸欏厖鏅堕敍?        statusCard.addSubview(ring)
        ring.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            ring.trailingAnchor.constraint(equalTo: statusCard.trailingAnchor, constant: -16),
            ring.centerYAnchor.constraint(equalTo: statusCard.centerYAnchor),
            ring.widthAnchor.constraint(equalToConstant: 92),
            ring.heightAnchor.constraint(equalToConstant: 92)
        ])
        // 閺傚洦婀伴崠鍝勫礁娓氀呮殌閸戣櫣鈹栭梻?        sStack.trailingAnchor.constraint(lessThanOrEqualTo: ring.leadingAnchor, constant: -12).isActive = true

        // ---- 鐠愶箑褰?        stack.addArrangedSubview(accountCard)
        userTF.placeholder = "鐠愶箑褰?
        passTF.placeholder = "鐎靛棛鐖?
        passTF.isSecureTextEntry = true
        cardTF.placeholder = "閸椻€崇槕閿涘牊鏁為崘?/ 缂侇厽婀￠悽顭掔礆"
        cardTF.autocapitalizationType = .none
        [userTF, passTF, cardTF].forEach {
            $0.font = .systemFont(ofSize: 16)
            $0.textColor = ink
            $0.borderStyle = .none
            $0.backgroundColor = UIColor(white: 1, alpha: 0.75)
            $0.layer.cornerRadius = 14
            $0.layer.cornerCurve = .continuous
            $0.setLeftPadding(14)
            $0.heightAnchor.constraint(equalToConstant: 50).isActive = true
        }
        let accStack = UIStackView(arrangedSubviews: [userTF, passTF, cardTF, btnLogin, btnReg, btnRenew, btnLogout])
        accStack.axis = .vertical
        accStack.spacing = 10
        accountCard.addSubview(accStack)

        btnLogin.addTarget(self, action: #selector(onLogin), for: .touchUpInside)
        btnReg.addTarget(self, action: #selector(onRegister), for: .touchUpInside)
        btnRenew.addTarget(self, action: #selector(onRenew), for: .touchUpInside)
        btnLogout.addTarget(self, action: #selector(onLogout), for: .touchUpInside)

        // ---- 鐟欏嫬鍨?        stack.addArrangedSubview(ruleCard)
        ruleLB.numberOfLines = 0
        ruleLB.font = .systemFont(ofSize: 13)
        ruleLB.textColor = UIColor(white: 0.32, alpha: 1)
        ruleLB.text = "鐟欏嫬鍨悩鑸碘偓涔梟鐏忔碍婀崥灞绢劄"
        let rStack = UIStackView(arrangedSubviews: [ruleLB, btnRules])
        rStack.axis = .vertical
        rStack.spacing = 12
        ruleCard.addSubview(rStack)
        btnRules.addTarget(self, action: #selector(onRules), for: .touchUpInside)

        // ---- 閹凤附鍩?        stack.addArrangedSubview(btnVPN)
        btnVPN.addTarget(self, action: #selector(onVPN), for: .touchUpInside)

        tipLB.font = .systemFont(ofSize: 12)
        tipLB.textColor = UIColor(white: 0.55, alpha: 1)
        tipLB.numberOfLines = 0
        stack.addArrangedSubview(tipLB)

        // ---- 閹剚璇為悩鑸碘偓浣规蒋
        pill = FloatingPill()
        view.addSubview(pill)
        pill.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pill.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pill.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            pill.widthAnchor.constraint(equalToConstant: 212),
            pill.heightAnchor.constraint(equalToConstant: 56)
        ])
        pill.onTap = { [weak self] in
            self?.scroll.setContentOffset(.zero, animated: true)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }


        // 缂佺喍绔撮崘鍛扮珶鐠?        [ (hero, heroImg, 0), (statusCard, sStack, 20), (accountCard, accStack, 18), (ruleCard, rStack, 18) ]
            .forEach { _, sub, pad in
                sub.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    sub.leadingAnchor.constraint(equalTo: sub.superview!.leadingAnchor, constant: pad),
                    sub.trailingAnchor.constraint(equalTo: sub.superview!.trailingAnchor, constant: -pad),
                    sub.topAnchor.constraint(equalTo: sub.superview!.topAnchor, constant: pad == 0 ? 0 : pad),
                    sub.bottomAnchor.constraint(equalTo: sub.superview!.bottomAnchor, constant: -pad)
                ])
            }
        heroImg.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            heroImg.leadingAnchor.constraint(equalTo: hero.leadingAnchor),
            heroImg.trailingAnchor.constraint(equalTo: hero.trailingAnchor),
            heroImg.topAnchor.constraint(equalTo: hero.topAnchor),
            heroImg.bottomAnchor.constraint(equalTo: hero.bottomAnchor)
        ])
        titleLB.translatesAutoresizingMaskIntoConstraints = false
        subLB.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLB.centerXAnchor.constraint(equalTo: hero.centerXAnchor),
            titleLB.centerYAnchor.constraint(equalTo: hero.centerYAnchor, constant: -6),
            subLB.centerXAnchor.constraint(equalTo: hero.centerXAnchor),
            subLB.topAnchor.constraint(equalTo: titleLB.bottomAnchor, constant: 8)
        ])
    }

    // MARK: 閸掗攱鏌?
    private func refresh() {
        let logged = Session.logged
        let exp = Session.expireAt
        let expired = exp > 0 && Date().timeIntervalSince1970 * 1000 > Double(exp)

        if logged {
            if expired {
                remainLB.text = "瀹告彃鍩岄張?
                remainLB.textColor = danger
            } else {
                remainLB.text = "閸撯晙缍?" + LyFmt.left(exp)
                remainLB.textColor = teal
            }
            detailLB.text = "鐠愶箑褰?" + Session.user + " 璺?閸掔増婀?" + LyFmt.date(exp)
        } else {
            remainLB.text = "閺堫亞娅ヨぐ?
            remainLB.textColor = UIColor(white: 0.5, alpha: 1)
            detailLB.text = "濞夈劌鍞介棁鈧崡鈥崇槕 璺?閸椻€崇槕閻㈠彉缍旈懓鍛絺閺€?
        }

        userTF.isHidden = logged
        passTF.isHidden = logged
        cardTF.isHidden = false                      // 缂侇厽婀¤箛鍛淬€忛懗钘夛綖閸椻€崇槕
        btnLogin.isHidden = logged
        btnReg.isHidden = logged
        btnRenew.isHidden = !logged
        btnLogout.isHidden = !logged

        // 鏉╂稑瀹抽悳顖ょ礄閹?30 婢垛晙璐熷鈽呯礆
        let leftMs = max(0, exp - Int64(Date().timeIntervalSince1970 * 1000))
        ring.set(ratio: exp <= 0 ? 0 : CGFloat(min(1.0, Double(leftMs) / (30.0 * 86400000.0))),
                 text: LyFmt.bigDays(leftMs),
                 sub: exp <= 0 ? "閺堫亝绺哄ú? : "閸撯晙缍?)

        // 鎼存洟鍎撮幃顒佽癁閺?        if pill != nil {
            pill.update(on: Settings.vpnOn, days: leftMs / 86400000, expired: expired || !logged)
        }

        let canUse = logged && !expired
        btnVPN.setTitle(Settings.vpnOn ? "閸忔娊妫寸純鎴犵捕閹凤附鍩? : "瀵偓閸氼垳缍夌紒婊勫閹?, for: .normal)
        btnVPN.alpha = canUse ? 1 : 0.45
        btnVPN.isEnabled = canUse
        tipLB.text = canUse
            ? (Settings.vpnOn ? "閹凤附鍩呮潻鎰攽娑擃叏绱欑純鎴犵捕鐏炲偊绱濋棃娆撶帛閿? : "閻愮懓鍤鈧崥顖氭倵鐠囧嘲鍘戠拋鎼炩偓瀛稰N 闁板秶鐤嗛妴?)
            : "閸掔増婀?/ 閺堫亞娅ヨぐ?璺?娑撳秴褰插鈧崥?
    }

    // MARK: 閸斻劋缍?
    private func setBusy(_ b: Bool, _ msg: String = "") {
        busy = b
        [btnLogin, btnReg, btnRenew, btnLogout, btnRules, btnVPN].forEach { $0.isEnabled = !b }
        if !msg.isEmpty { tipLB.text = msg }
    }

    @objc private func onLogin() {
        guard !busy else { return }
        setBusy(true, "閻ц缍嶆稉顓涒偓?)
        AccountApi.login(user: userTF.text ?? "", pass: passTF.text ?? "") { r in
            self.setBusy(false)
            if r.ok {
                Session.save(token: r.token, expireAt: r.expireAt, user: r.user.isEmpty ? (self.userTF.text ?? "") : r.user)
                self.tipLB.text = "閻ц缍嶉幋鎰"
                self.refresh()
            } else {
                self.tipLB.text = "閻ц缍嶆径杈Е閿? + r.msg
            }
        }
    }

    @objc private func onRegister() {
        guard !busy else { return }
        let c = cardTF.text ?? ""
        if c.count < 6 { tipLB.text = "鐠囧嘲鍘涙繅顐㈠晸閸椻€崇槕"; return }
        setBusy(true, "濞夈劌鍞芥稉顓涒偓?)
        AccountApi.register(user: userTF.text ?? "", pass: passTF.text ?? "", card: c) { r in
            self.setBusy(false)
            if r.ok {
                Session.save(token: r.token, expireAt: r.expireAt, user: self.userTF.text ?? "")
                self.cardTF.text = ""
                self.tipLB.text = "濞夈劌鍞介幋鎰"
                self.refresh()
            } else {
                self.tipLB.text = "濞夈劌鍞芥径杈Е閿? + r.msg
            }
        }
    }

    @objc private func onRenew() {
        guard !busy else { return }
        let c = cardTF.text ?? ""
        if c.count < 6 { tipLB.text = "鐠囧嘲锝為崘娆忓幢鐎?; return }
        setBusy(true, "缂侇厽婀℃稉顓涒偓?)
        AccountApi.renew(card: c) { r in
            self.setBusy(false)
            if r.ok {
                Session.touch(expireAt: r.expireAt)      // 閸忔娊鏁敍姘倱濮濄儱鍩岄張鐔告闂?                self.cardTF.text = ""
                self.tipLB.text = "缂侇厽婀￠幋鎰 璺?閸掔増婀?" + LyFmt.date(r.expireAt)
                self.refresh()
            } else {
                self.tipLB.text = "缂侇厽婀℃径杈Е閿? + r.msg
            }
        }
    }

    @objc private func onLogout() {
        Session.clear()
        tipLB.text = "瀹告煡鈧偓閸?
        refresh()
    }

    @objc private func onRules() {
        guard !busy else { return }
        setBusy(true, "閹峰褰囩憴鍕灟閳?)
        CloudRules.fetch { ok, text, diag in
            self.setBusy(false)
            if ok {
                let lines = text.components(separatedBy: "\n")
                RuleStore.save(text)
                self.ruleLB.text = "瀹告彃鎮撳?璺?" + String(text.utf8.count) + " 鐎涙濡璡n"
                    + "鐟欏嫬鍨弬鍥ㄦ拱鐞涘本鏆熼敍? + String(lines.count) + "\n" + diag
                self.tipLB.text = "鐟欏嫬鍨鍙夋纯閺?
            } else {
                self.ruleLB.text = "閹峰褰囨径杈Е\n" + diag
            }
        }
    }

    @objc private func onVPN() {
        Settings.vpnOn.toggle()
        VPNController.apply(enabled: Settings.vpnOn) { err in
            if let e = err {
                Settings.vpnOn = false
                self.tipLB.text = "瀵偓閸氼垰銇戠拹銉窗" + e
            } else {
                self.tipLB.text = Settings.vpnOn ? "閹凤附鍩呭鎻掔磻閸? : "閹凤附鍩呭鎻掑彠闂?
            }
            self.refresh()
        }
    }
}

// MARK: - 閹稿鎸?
final class LyButton: UIButton {
    enum Style { case primary, ghost }
    init(title: String, style: Style) {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        layer.cornerRadius = 16
        layer.cornerCurve = .continuous
        heightAnchor.constraint(equalToConstant: 52).isActive = true
        switch style {
        case .primary:
            backgroundColor = UIColor(red: 0.18, green: 0.44, blue: 0.40, alpha: 1)
            setTitleColor(.white, for: .normal)
        case .ghost:
            backgroundColor = UIColor(white: 1, alpha: 0.8)
            setTitleColor(UIColor(red: 0.18, green: 0.44, blue: 0.40, alpha: 1), for: .normal)
            layer.borderWidth = 1
            layer.borderColor = UIColor(white: 0.88, alpha: 1).cgColor
        }
    }
    required init?(coder: NSCoder) { fatalError() }
    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.75 : 1 }
    }
}

// MARK: - 鐏忓繐浼愰崗?
extension UITextField {
    func setLeftPadding(_ w: CGFloat) {
        let v = UIView(frame: CGRect(x: 0, y: 0, width: w, height: 1))
        leftView = v; leftViewMode = .always
    }
}

enum LyFmt {
    static func date(_ ms: Int64) -> String {
        guard ms > 0 else { return "閳? }
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f.string(from: Date(timeIntervalSince1970: Double(ms) / 1000))
    }
    static func bigDays(_ leftMs: Int64) -> String {
        let sec = Int(max(0, leftMs) / 1000)
        let d = sec / 86400
        if d > 0 { return "\(d)婢? }
        let h = sec / 3600
        if h > 0 { return "\(h)閺? }
        return "\(sec / 60)閸?
    }

    static func left(_ ms: Int64) -> String {
        let sec = max(0, Int(Double(ms) / 1000 - Date().timeIntervalSince1970))
        let d = sec / 86400, h = (sec % 86400) / 3600
        if d > 0 { return "\(d) 婢?\(h) 鐏忓繑妞? }
        let m = (sec % 3600) / 60
        return "\(h) 鐏忓繑妞?\(m) 閸?
    }
}
