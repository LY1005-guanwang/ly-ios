//
//  App.swift — LY内部 iOS（重制：底部 Tab 四页面 / 大厂范式 / 液态玻璃）
//  Home · 账号 · 规则 · 设置
//

import UIKit

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ app: UIApplication,
                     didFinishLaunchingWithOptions opt: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let w = UIWindow(frame: UIScreen.main.bounds)
        w.rootViewController = RootTabs()
        w.makeKeyAndVisible()
        window = w
        return true
    }
}

// MARK: - 根容器（自定义玻璃 TabBar）

final class RootTabs: UIViewController {

    private let pages: [UIViewController] = [HomePage(), AccountPage(), RulesPage(), SettingsPage()]
    private let container = UIView()
    private let tabBar = GlassTabBar(titles: ["首页", "账号", "规则", "设置"],
                                     symbols: ["house.fill", "person.crop.circle", "shield.lefthalf.filled", "gearshape"])
    private var current: UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = DS.bg
        view.addSubview(container)
        view.addSubview(tabBar)
        tabBar.onSelect = { [weak self] i in self?.show(i) }
        show(0)
    }

    override var childForStatusBarStyle: UIViewController? { current }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let barH: CGFloat = 62
        let bottom = view.safeAreaInsets.bottom
        container.frame = view.bounds
        tabBar.frame = CGRect(x: 0, y: view.bounds.height - barH - bottom,
                              width: view.bounds.width, height: barH + bottom)
        current?.view.frame = container.bounds
    }

    private func show(_ i: Int) {
        guard i < pages.count else { return }
        current?.willMove(toParent: nil)
        current?.view.removeFromSuperview()
        current?.removeFromParent()

        let vc = pages[i]
        addChild(vc)
        vc.view.frame = container.bounds
        vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        vc.view.clipsToBounds = true
        container.insertSubview(vc.view, at: 0)
        vc.didMove(toParent: self)
        current = vc
        vc.view.alpha = 0
        UIView.animate(withDuration: 0.22) { vc.view.alpha = 1 }
        setNeedsStatusBarAppearanceUpdate()
    }
}

// MARK: - 页面基类（滚动 + 联动模糊 + 大标题）

class BasePage: UIViewController, UIScrollViewDelegate {

    let scroll = UIScrollView()
    let stack = UIStackView()
    private let topBlur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialLight))
    private let titleLB = UILabel()
    private let subLB = UILabel()
    private let hair = UIView()

    var pageTitle = ""
    var pageSubtitle = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = DS.bg
        addBackdrop()

        scroll.showsVerticalScrollIndicator = false
        scroll.alwaysBounceVertical = true
        scroll.delegate = self
        scroll.contentInsetAdjustmentBehavior = .never
        scroll.contentInset = UIEdgeInsets(top: 128, left: 0, bottom: 130, right: 0)
        view.addSubview(scroll)

        stack.axis = .vertical
        stack.spacing = DS.gap
        scroll.addSubview(stack)

        topBlur.alpha = 0
        view.addSubview(topBlur)

        titleLB.font = DS.h1(30)
        titleLB.textColor = DS.label
        view.addSubview(titleLB)

        subLB.font = DS.body(13)
        subLB.textColor = DS.label3
        view.addSubview(subLB)

        hair.backgroundColor = UIColor(white: 0, alpha: 0)
        view.addSubview(hair)
        titleLB.text = pageTitle
        subLB.text = pageSubtitle
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let top = view.safeAreaInsets.top
        scroll.frame = view.bounds
        let w = view.bounds.width - DS.pad * 2
        stack.layoutIfNeeded()
        let h = stack.systemLayoutSizeFitting(CGSize(width: w, height: UIView.layoutFittingCompressedSize.height)).height
        stack.frame = CGRect(x: DS.pad, y: 0, width: w, height: h)
        scroll.contentSize = CGSize(width: view.bounds.width, height: h + 160)

        titleLB.frame = CGRect(x: DS.pad, y: top + 10, width: w, height: 38)
        subLB.frame = CGRect(x: DS.pad, y: top + 48, width: w, height: 18)
        topBlur.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: top + 82)
        hair.frame = CGRect(x: 0, y: top + 81, width: view.bounds.width, height: 0.5)
    }

    private func addBackdrop() {
        let a = CAGradientLayer()
        a.colors = [UIColor(red: 0.79, green: 0.91, blue: 0.89, alpha: 1).cgColor,
                    UIColor(white: 1, alpha: 0).cgColor]
        a.startPoint = CGPoint(x: 0.05, y: 0)
        a.endPoint = CGPoint(x: 0.9, y: 0.55)
        a.frame = CGRect(x: -120, y: -200, width: view.bounds.width + 240, height: 560)
        view.layer.addSublayer(a)

        let b = CAGradientLayer()
        b.colors = [UIColor(red: 0.89, green: 0.90, blue: 0.97, alpha: 1).cgColor,
                    UIColor(white: 1, alpha: 0).cgColor]
        b.startPoint = CGPoint(x: 1, y: 1)
        b.endPoint = CGPoint(x: 0.1, y: 0.3)
        b.frame = CGRect(x: -100, y: UIScreen.main.bounds.height - 560, width: view.bounds.width + 200, height: 600)
        view.layer.addSublayer(b)
    }

    func scrollViewDidScroll(_ sv: UIScrollView) {
        let y = sv.contentOffset.y + sv.contentInset.top
        let p = max(0, min(1, (y - 40) / 60))
        topBlur.alpha = p
        hair.backgroundColor = UIColor(white: 0, alpha: 0.06 * p)
    }

    func add(_ v: UIView) { stack.addArrangedSubview(v) }
}

