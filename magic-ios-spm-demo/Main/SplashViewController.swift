//
//  SplashViewController.swift
//
//  The first screen, branded Payward. It asks Magic whether the user has a session, then
//  replaces itself with the main tabs or the login screen.

import UIKit
import MagicSDK

class SplashViewController: UIViewController {

    /// How long to wait for the session check before showing the login screen.
    private let sessionCheckTimeout: TimeInterval = 10

    private var didCheckSession = false
    private var didRoute = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        // Payward wordmark: black on light, white on dark (see PaywardWordmark in Assets)
        let wordmark = UIImageView(image: UIImage(named: "PaywardWordmark"))
        wordmark.contentMode = .scaleAspectFit
        wordmark.isAccessibilityElement = true
        wordmark.accessibilityLabel = "Payward"

        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.startAnimating()

        let caption = UILabel()
        caption.text = "Checking your session..."
        caption.font = .preferredFont(forTextStyle: .footnote)
        caption.textColor = .secondaryLabel

        let stack = UIStackView(arrangedSubviews: [wordmark, spinner, caption])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 24
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            wordmark.widthAnchor.constraint(equalToConstant: 220),
            wordmark.heightAnchor.constraint(equalTo: wordmark.widthAnchor, multiplier: 500.0 / 3624.0)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didCheckSession else { return }
        didCheckSession = true
        checkSession()
    }

    private func checkSession() {
        guard let magic = Magic.shared else {
            route(loggedIn: false)
            return
        }

        magic.user.isLoggedIn { [weak self] response in
            DispatchQueue.main.async {
                self?.route(loggedIn: response.result == true)
            }
        }

        // The check goes through a web view. If it never answers, do not leave the user here.
        DispatchQueue.main.asyncAfter(deadline: .now() + sessionCheckTimeout) { [weak self] in
            self?.route(loggedIn: false)
        }
    }

    /// Replaces the splash screen. Only the first call does anything.
    private func route(loggedIn: Bool) {
        guard !didRoute else { return }
        didRoute = true

        let identifier = loggedIn ? MainTabBarController.storyboardIdentifier : LoginViewController.storyboardIdentifier
        let next = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: identifier)
        (UIApplication.shared.delegate as? AppDelegate)?.changeRootViewController(next)
    }
}
