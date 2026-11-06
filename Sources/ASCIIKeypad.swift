//
//  ASCIIKeypad.swift — 自绘输入键盘
//  目的：完全绕开系统键盘（TextInputUI 候选栏在 iPad M2 + iOS 16.5 会崩）
//

import UIKit

final class ASCIIKeypad: UIView {

    weak var target: UITextField?

    private let rows: [[String]] = [
        ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
        ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
        ["a", "s", "d", "f", "g", "h", "j", "k", "l", "-"],
        ["z", "x", "c", "v", "b", "n", "m", ".", "_", "@"]
    ]

    override init(frame: CGRect) {
        super.init(frame: frame)
        autoresizingMask = .flexibleHeight
        backgroundColor = UIColor(white: 0.94, alpha: 1)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6)
        ])

        for row in rows {
            stack.addArrangedSubview(makeRow(row))
        }
        stack.addArrangedSubview(makeBottomRow())
    }
    required init?(coder: NSCoder) { return nil }

    override var intrinsicContentSize: CGSize { CGSize(width: UIView.noIntrinsicMetric, height: 268) }

    private func makeRow(_ keys: [String]) -> UIView {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 4
        s.distribution = .fillEqually
        for k in keys {
            s.addArrangedSubview(keyButton(k, action: #selector(onKey(_:))))
        }
        return s
    }

    private func makeBottomRow() -> UIView {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 4
        s.distribution = .fillEqually

        let del = UIButton(type: .system)
        del.setTitle("⌫", for: .normal)
        del.titleLabel?.font = .systemFont(ofSize: 20, weight: .medium)
        del.backgroundColor = UIColor(white: 0.85, alpha: 1)
        del.layer.cornerRadius = 8
        del.heightAnchor.constraint(equalToConstant: 42).isActive = true
        del.addTarget(self, action: #selector(onDelete), for: .touchUpInside)
        s.addArrangedSubview(del)

        let space = UIButton(type: .system)
        space.setTitle("空格", for: .normal)
        space.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        space.backgroundColor = UIColor(white: 0.85, alpha: 1)
        space.layer.cornerRadius = 8
        space.addTarget(self, action: #selector(onSpace), for: .touchUpInside)
        s.addArrangedSubview(space)

        let done = UIButton(type: .system)
        done.setTitle("完成", for: .normal)
        done.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        done.setTitleColor(.white, for: .normal)
        done.backgroundColor = DS.accent
        done.layer.cornerRadius = 8
        done.addTarget(self, action: #selector(onDone), for: .touchUpInside)
        s.addArrangedSubview(done)
        return s
    }

    private func keyButton(_ title: String, action: Selector) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        b.setTitleColor(DS.label, for: .normal)
        b.backgroundColor = .white
        b.layer.cornerRadius = 8
        b.layer.borderWidth = 0.5
        b.layer.borderColor = UIColor(white: 0.86, alpha: 1).cgColor
        b.heightAnchor.constraint(equalToConstant: 42).isActive = true
        b.addTarget(self, action: action, for: .touchUpInside)
        return b
    }

    @objc private func onKey(_ sender: UIButton) {
        guard let t = target, let k = sender.title(for: .normal) else { return }
        t.insertText(k)
    }

    @objc private func onDelete() {
        target?.deleteBackward()
    }

    @objc private func onSpace() {
        target?.insertText(" ")
    }

    @objc private func onDone() {
        target?.resignFirstResponder()
    }
}