// MARK: - 首页

final class HomePage: BasePage {

    private let hero = GlassCard(radius: 30)
    private let status = GlassCard()
    private let ring = RingView()
    private let accLB = UILabel()
    private let expLB = UILabel()
    private let devPill = UILabel()
    private let quick = GlassCard()
    private let vpnSwitch = UISwitch()

    override func viewDidLoad() {
        pageTitle = "LY 内部"
        pageSubtitle = "网络层 · 静默拦截"
        super.viewDidLoad()
        buildHero()
        buildStatus()
        buildQuick()
        NotificationCenter.default.addObserver(self, selector: #selector(reload),
                                              name: UIApplication.willEnterForegroundNotification, object: nil)
        reload()
    }

    private func buildHero() {
        hero.heightAnchor.constraint(equalToConstant: 188).isActive = true
        add(hero)

        let t = UILabel()
        t.text = "静 默 拦 截"
        t.font = DS.h1(38)
        t.textColor = DS.label
        t.textAlignment = .center
        t.translatesAutoresizingMaskIntoConstraints = false
        hero.addSubview(t)

        let s = UILabel()
        s.text = "规则云端下发 · 全程加密 · 设备级校验"
        s.font = DS.body(12)
        s.textColor = DS.label2
        s.textAlignment = .center
        s.translatesAutoresizingMaskIntoConstraints = false
        hero.addSubview(s)

        let pill = UILabel()
        pill.text = "  v3.9 · iOS  "
        pill.font = DS.cap(11)
        pill.textColor = DS.accent
        pill.backgroundColor = DS.accentLo
        pill.layer.cornerRadius = 10
        pill.layer.masksToBounds = true
        pill.textAlignment = .center
        pill.translatesAutoresizingMaskIntoConstraints = false
        hero.addSubview(pill)

        NSLayoutConstraint.activate([
            t.centerXAnchor.constraint(equalTo: hero.centerXAnchor),
            t.centerYAnchor.constraint(equalTo: hero.centerYAnchor, constant: -16),
            s.centerXAnchor.constraint(equalTo: hero.centerXAnchor),
            s.topAnchor.constraint(equalTo: t.bottomAnchor, constant: 6),
            pill.centerXAnchor.constraint(equalTo: hero.centerXAnchor),
            pill.topAnchor.constraint(equalTo: s.bottomAnchor, constant: 12),
            pill.heightAnchor.constraint(equalToConstant: 22)
        ])
    }

