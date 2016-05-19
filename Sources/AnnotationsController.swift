//
//  AnnotationsController.swift
//  CanvasText
//
//  Created by Sam Soffes on 3/7/16.
//  Copyright © 2016 Canvas Labs, Inc. All rights reserved.
//

import UIKit
import CanvasNative

protocol AnnotationsControllerDelegate: class {
	func annotationsController(annotationsController: AnnotationsController, willAddAnnotation annotation: Annotation)
	func annotationsController(annotationsController: AnnotationsController, willRemoveAnnotation annotation: Annotation)
}

final class AnnotationsController {

	// MARK: - Properties

	var enabled = true

	var theme: Theme {
		didSet {
			for annotation in annotations {
				annotation?.theme = theme
			}
		}
	}

	var textContainerInset: EdgeInsets = .zero {
		didSet {
			layoutAnnotations()
		}
	}

	var horizontalSizeClass: UserInterfaceSizeClass = .Unspecified {
		didSet {
			for annotation in annotations {
				annotation?.horizontalSizeClass = horizontalSizeClass
			}
		}
	}

	weak var delegate: AnnotationsControllerDelegate?
	weak var textController: TextController?

	private var annotations = [Annotation?]()


	// MARK: - Initializers

	init(theme: Theme) {
		self.theme = theme
	}


	// MARK: - Manipulating

	func insert(block block: BlockNode, index: Int) {
		guard enabled, let block = block as? Annotatable, annotation = annotationForBlock(block) else {
			annotations.insert(nil, atIndex: index)
			return
		}

		annotations.insert(annotation, atIndex: index)
		delegate?.annotationsController(self, willAddAnnotation: annotation)

		// Add taps
		if annotation.view.userInteractionEnabled {
			let tap = UITapGestureRecognizer(target: self, action: #selector(self.tap))
			annotation.view.addGestureRecognizer(tap)
		}
	}

	func remove(block block: BlockNode, index: Int) {
		guard enabled && index < annotations.count else { return }

		if let annotation = annotations[index] {
			delegate?.annotationsController(self, willRemoveAnnotation: annotation)
		}

		annotations[index]?.view.removeFromSuperview()
		annotations.removeAtIndex(index)
	}

	func update(block block: BlockNode, index: Int) {
		guard enabled && index < annotations.count, let block = block as? Annotatable, annotation = annotations[index] else { return }
		annotation.block = block
	}


	// MARK: - Layout

	func layoutAnnotations() {
		for annotation in annotations {
			guard let annotation = annotation else { continue }
			annotation.view.frame = rectForAnnotation(annotation)
		}
	}

	func rectForAnnotation(annotation: Annotation) -> CGRect {
		guard let textController = textController else { return .zero }

		let document = textController.currentDocument
		var presentationRange = document.presentationRange(block: annotation.block)

		// Add new line
		if presentationRange.max < (document.presentationString as NSString).length {
			presentationRange.length += 1
		}

		guard let rects = rectsForPresentationRange(presentationRange), firstRect = rects.first else { return .zero }
		var rect: CGRect

		switch annotation.placement {
		case .FirstLeadingGutter:
			rect = firstRect
			rect.size.width = rect.origin.x
			rect.origin.x = 0
		case .ExpandedLeadingGutter:
			rect = rects.reduce(firstRect) { $0.union($1) }
			rect.size.width = rect.origin.x
			rect.origin.x = 0
		case .ExpandedBackground:
			rect = rects.reduce(firstRect) { $0.union($1) }
			rect.origin.x = 0
			rect.size.width = textController.textContainer.size.width
		}

		// Expand to the top of the next block if neccessary
		if annotation.placement.isExpanded, let positionable = annotation.block as? Positionable where !positionable.position.isBottom {
			if let index = document.indexOf(block: annotation.block) where index < document.blocks.count - 1 {
				var nextRange = document.presentationRange(blockIndex: index + 1)
				nextRange.length = min(presentationRange.length + 1, textController.textStorage.length - nextRange.location)

				if let nextRect = firstRectsForPresentationRange(nextRange) {
					if nextRect.minY > rect.maxY {
						rect.size.height = nextRect.minY - rect.minY
					}
				}
			}
		}

		rect.origin.x += textContainerInset.left
		rect.origin.y += textContainerInset.top

		// Account for line height
		// TODO: We should get this a better way
		rect.origin.y += 3

		return rect.integral
	}


	// MARK: - Private

	private func firstRectsForPresentationRange(presentationRange: NSRange) -> CGRect? {
		guard let textController = textController else { return nil }

		let layoutManager = textController.layoutManager

		let glyphRange = layoutManager.glyphRangeForCharacterRange(presentationRange, actualCharacterRange: nil)
		layoutManager.ensureLayoutForGlyphRange(glyphRange)

		var rect: CGRect?
		layoutManager.enumerateLineFragmentsForGlyphRange(glyphRange) { availableRect, usedRect, _, _, stop in
			rect = usedRect
			stop.memory = true
		}

		return rect ?? layoutManager.extraLineFragmentRect
	}

	private func rectsForPresentationRange(presentationRange: NSRange) -> [CGRect]? {
		guard let textController = textController else { return nil }

		let layoutManager = textController.layoutManager

		let glyphRange = layoutManager.glyphRangeForCharacterRange(presentationRange, actualCharacterRange: nil)
		layoutManager.ensureLayoutForGlyphRange(glyphRange)

		var rects = [CGRect]()
		layoutManager.enumerateLineFragmentsForGlyphRange(glyphRange) { availableRect, usedRect, _, _, _ in
			rects.append(usedRect)
		}

		// Handle the last line
		if rects.isEmpty {
			rects.append(layoutManager.extraLineFragmentRect)
		}

		return rects
	}

	private func annotationForBlock(block: Annotatable) -> Annotation? {
		return block.annotation(theme: theme)
	}

	@objc private func tap(sender: UITapGestureRecognizer?) {
		guard let annotation = sender?.view as? CheckboxView,
			block = annotation.block as? ChecklistItem
		else { return }

		let range = block.stateRange
		let replacement = block.state.opposite.string
		textController?.edit(backingRange: range, replacement: replacement)
	}
}
