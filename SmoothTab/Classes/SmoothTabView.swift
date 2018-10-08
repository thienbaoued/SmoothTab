//
//  SmoothTabView.swift
//  SmoothTab
//
//  Created by Yervand Saribekyan on 3/1/18.
//  Copyright © 2018 Yervand Saribekyan. All rights reserved.
//

import UIKit

@objc public protocol SmoothTabDelegate: class {
    func smootItemSelected(at index: Int)
}

public class SmoothTabView: UIView {

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()

    private lazy var selectedView: UIView = {
        let frame = CGRect(
			origin: CGPoint.zero,
			size: CGSize(width: 0, height: self.bounds.height
		))

        let selectedView = UIView(frame: frame)
        selectedView.alpha = 0

        return selectedView
    }()

    private var items = [SmoothTabItem]() {
        didSet {
            itemsViews = items.enumerated().map { index, item in smoothBarItemView(for: item, at: index) }
        }
    }
    private var itemsViews = [UIStackView]() {
        didSet {
            render()
        }
    }

    private var options: SmoothTabOptions = .default

    private var selectedSegmentIndex: Int = 0 {
        didSet {
            selectItem(at: selectedSegmentIndex)
            selectedView.alpha = 1
            transition(from: oldValue, to: selectedSegmentIndex)
            delegate?.smootItemSelected(at: selectedSegmentIndex)
        }
    }

    weak var delegate: SmoothTabDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)

        commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        commonInit()
    }

    public func setup(
        with items: [SmoothTabItem],
        options: SmoothTabOptions = .default,
        delegate: SmoothTabDelegate?) {
        self.options = options
        self.items = items
        self.delegate = delegate
		setOptions(options)
    }

	private func setOptions(_ options: SmoothTabOptions) {
        stackView.spacing = options.itemsMargin
		stackView.backgroundColor = options.backgroundColor
		selectedView.layer.borderWidth = options.borderWidth
		selectedView.layer.borderColor = options.borderColor.cgColor
		switch options.cornerRadius {
		case .rounded:
			selectedView.layer.cornerRadius = bounds.size.height / 2
		case let .fixed(corner):
			selectedView.layer.cornerRadius = corner
		}
		if let shadowOptions = options.shadow {
			setShadow(with: shadowOptions)
		}

	}

    private func setShadow(with options: SmoothTabShadowOptions) {
        layer.shadowColor = options.color.cgColor
        layer.shadowOpacity = options.opacity
        layer.shadowOffset = options.offset
        layer.shadowRadius = options.radius
        layer.shouldRasterize = true

        layer.masksToBounds = false
        layer.rasterizationScale = UIScreen.main.scale
    }

    private func render() {
        stackView.addSubview(selectedView)
        stackView.sendSubview(toBack: selectedView)
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        itemsViews.forEach { stackView.addArrangedSubview($0) }
    }

    private func selectItem(at index: Int) {
        let selectedView = itemsViews[index]
        itemsViews
            .enumerated()
            .flatMap { index, stackView -> UILabel? in
                if let imageView = stackView.arrangedSubviews.first as? UIImageView {
                    imageView.image = items[index].image
                }
                return stackView.arrangedSubviews.last as? UILabel
            }
            .forEach { $0.isHidden = true }

        if let imageView = selectedView.arrangedSubviews.first as? UIImageView {
            imageView.image = items[index].selectedImage
        }

        if let label = selectedView.arrangedSubviews.last as? UILabel {
            label.isHidden = false
        }
    }

    override public func didMoveToWindow() {
        super.didMoveToWindow()
		guard window != nil else { return }
		layoutIfNeeded()
		if itemsViews.count > selectedSegmentIndex {
			transition(from: selectedSegmentIndex, to: selectedSegmentIndex)
		}
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        moveHighlighterView(toItemAt: selectedSegmentIndex)
    }

    public func tapItem(at index: Int) {
        selectedSegmentIndex = index
    }
    
}

/// Setup
private extension SmoothTabView {
    func commonInit() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        stackView.distribution = .fill