    private func buildStatus() {
        add(status)

        accLB.font = DS.h2(18)
        accLB.textColor = DS.label
        accLB.text = "未登录"

        expLB.font = DS.body(12)
        expLB.textColor = DS.label3
        expLB.text = "注册需卡密"

        devPill.font = DS.cap(11)
        devPill.textColor = DS.label2
        devPill.backgroundColor = UIColor(white: 0.95, alpha: 1)
        devPill.textAlignment = .center
        devPill.layer.cornerRadius = 9
        devPill.layer.masksToBounds = true
        devPill.heightAnchor.constraint(equalToConstant: 22).isActive = true
        devPill.widthAnchor.constraint(greaterThanOrEqualToConstant: 126).isActive = true

        let col = UIStackView(arrangedSubviews: [accLB, expLB, devPill])
        col.axis = .vertical
        col.spacing = 8
        col.alignment = .leading

        let row = UIStackView(arrangedSubviews: [ring, col])
        row.axis = .horizontal
        row.spacing = 18
        row.alignment = .center
        status.addSubview(row)

        row.translatesAutoresizingMaskIntoConstraints = false
        ring.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: status.leadingAnchor, constant: 18),
            row.trailingAnchor.constraint(equalTo: status.trailingAnchor, constant: -18),
            row.topAnchor.constraint(equalTo: status.topAnchor, constant: 18),
            row.bottomAnchor.constraint(equalTo: status.bottomAnchor, constant: -18),
            ring.widthAnchor.constraint(equalToConstant: 104),
            ring.heightAnchor.constraint(equalToConstant: 104)
        ])
    }

    private func buildQuick() {
        add(quick)

        let title = UILabel()
        title.text = "网络拦截"
        title.font = DS.h2(17)
        title.textColor = DS.label

        let sub = UILabel()
        sub.font = DS.body(12)
        sub.textColor = DS.label3
        sub.numberOfLines = 2
        sub.text = "按规则丢弃目标 IP / 端口"

        vpnSwitch.onTintColor = DS.accent
        vpnSwitch.addTarget(self, action: #selector(toggle), for: .valueChanged)

        let left = UIStackView(arrangedSubviews: [title, sub])
        left.axis = .vertical
        left.spacing = 4

        let row = UIStackView(arrangedSubviews: [left, vpnSwitch])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center
        quick.addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: quick.leadingAnchor, constant: 18),
            row.trailingAnchor.constraint(equalTo: quick.trailingAnchor, constant: -18),
            row.topAnchor.constraint(equalTo: quick.topAnchor, constant: 18),
            row.bottomAnchor.constraint(equalTo: quick.bottomAnchor, constant: -18)
        ])
    }

    @objc private func reload() {
        let logged = Session.logged
        let exp = Session.expireAt
        let expired = exp > 0 && Int64(Date().timeIntervalSince1970 * 1000) > exp
        let leftMs = max(0, exp - Int64(Date().timeIntervalSince1970 * 1000))

        accLB.text = logged ? (Session.user.isEmpty ? "已登录" : Session.user) : "未登录"
        expLB.text = logged ? "到期 " + Fmt.date(exp) : "注册需卡密 · 卡密由作者发放"
        devPill.text = "  设备 " + String(Dev.id.prefix(8)) + "  "

        ring.set(ratio: exp <= 0 ? 0 : CGFloat(min(1, Double(leftMs) / (30.0 * 86400000.0))),
                 text: exp <= 0 ? "—" : Fmt.left(leftMs) + Fmt.leftUnit(leftMs),
                 sub: expired ? "已到期" : "剩余")

        let usable = logged && !expired
        vpnSwitch.isEnabled = usable
        if Settings.vpnOn && !usable { Settings.vpnOn = false }
        vpnSwitch.setOn(Settings.vpnOn, animated: false)
    }

    @objc private func toggle() {
        Settings.vpnOn = vpnSwitch.isOn
        VPNController.apply(enabled: vpnSwitch.isOn) { err in
            if let e = err {
                Settings.vpnOn = false
                self.vpnSwitch.setOn(false, animated: true)
                HUD.toast("开启失败：" + e, ok: false)
            } else {
                HUD.toast(self.vpnSwitch.isOn ? "拦截已开启" : "拦截已关闭")
            }
        }
    }
}

