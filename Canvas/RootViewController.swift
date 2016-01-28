//
//  RootViewController.swift
//  Canvas
//
//  Created by Sam Soffes on 11/12/15.
//  Copyright © 2015 Canvas Labs, Inc. All rights reserved.
//

import UIKit
import CanvasKit
import Raven

final class RootViewController: UIViewController {

	// MARK: - Properties

	private(set) var viewController: UIViewController? {
		willSet {
			guard let viewController = viewController else { return }
			viewController.viewWillDisappear(false)
			viewController.view.removeFromSuperview()
			viewController.viewDidDisappear(false)
			viewController.removeFromParentViewController()
		}

		didSet {
			guard let viewController = viewController else { return }
			addChildViewController(viewController)

			viewController.view.translatesAutoresizingMaskIntoConstraints = false
			viewController.viewWillAppear(false)
			view.addSubview(viewController.view)

			NSLayoutConstraint.activateConstraints([
				viewController.view.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor),
				viewController.view.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor),
				viewController.view.topAnchor.constraintEqualToAnchor(view.topAnchor),
				viewController.view.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor)
			])
			viewController.viewDidAppear(false)

			setNeedsStatusBarAppearanceUpdate()
		}
	}


	// MARK: - Initializers

	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)

	}


	// MARK: - UIViewController

	override func viewDidLoad() {
		super.viewDidLoad()

		NSNotificationCenter.defaultCenter().addObserver(self, selector: "accountDidChange:", name: AccountController.accountDidChangeNotificationName, object: nil)
		accountDidChange(nil)
	}

	override func childViewControllerForStatusBarStyle() -> UIViewController? {
		return viewController
	}

	override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
		return traitCollection.userInterfaceIdiom == .Pad ? .All : .AllButUpsideDown
	}


	// MARK: - Private

	@objc private func accountDidChange(notification: NSNotification?) {
		guard let account = AccountController.sharedController.currentAccount else {
			RavenClient.sharedClient?.user = nil
			viewController = LoginViewController()
			return
		}

		RavenClient.sharedClient?.user = [
			"id": account.user.ID,
			"username": account.user.username
		]

		if var viewController = viewController as? Accountable {
			// TODO: Handle containers
			viewController.account = account
			return
		}

		viewController = NavigationController(rootViewController: OrganizationsViewController(account: account))
	}
}
