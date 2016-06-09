//
//  SplitViewController.swift
//  Canvas
//
//  Created by Sam Soffes on 5/17/16.
//  Copyright © 2016 Canvas Labs, Inc. All rights reserved.
//

import UIKit

class SplitViewController: UISplitViewController {

	// MARK: - Properties

	private var lastSize: CGSize?

	// MARK: - Initializers

	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
		super.init(nibName: nil, bundle: nil)
		preferredDisplayMode = .AllVisible
		delegate = self
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}


	// MARK: - UIViewController

	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = Color.lightGray
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()

		// Work around wrong automatic primary column calculatations by UISplitViewController
		guard let window = view.window where lastSize != window.bounds.size else { return }

		lastSize = window.bounds.size

		let screen = window.screen
		let width: CGFloat

		if window.bounds.width < screen.bounds.width {
			width = 258
		} else {
			width = window.bounds.width > 1024 ? 375 : 320
		}

		minimumPrimaryColumnWidth = width
		maximumPrimaryColumnWidth = width
	}

	override func showViewController(viewController: UIViewController, sender: AnyObject?) {
		// Prevent weird animation *sigh*
		UIView.performWithoutAnimation {
			super.showViewController(viewController, sender: sender)
			self.view.layoutIfNeeded()
			viewController.view.layoutIfNeeded()
		}
	}


	// MARK: - Private

	@objc private func toggleSidebar() {
		preferredDisplayMode = displayMode == .AllVisible ? .PrimaryHidden : .AllVisible
	}
}


extension SplitViewController: UISplitViewControllerDelegate {
	func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController: UIViewController, ontoPrimaryViewController primaryViewController: UIViewController) -> Bool {
		if !isEmpty(secondaryViewController: secondaryViewController) {
			var target = secondaryViewController
			if let top = (secondaryViewController as? UINavigationController)?.topViewController {
				target = top
			}

			target.navigationItem.leftBarButtonItem = nil
			return false
		}

		return true
	}

	func primaryViewControllerForExpandingSplitViewController(splitViewController: UISplitViewController) -> UIViewController? {
		guard let outer = splitViewController.viewControllers.first as? UINavigationController,
			detailNavigationController = outer.topViewController as? UINavigationController,
			detailViewController = detailNavigationController.topViewController
		else { return nil }

		if detailViewController is EditorViewController || detailViewController is PlaceholderViewController {
			return masterViewController
		}

		return detailViewController
	}

	func splitViewController(splitViewController: UISplitViewController, showDetailViewController viewController: UIViewController, sender: AnyObject?) -> Bool {
		var detail = viewController
		if let top = (detail as? UINavigationController)?.topViewController {
			detail = top
		}

		let isPlaceholder = detail is PlaceholderViewController
		if !isPlaceholder && !collapsed {
			detail.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "SidebarLeft"), style: .Plain, target: self, action: #selector(toggleSidebar))
		}

		splitViewController.preferredDisplayMode = isPlaceholder ? .AllVisible : .Automatic

		return false
	}

	func targetDisplayModeForActionInSplitViewController(splitViewController: UISplitViewController) -> UISplitViewControllerDisplayMode {
		switch splitViewController.displayMode {
		case .PrimaryOverlay, .PrimaryHidden: return .AllVisible
		default: return .PrimaryHidden
		}
	}

	private func isEmpty(secondaryViewController secondaryViewController: UIViewController? = nil) -> Bool {
		let viewController = secondaryViewController ?? detailViewController
		if let secondaryNavigationController = viewController as? UINavigationController {
			return secondaryNavigationController.topViewController is PlaceholderViewController
		}
		
		return false
	}
}