// MARK: - 账号页

final class AccountPage: BasePage {

    private let card = GlassCard()
    private let userF = GlassField(symbol: "person", placeholder: "账号")
    private let passF = GlassField(symbol: "lock", placeholder: "密码", secure: true)
    private let codeF = GlassField(symbol: "key", placeholder: "卡密（注册 / 续期）")
    private let loginB = PillButton("登录", symbol: "arrow.right.to.line", height: 54)
    private let regB = PillButton("注册（需卡密）", symbol: "person.badge.plus", kind: .secondary, height: 50)
    private let renewB = PillButton("用卡密续期", symbol: "clock.arrow.circlepath", height: 54)
    private let logoutB = PillButton("退出登录", symbol: "rectangle.portrait.and.arrow.right", kind: .danger, height: 48)
    private let tip = UILabel()

    override func viewDidLoad() {
        pageTitle = "账号"
        pageSubtitle = "登录 / 注册 / 续期（一卡一账号）"
        super.viewDidLoad()

        add(card)
        let s = UIStackView(arrangedSubviews: [userF, passF, codeF, loginB, regB, renewB, logoutB])
        s.axis = .vertical
        s.spacing = 12
        card.addSubview(s)
        s.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            s.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            s.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            s.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            s.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])

        tip.font = DS.body(12)
        tip.textColor = DS.label3
        tip.numberOfLines = 0
        tip.text = "密码要求：8–32 位，含字母和数字"
        add(tip)

        loginB.addTarget(self, action: #selector(onLogin), for: .touchUpInside)
        regB.addTarget(self, action: #selector(onRegister), for: .touchUpInside)
        renewB.addTarget(self, action: #selector(onRenew), for: .touchUpInside)
        logoutB.addTarget(self, action: #selector(onLogout), for: .touchUpInside)
        refresh()
    }

    private func refresh() {
        let logged = Session.logged
        userF.isHidden = logged
        passF.isHidden = logged
        loginB.isHidden = logged
        regB.isHidden = logged
        renewB.isHidden = !logged
        logoutB.isHidden = !logged
    }

    private func busy(_ b: Bool, _ msg: String) {
        [loginB, regB, renewB, logoutB].forEach { $0.isEnabled = !b }
        tip.text = msg
    }

    @objc private func onLogin() {
        busy(true, "登录中…")
        AccountApi.login(user: userF.text, pass: passF.text) { r in
            self.busy(false, r.ok ? "登录成功" : "登录失败：" + r.msg)
            if r.ok {
                Session.save(token: r.token, expireAt: r.expireAt, user: r.user.isEmpty ? self.userF.text : r.user)
                self.refresh()
            }
        }
    }

    @objc private func onRegister() {
        guard codeF.text.count >= 6 else { return }
        busy(true, "注册中…")
        AccountApi.register(user: userF.text, pass: passF.text, card: codeF.text) { r in
            self.busy(false, r.ok ? "注册成功" : "注册失败：" + r.msg)
            if r.ok {
                Session.save(token: r.token, expireAt: r.expireAt, user: self.userF.text)
                self.codeF.clear()
                self.refresh()
            }
        }
    }

    @objc private func onRenew() {
        guard codeF.text.count >= 6 else { return }
        busy(true, "续期中…")
        AccountApi.renew(card: codeF.text) { r in
            self.busy(false, r.ok ? "续期成功" : "续期失败：" + r.msg)
            if r.ok {
                Session.touch(expireAt: r.expireAt)
                self.codeF.clear()
                self.refresh()
            }
        }
    }

    @objc private func onLogout() {
        Settings.vpnOn = false
        Session.clear()
        refresh()
    }
}

// MARK: - 规则页

final class RulesPage: BasePage {

    private let card = GlassCard()
    private let statusLB = UILabel()
    private let tiles = UIStackView()
    private let tIp = StatTile(key: "IP", symbol: "network")
    private let tPort = StatTile(key: "端口", symbol: "number")
    private let tDom = StatTile(key: "域名", symbol: "globe")
    private let tKw = StatTile(key: "关键字", symbol: "text.magnifyingglass")
    private let syncB = PillButton("拉取云端规则", symbol: "arrow.down.circle", height: 54)
    private let catCard = GlassCard()
    private let swIp = UISwitch()
    private let swPort = UISwitch()
    private let swDom = UISwitch()
    private let diag = UILabel()

    override func viewDidLoad() {
        pageTitle = "规则"
        pageSubtitle = "云端加密下发 · RSA 验签"
        super.viewDidLoad()

        add(card)
        statusLB.font = DS.body(13)
        statusLB.textColor = DS.label2

        tiles.axis = .horizontal
        tiles.spacing = 10
        tiles.distribution = .fillEqually
        [tIp, tPort, tDom, tKw].forEach { tiles.addArrangedSubview($0) }

        let s = UIStackView(arrangedSubviews: [statusLB, tiles, syncB])
        s.axis = .vertical
        s.spacing = 14
        card.addSubview(s)
        s.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            s.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            s.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            s.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            s.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])

        add(catCard)
        let head = SectionHeader("拦截范围", subtitle: "按分类启用")
        let rows = UIStackView()
        rows.axis = .vertical
        rows.spacing = 10
        rows.addArrangedSubview(makeRow("IP / 网段", swIp, "network"))
        rows.addArrangedSubview(makeRow("端口", swPort, "number"))
        rows.addArrangedSubview(makeRow("域名 / 关键字", swDom, "globe"))
        let box = UIStackView(arrangedSubviews: [head, rows])
        box.axis = .vertical
        box.spacing = 6
        catCard.addSubview(box)
        box.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            box.leadingAnchor.constraint(equalTo: catCard.leadingAnchor, constant: 16),
            box.trailingAnchor.constraint(equalTo: catCard.trailingAnchor, constant: -16),
            box.topAnchor.constraint(equalTo: catCard.topAnchor, constant: 12),
            box.bottomAnchor.constraint(equalTo: catCard.bottomAnchor, constant: -16)
        ])
        for sw in [swIp, swPort, swDom] {
            sw.onTintColor = DS.accent
            sw.isOn = true
            sw.addTarget(self, action: #selector(catChanged), for: .valueChanged)
        }

        diag.font = DS.cap(11)
        diag.textColor = DS.label3
        diag.numberOfLines = 0
        add(diag)

        syncB.addTarget(self, action: #selector(onSync), for: .touchUpInside)
        refresh()
    }

    private func makeRow(_ name: String, _ sw: UISwitch, _ sym: String) -> UIView {
        let ic = UIImageView(image: UIImage(systemName: sym,
                                           withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)))
        ic.tintColor = DS.label3
        ic.contentMode = .scaleAspectFit
        ic.translatesAutoresizingMaskIntoConstraints = false
        ic.widthAnchor.constraint(equalToConstant: 22).isActive = true

        let l = UILabel()
        l.text = name
        l.font = DS.body(15)
        l.textColor = DS.label

        let row = UIStackView(arrangedSubviews: [ic, l, sw])
        row.axis = .horizontal
        row.spacing = 10
        row.alignment = .center
        row.heightAnchor.constraint(equalToConstant: 40).isActive = true
        return row
    }

    private func refresh() {
        let txt = RuleStore.load()
        if txt.isEmpty {
            statusLB.text = "尚未同步 · 点下方拉取"
            diag.text = ""
            tIp.set(0); tPort.set(0); tDom.set(0); tKw.set(0)
            return
        }
        statusLB.text = "已同步 · " + String(txt.utf8.count) + " 字节"
        let st = RuleStats.parse(txt)
        tIp.set(st.ip); tPort.set(st.port); tDom.set(st.dom); tKw.set(st.kw)
        diag.text = "按分类启用：IP/网段、端口、域名与关键字可分别关闭（重开拦截生效）"
    }

    @objc private func catChanged() {
        HUD.toast("拦截范围已更新，重开拦截生效")
    }

    @objc private func onSync() {
        syncB.isEnabled = false
        statusLB.text = "拉取中…"
        CloudRules.fetch { ok, text, d in
            self.syncB.isEnabled = true
            if ok { RuleStore.save(text) }
            self.diag.text = d
            self.refresh()
        }
    }
}