        addScrollView()
        addStackView()

    }

    func addScrollView() {
        addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        let topConstraint = NSLayoutConstraint(
            item: scrollView,
            attribute: .top,
            relatedBy: .equal,
            toItem: self,
            attribute: .top,
            multiplier: 1.0,
            constant: 0
        )
        let rightConstraint = NSLayoutConstraint(
            item: scrollView,
            attribute: .right,
            relatedBy: .equal,
            toItem: self,
            attribute: .right,
            multiplier: 1.0,
            constant: 0
        )
        let leftConstraint = NSLayoutConstraint(
            item: scrollView,
            attribute: .left,
            relatedBy: .equal,
            toItem: self,
            attribute: .left,
            multiplier: 1.0,
            constant: 0
        )
        let bottomConstraint = NSLayoutConstraint(
            item: scrollView,
            attribute: .bottom,
            relatedBy: .equal,
            toItem: self,
            attribute: .bottom,
            multiplier: 1.0,
            constant: 0
        )
        addConstraints([
            topConstraint,
            rightConstraint,
            bottomConstraint,
            leftConstraint
            ])
    }

    func smoothBarItemView(for item: SmoothTabItem, at index: Int) -> UIStackView {

        let parentView = UIStackView()
        parentView.tag = index
        parentView.spacing = options.imageTitleMargin
        parentView.distribution = .fill
        parentView.accessibilityIdentifier = kSmoothBarView + "_\(index)"

        parentView.translatesAutoresizingMaskIntoConstraints = false
        let heightConstraint = NSLayoutConstraint(
            item: parentView,
            attribute: .height,
            relatedBy: .equal,
            toItem: nil,
            attribute: .height,
            multiplier: 1.0,
            constant: bounds.size.height
        )
        parentView.addConstraint(heightConstraint)

        parentView.isLayoutMarginsRelativeArrangement = true
        parentView.layoutMargins = UIEdgeInsets(
			top: 0,
			left: options.innerPadding,
			bottom: 0,
			right: options.innerPadding)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(itemTapped(_:)))
        tapGesture.numberOfTapsRequired = 1
        tapGesture.numberOfTouchesRequired = 1
        parentView.addGestureRecognizer(tapGesture)
        parentView.isUserInteractionEnabled = true

        let imageView = UIImageView()
        imageView.accessibilityIdentifier = kSmoothBarImage + "_\(index)"
        imageView.contentMode = options.imageContentMode
        imageView.image = item.image
        parentView.addArrangedSubview(imageView)

        let label = UILabel()
        label.accessibilityIdentifier = kSmoothBarTitle + "_\(index)"
        label.text = item.title
        label.font = options.titleFont
        label.textColor = options.titleColor
        label.isHidden = true
        parentView.addArrangedSubview(label)
        return parentView
    }

    @objc private func itemTapped(_ sender: UITapGestureRecognizer) {
        guard let selectedView = sender.view as? UIStackView else { return }
        selectedSegmentIndex = selectedView.tag

    }
}

/// Setup Constraints
private extension SmoothTabView {
    func addStackView() {
        scrollView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        let topConstraint = NSLayoutConstraint(
            item: stackView,
            attribute: .top,
            relatedBy: .equal,
            toItem: scrollView,
            attribute: .top,
            multiplier: 1.0,
            constant: 0
        )
        let rightConstraint = NSLayoutConstraint(
            item: stackView,
            attribute: .right,
            relatedBy: .equal,
            toItem: scrollView,
            attribute: .right,
            multiplier: 1.0,
            constant: 0
        )
        let leftConstraint = NSLayoutConstraint(
            item: stackView,
            attribute: .left,
            relatedBy: .equal,
            toItem: scrollView,
            attribute: .left,
            multiplier: 1.0,
            constant: 0
        )
        let bottomConstraint = NSLayoutConstraint(
            item: stackView,
            attribute: .bottom,
            relatedBy: .equal,
            toItem: scrollView,
            attribute: .bottom,
            multiplier: 1.0,
            constant: 0
        )
        let widthConstraint = NSLayoutConstraint(
            item: stackView,
            attribute: .width,
            relatedBy: .equal,
            toItem: scrollView,
            attribute: .width,
            multiplier: 1.0,
            constant: 150
        )
        widthConstraint.priority = UILayoutPriority(Float(250))
        addConstraints([
            topConstraint,
            rightConstraint,
            bottomConstraint,
            leftConstraint,
            widthConstraint
            ])
    }
}

/// Animating
private extension SmoothTabView {
    func transition(from fromIndex: Int, to toIndex: Int) {
        let animation = {
            self.stackView.layoutIfNeeded()
            self.layoutIfNeeded()
            self.moveHighlighterView(toItemAt: toIndex)
        }

        UIView.animate(
            withDuration: SwitchAnimationDuration,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 3,
            options: [],
            animations: animation,
            completion: nil
        )
    }

    func moveHighlighterView(toItemAt toIndex: Int) {
        guard itemsViews.count > toIndex else {
            return
        }

        let toView = itemsViews[toIndex]

        // offset for first item
        let point = convert(toView.frame.origin, to: self)
        let offsetForFirstItem: CGFloat = toIndex == 0 ? -HighlighterViewOffScreenOffset : 0
        selectedView.frame.origin.x = point.x + offsetForFirstItem

        // offset for last item
        let offsetForLastItem: CGFloat = toIndex == itemsViews.count - 1 ? HighlighterViewOffScreenOffset : 0
        selectedView.frame.size.width = toView.frame.size.width + offsetForLastItem - offsetForFirstItem

        selectedView.backgroundColor = items[toIndex].tintColor

        var newOffset: CGPoint?

        if selectedView.frame.origin.x + selectedView.frame.size.width - scrollView.contentOffset.x > bounds.size.width {
            let distance = selectedView.frame.origin.x - scrollView.contentOffset.x
            let showed = bounds.size.width - distance
            let mustShow = selectedView.frame.size.width - showed
            let newX = scrollView.contentOffset.x + mustShow - ( toIndex != itemsViews.count - 1 ? 0 : HighlighterViewOffScreenOffset )
            newOffset = CGPoint(x: newX, y: 0)
        }

        if selectedView.frame.origin.x < scrollView.contentOffset.x {
            newOffset = CGPoint(x: selectedView.frame.origin.x + ( toIndex != 0 ? 0 : HighlighterViewOffScreenOffset ), y: 0)
        }

        if let offset = newOffset {
            scrollView.setContentOffset(offset, animated: true)
        }
    }
}
