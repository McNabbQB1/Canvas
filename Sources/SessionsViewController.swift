//
//  SessionsViewController.swift
//  Canvas
//
//  Created by Sam Soffes on 5/16/16.
//  Copyright © 2016 Canvas Labs, Inc. All rights reserved.
//

import UIKit
import CanvasCore
import CanvasKit
import OnePasswordExtension

class SessionsViewController: StackViewController {

	// MARK: - Properties
	
	let iconView: UIView = {
		let stackView = UIStackView()
		stackView.axis = .Vertical
		stackView.alignment = .Center
		
		let imageView = UIImageView(image: UIImage(named: "Icon-Small"))
		stackView.addArrangedSubview(imageView)
		
		return stackView
	}()
	
	let headingLabel: UILabel = {
		let label = UILabel()
		label.textColor = Swatch.black
		label.font = Font.sansSerif(size: .heading)
		label.textAlignment = .Center
		return label
	}()

	let usernameTextField: UITextField = {
		let textField = TextField()
		textField.keyboardType = .EmailAddress
		textField.placeholder = LocalizedString.LoginPlaceholder.string
		textField.returnKeyType = .Next
		textField.autocapitalizationType = .None
		textField.autocorrectionType = .No
		return textField
	}()
	
	let passwordTextField: UITextField = {
		let textField = TextField()
		textField.secureTextEntry = true
		textField.placeholder = LocalizedString.PasswordPlaceholder.string
		textField.returnKeyType = .Go
		return textField
	}()

	let submitButton: IndicatorButton = {
		let button = IndicatorButton()
		button.translatesAutoresizingMaskIntoConstraints = false
		button.setTitleColor(UIColor(red: 0.209, green: 0.556, blue: 1, alpha: 1), forState: .Disabled)
		return button
	}()
	
	let footerButton: UIButton = {
		let button = UIButton()
		button.translatesAutoresizingMaskIntoConstraints = false
		button.setTitle("Don’t have an account? Sign up.", forState: .Normal)
		button.titleLabel?.font = Font.sansSerif(size: .subtitle)
		button.setTitleColor(Swatch.gray, forState: .Normal)
		
		let lineView = LineView()
		lineView.translatesAutoresizingMaskIntoConstraints = false
		lineView.backgroundColor = Swatch.border
		button.addSubview(lineView)
		
		NSLayoutConstraint.activateConstraints([
			lineView.widthAnchor.constraintEqualToAnchor(button.widthAnchor),
			lineView.topAnchor.constraintEqualToAnchor(button.topAnchor)
		])
		
		return button
	}()

	var textFields: [UITextField] {
		return [usernameTextField, passwordTextField]
	}

	var loading = false {
		didSet {
			textFields.forEach { $0.enabled = !loading }
			submitButton.enabled = !loading
			submitButton.loading = loading
			UIApplication.sharedApplication().networkActivityIndicatorVisible = loading
		}
	}


	// MARK: - UIViewController
	
	override var title: String? {
		didSet {
			headingLabel.text = title
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		
		// 1Password
		if OnePasswordExtension.sharedExtension().isAppExtensionAvailable() {
			let button = UIButton(frame: CGRect(x: 0, y: 0, width: 32, height: 44))
			button.setImage(UIImage(named: "OnePassword"), forState: .Normal)
			button.imageView?.tintColor = Swatch.white
			button.addTarget(self, action: #selector(onePassword), forControlEvents: .TouchUpInside)
			passwordTextField.rightView = button
			passwordTextField.rightViewMode = .Always
		}
		
		// Icon
		if view.bounds.height > 480 {
			stackView.addArrangedSubview(iconView)
			
			if view.bounds.height > 568 {
				stackView.addArrangedSubview(headingLabel)
			}
		}

		// Text fields
		textFields.forEach { textField in
			stackView.addArrangedSubview(textField)
			textField.delegate = self
		}
		
		submitButton.addTarget(self, action: #selector(submit), forControlEvents: .TouchUpInside)
		stackView.addArrangedSubview(submitButton)
		
		view.addSubview(footerButton)
	
		NSLayoutConstraint.activateConstraints([
			footerButton.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor),
			footerButton.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor),
			footerButton.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor),
			footerButton.heightAnchor.constraintEqualToConstant(48)
		])
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		textFields.first?.becomeFirstResponder()
	}


	// MARK: - Actions

	func submit() {
		// Subclasses should override this
	}
	
	func onePassword(sender: AnyObject?) {
		// Subclasses should override this
	}


	// MARK: - Factory

	func secondaryButton(title title: String, emphasizedRange: NSRange) -> UIButton {
		let button = UIButton()
		button.titleLabel?.numberOfLines = 0
		button.titleLabel?.textAlignment = .Center

		let text = NSMutableAttributedString(string: title, attributes: [
			NSFontAttributeName: Font.sansSerif(weight: .bold, size: .subtitle),
			NSForegroundColorAttributeName: UIColor(white: 1, alpha: 0.7)
		])

		text.addAttribute(NSForegroundColorAttributeName, value: Swatch.white, range: emphasizedRange)
		button.setAttributedTitle(text, forState: .Normal)

		if let highlightedText = text.mutableCopy() as? NSMutableAttributedString {
			highlightedText.addAttribute(NSForegroundColorAttributeName, value: Swatch.white.colorWithAlphaComponent(0.9), range: NSRange(location: 0, length: highlightedText.length))
			highlightedText.addAttribute(NSForegroundColorAttributeName, value: Swatch.white, range: emphasizedRange)
			button.setAttributedTitle(highlightedText, forState: .Highlighted)
		}

		return button
	}
}


extension SessionsViewController: UITextFieldDelegate {
	func textFieldShouldReturn(textField: UITextField) -> Bool {
		let count = textFields.count
		for (i, field) in textFields.enumerate() {
			if field == textField && i < count - 1 {
				textFields[i + 1].becomeFirstResponder()
				return false
			}
		}

		submit()

		return false
	}

	func textFieldDidEndEditing(textField: UITextField) {
		// Workaround iOS bug that causes text to flicker when you lose focus
		textField.layoutIfNeeded()
	}
}