// MARK: - 设置页

final class SettingsPage: BasePage {

    override func viewDidLoad() {
        pageTitle = "设置"
        pageSubtitle = "连接 / 安全 / 关于"
        super.viewDidLoad()

                add(group("连接", rows: [
            ("通道状态", "已加密 · 证书固定"),
            ("传输协议", "HTTPS / TLS 1.2+"),
            ("规则来源", "云端加密下发")
        ]))
        add(group("安全", rows: [
            ("密码策略", "8–32 位 · 字母+数字"),
            ("设备绑定", "单设备在线"),
            ("登录锁定", "5 次失败锁 15 分钟"),
            ("规则验签", "RSA-2048 / SHA-256")
        ]))
        add(group("本机", rows: [
            ("设备指纹", String(Dev.id.prefix(4)) + "******"),
            ("缓存规则", String(RuleStore.load().utf8.count) + " 字节")
        ]))

        let clear = PillButton("清除本地规则缓存", symbol: "trash", kind: .danger, height: 50)
        clear.addTarget(self, action: #selector(onClear), for: .touchUpInside)
        add(clear)

        let about = UILabel()
        about.font = DS.cap(11)
        about.textColor = DS.label3
        about.numberOfLines = 0
        about.text = "LY 内部 iOS v3.9 · 液态玻璃界面\n仅做网络层拦截，不修改任何进程内存"
        add(about)
    }

    private func group(_ title: String, rows: [(String, String)]) -> UIView {
        let c = GlassCard()
        let head = SectionHeader(title)
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 0
        for (k, v) in rows {
            let l = UILabel()
            l.text = k
            l.font = DS.body(15)
            l.textColor = DS.label

            let r = UILabel()
            r.text = v
            r.font = DS.body(13)
            r.textColor = DS.label3
            r.textAlignment = .right
            r.lineBreakMode = .byTruncatingMiddle

            let row = UIStackView(arrangedSubviews: [l, r])
            row.axis = .horizontal
            row.spacing = 12
            row.alignment = .center
            row.heightAnchor.constraint(equalToConstant: 44).isActive = true
            s.addArrangedSubview(row)
        }
        let box = UIStackView(arrangedSubviews: [head, s])
        box.axis = .vertical
        box.spacing = 4
        c.addSubview(box)
        box.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            box.leadingAnchor.constraint(equalTo: c.leadingAnchor, constant: 16),
            box.trailingAnchor.constraint(equalTo: c.trailingAnchor, constant: -16),
            box.topAnchor.constraint(equalTo: c.topAnchor, constant: 12),
            box.bottomAnchor.constraint(equalTo: c.bottomAnchor, constant: -16)
        ])
        return c
    }

    @objc private func onClear() {
        RuleStore.save("")
        HUD.toast("已清除")
    }
}

// MARK: - 玻璃输入框

final class GlassField: UIView, UITextFieldDelegate {
    private let field = UITextField()
    private let icon = UIImageView()
    var text: String { field.text ?? "" }
    func clear() { field.text = "" }

    init(symbol: String, placeholder: String, secure: Bool = false) {
        super.init(frame: .zero)
        backgroundColor = UIColor(white: 1, alpha: 0.9)
        layer.cornerRadius = 16
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = UIColor(white: 0.92, alpha: 1).cgColor

        icon.image = UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .medium))
        icon.tintColor = DS.label3
        icon.contentMode = .scaleAspectFit
        addSubview(icon)

        field.font = DS.body(16)
        field.textColor = DS.label
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
        layer.borderColor = DS.accent.withAlphaComponent(0.55).cgColor
        backgroundColor = .white
    }
    func textFieldDidEndEditing(_ t: UITextField) {
        layer.borderColor = UIColor(white: 0.92, alpha: 1).cgColor
        backgroundColor = UIColor(white: 1, alpha: 0.9)
    }
}
