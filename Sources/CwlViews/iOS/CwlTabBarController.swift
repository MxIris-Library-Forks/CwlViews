//
//  CwlTabBarController.swift
//  CwlViews
//
//  Created by Matt Gallagher on 2018/03/08.
//  Copyright © 2018 Matt Gallagher ( https://www.cocoawithlove.com ). All rights reserved.
//
//  Permission to use, copy, modify, and/or distribute this software for any purpose with or without
//  fee is hereby granted, provided that the above copyright notice and this permission notice
//  appear in all copies.
//
//  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS
//  SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
//  AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
//  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
//  NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE
//  OF THIS SOFTWARE.
//

#if os(macOS)
	import AppKit
#else
	import UIKit
#endif

public class TabBarController<ItemIdentifier: Hashable>: ConstructingBinder, TabBarControllerConvertible {
	public typealias Instance = UITabBarController
	public typealias Inherited = ViewController
	
	public var state: ConstructingBinderState<Instance, Binding>
	public required init(state: ConstructingBinderState<Instance, Binding>) {
		self.state = state
	}
	public static func bindingToInherited(_ binding: Binding) -> Inherited.Binding? {
		if case .inheritedBinding(let s) = binding { return s } else { return nil }
	}
	public func uiTabBarController() -> Instance { return instance() }
	
	public enum Binding: TabBarControllerBinding {
		public typealias ItemIdentifierType = ItemIdentifier
		public typealias EnclosingBinder = TabBarController
		public static func tabBarControllerBinding(_ binding: Binding) -> Binding { return binding }
		case inheritedBinding(Inherited.Binding)
		
		//	0. Static bindings are applied at construction and are subsequently immutable.
		case tabBar(Constant<TabBar<ItemIdentifier>>)

		// 1. Value bindings may be applied at construction and may subsequently change.
		case items(Dynamic<SetOrAnimate<[ItemIdentifier]>>)
		case customizableItems(Dynamic<Set<ItemIdentifier>>)

		// 2. Signal bindings are performed on the object after construction.
		case selectItem(Signal<ItemIdentifier>)

		// 3. Action bindings are triggered by the object after construction.
		case didSelect(SignalInput<ItemIdentifier>)
		case willBeginCustomizing(SignalInput<[ItemIdentifier]>)
		case willEndCustomizing(SignalInput<([ItemIdentifier], Bool)>)
		case didEndCustomizing(SignalInput<([ItemIdentifier], Bool)>)

		// 4. Delegate bindings require synchronous evaluation within the object's context.
		case tabConstructor((ItemIdentifier) -> ViewControllerConvertible)
		case shouldSelect((ItemIdentifier) -> Bool)
		case supportedInterfaceOrientations(() -> UIInterfaceOrientationMask)
		case preferredInterfaceOrientationForPresentation(() -> UIInterfaceOrientation)
		case interactionControllerForAnimation((UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning?)
		case animationControllerForTransition((UIViewController, UIViewController) -> UIViewControllerAnimatedTransitioning?)
	}

	public struct Preparer: ConstructingPreparer {
		public typealias EnclosingBinder = TabBarController
		public var linkedPreparer = Inherited.Preparer()

		public func constructStorage() -> EnclosingBinder.Storage { return Storage() }
		public func constructInstance(subclass: EnclosingBinder.Instance.Type) -> EnclosingBinder.Instance { return subclass.init() }

		public init() {
			self.init(delegateClass: Delegate.self)
		}
		public init<Value>(delegateClass: Value.Type) where Value: Delegate {
			self.delegateClass = delegateClass
		}
		public let delegateClass: Delegate.Type
		var possibleDelegate: Delegate? = nil
		mutating func delegate() -> Delegate {
			if let d = possibleDelegate {
				return d
			} else {
				let d = delegateClass.init()
				possibleDelegate = d
				return d
			}
		}
		
		var tabConstructor: ((ItemIdentifier) -> ViewControllerConvertible)?
		
		public mutating func prepareBinding(_ binding: Binding) {
			switch binding {
			case .tabConstructor(let x): tabConstructor = x
			case .shouldSelect(let x):
				let s = #selector(UITabBarControllerDelegate.tabBarController(_:shouldSelect:))
				delegate().addSelector(s).shouldSelect = x
			case .supportedInterfaceOrientations(let x):
				let s = #selector(UITabBarControllerDelegate.tabBarControllerSupportedInterfaceOrientations(_:))
				delegate().addSelector(s).supportedInterfaceOrientations = x
			case .preferredInterfaceOrientationForPresentation(let x):
				let s = #selector(UITabBarControllerDelegate.tabBarControllerPreferredInterfaceOrientationForPresentation(_:))
				delegate().addSelector(s).preferredInterfaceOrientationForPresentation = x
			case .interactionControllerForAnimation(let x):
				let s = #selector(UITabBarControllerDelegate.tabBarController(_:interactionControllerFor:))
				delegate().addSelector(s).interactionControllerForAnimation = x
			case .animationControllerForTransition(let x):
				let s = #selector(UITabBarControllerDelegate.tabBarController(_:animationControllerForTransitionFrom:to:))
				delegate().addSelector(s).animationControllerForTransition = x
			case .willBeginCustomizing(let x):
				let s = #selector(UITabBarControllerDelegate.tabBarController(_:willBeginCustomizing:))
				delegate().addSelector(s).willBeginCustomizing = x
			case .willEndCustomizing(let x):
				let s = #selector(UITabBarControllerDelegate.tabBarController(_:willEndCustomizing:changed:))
				delegate().addSelector(s).willEndCustomizing = x
			case .didEndCustomizing(let x):
				let s = #selector(UITabBarControllerDelegate.tabBarController(_:didEndCustomizing:changed:))
				delegate().addSelector(s).didEndCustomizing = x
			case .didSelect(let x):
				let s = #selector(UITabBarControllerDelegate.tabBarController(_:didSelect:))
				delegate().addSelector(s).didSelect = x
			case .inheritedBinding(let x): linkedPreparer.prepareBinding(x)
			default: break
			}
		}
		
		public mutating func prepareInstance(_ instance: Instance, storage: Storage) {
			precondition(instance.delegate == nil, "Conflicting delegate applied to instance")

			storage.dynamicDelegate = possibleDelegate
			storage.tabConstructor = tabConstructor

			if storage.inUse {
				instance.delegate = storage
			}
			
			linkedPreparer.prepareInstance(instance, storage: storage)
		}
		
		public func applyBinding(_ binding: Binding, instance: Instance, storage: Storage) -> Cancellable? {
			switch binding {
			case .tabBar(let x):
				x.value.applyBindings(to: instance.tabBar)
				return nil
			case .items(let x):
				return x.apply(instance, storage) { inst, stor, val in
					let items = val.value.compactMap { stor.viewController(for: $0) }
					inst.setViewControllers(items, animated: val.isAnimated)
				}
			case .customizableItems(let x):
				return x.apply(instance, storage) { inst, stor, val in
					inst.customizableViewControllers = val.compactMap { stor.viewController(for: $0) }
				}
			case .selectItem(let x):
				return x.apply(instance, storage) { inst, stor, val in
					if let vc = stor.viewController(for: val), let index = inst.viewControllers?.index(of: vc) {
						inst.selectedIndex = index
					}
				}
			case .tabConstructor: return nil
			case .didSelect: return nil
			case .willBeginCustomizing: return nil
			case .willEndCustomizing: return nil
			case .didEndCustomizing: return nil
			case .shouldSelect: return nil
			case .supportedInterfaceOrientations: return nil
			case .preferredInterfaceOrientationForPresentation: return nil
			case .interactionControllerForAnimation: return nil
			case .animationControllerForTransition: return nil
			case .inheritedBinding(let b): return linkedPreparer.applyBinding(b, instance: instance, storage: storage)
			}
		}
	}

	open class Storage: ViewController.Storage, UITabBarControllerDelegate {
		open var tabConstructor: ((ItemIdentifier) -> ViewControllerConvertible)?
		open var allItems: [ItemIdentifier: ViewControllerConvertible] = [:]
		
		open override var inUse: Bool { return true }
		
		open func identifier(for viewController: UIViewController) -> ItemIdentifier? {
			return allItems.first(where: { pair -> Bool in
				pair.value.uiViewController() === viewController
			})?.key
		}
		open func viewController(for identifier: ItemIdentifier) -> UIViewController? {
			if let existing = allItems[identifier] {
				return existing.uiViewController()
			}
			if let constructor = tabConstructor {
				let new = constructor(identifier)
				allItems[identifier] = new
				return new.uiViewController()
			}
			return nil
		}
	}
	
	open class Delegate: DynamicDelegate, UITabBarControllerDelegate {
		public required override init() {
			super.init()
		}

		open var didSelect: SignalInput<ItemIdentifier>?
		open func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
			if let identifier = (tabBarController.delegate as? Storage)?.identifier(for: viewController) {
				didSelect?.send(value: identifier)
			}
		}

		open var willBeginCustomizing: SignalInput<[ItemIdentifier]>?
		open func tabBarController(_ tabBarController: UITabBarController, willBeginCustomizing viewControllers: [UIViewController]) {
			if let storage = tabBarController.delegate as? Storage {
				willBeginCustomizing?.send(value: viewControllers.compactMap { storage.identifier(for: $0) })
			}
		}

		open var didBeginCustomizing: SignalInput<[ItemIdentifier]>?
		open func tabBarController(_ tabBarController: UITabBarController, didBeginCustomizing viewControllers: [UIViewController]) {
			if let storage = tabBarController.delegate as? Storage {
				didBeginCustomizing?.send(value: viewControllers.compactMap { storage.identifier(for: $0) })
			}
		}

		open var willEndCustomizing: SignalInput<([ItemIdentifier], Bool)>?
		open func tabBarController(_ tabBarController: UITabBarController, willEndCustomizing viewControllers: [UIViewController], changed: Bool) {
			if let storage = tabBarController.delegate as? Storage {
				willEndCustomizing?.send(value: (viewControllers.compactMap { storage.identifier(for: $0) }, changed))
			}
		}

		open var didEndCustomizing: SignalInput<([ItemIdentifier], Bool)>?
		open func tabBarController(_ tabBarController: UITabBarController, didEndCustomizing viewControllers: [UIViewController], changed: Bool) {
			if let storage = tabBarController.delegate as? Storage {
				didEndCustomizing?.send(value: (viewControllers.compactMap { storage.identifier(for: $0) }, changed))
			}
		}
		
		open var shouldSelect: ((ItemIdentifier) -> Bool)?
		open func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
			if let storage = tabBarController.delegate as? Storage, let identifier = storage.identifier(for: viewController) {
				return shouldSelect!(identifier)
			}
			return false
		}
		
		open var supportedInterfaceOrientations: (() -> UIInterfaceOrientationMask)?
		open func tabBarControllerSupportedInterfaceOrientations(_ tabBarController: UITabBarController) -> UIInterfaceOrientationMask {
			return supportedInterfaceOrientations!()
		}
		
		open var preferredInterfaceOrientationForPresentation: (() -> UIInterfaceOrientation)?
		open func tabBarControllerPreferredInterfaceOrientationForPresentation(_ tabBarController: UITabBarController) -> UIInterfaceOrientation {
			return preferredInterfaceOrientationForPresentation!()
		}
		
		open var interactionControllerForAnimation: ((UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning?)?
		open func tabBarController(_ tabBarController: UITabBarController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
			return interactionControllerForAnimation!(animationController)
		}
		
		open var animationControllerForTransition: ((UIViewController, UIViewController) -> UIViewControllerAnimatedTransitioning?)?
		open func tabBarController(_ tabBarController: UITabBarController, animationControllerForTransitionFrom fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
			return animationControllerForTransition!(fromVC, toVC)
		}
	}
}

extension BindingName where Binding: TabBarControllerBinding {
	// You can easily convert the `Binding` cases to `BindingName` by copying them to here and using the following Xcode-style regex:
	// Find:    case ([^\(]+)\((.+)\)$
	// Replace: public static var $1: BindingName<$2, Binding> { return BindingName<$2, Binding>({ v in .tabBarControllerBinding(TabBarController<Binding.ItemIdentifierType>.Binding.$1(v)) }) }
	public static var tabBar: BindingName<Constant<TabBar<Binding.ItemIdentifierType>>, Binding> { return BindingName<Constant<TabBar<Binding.ItemIdentifierType>>, Binding>({ v in .tabBarControllerBinding(TabBarController<Binding.ItemIdentifierType>.Binding.tabBar(v)) }) }
	public static var items: BindingName<Dynamic<SetOrAnimate<[Binding.ItemIdentifierType]>>, Binding> { return BindingName<Dynamic<SetOrAnimate<[Binding.ItemIdentifierType]>>, Binding>({ v in .tabBarControllerBinding(TabBarController<Binding.ItemIdentifierType>.Binding.items(v)) }) }
	public static var customizableItems: BindingName<Dynamic<Set<Binding.ItemIdentifierType>>, Binding> { return BindingName<Dynamic<Set<Binding.ItemIdentifierType>>, Binding>({ v in .tabBarControllerBinding(TabBarController<Binding.ItemIdentifierType>.Binding.customizableItems(v)) }) }
	public static var selectItem: BindingName<Signal<Binding.ItemIdentifierType>, Binding> { return BindingName<Signal<Binding.ItemIdentifierType>, Binding>({ v in .tabBarControllerBinding(TabBarController<Binding.ItemIdentifierType>.Binding.selectItem(v)) }) }
	public static var didSelect: BindingName<SignalInput<Binding.ItemIdentifierType>, Binding> { return BindingName<SignalInput<Binding.ItemIdentifierType>, Binding>({ v in .tabBarControllerBinding(TabBarController<Binding.ItemIdentifierType>.Binding.didSelect(v)) }) }
	public static var willBeginCustomizing: BindingName<SignalInput<[Binding.ItemIdentifierType]>, Binding> { return BindingName<SignalInput<[Binding.ItemIdentifierType]>, Binding>({ v in .tabBarControllerBinding(TabBarController<Binding.ItemIdentifierType>.Binding.willBeginCustomizing(v)) }) }
	public static var willEndCustomizing: BindingName<SignalInput<([Binding.ItemIdentifierType], Bool)>, Binding> { return BindingName<SignalInput<([Binding.ItemIdentifierType], Bool)>, Binding>({ v in .tabBarControllerBinding(TabBarController<Binding.ItemIdentifierType>.Binding.willEndCustomizing(v)) }) }
	public static var didEndCustomizing: BindingName<SignalInput<([Binding.ItemIdentifierType], Bool)>, Binding> { return BindingName<SignalInput<([Binding.ItemIdentifierType], Bool)>, Binding>({ v in .tabBarControllerBinding(TabBarController<Binding.ItemIdentifierType>.Binding.didEndCustomizing(v)) }) }
	public static var tabConstructor: BindingName<(Binding.ItemIdentifierType) -> ViewControllerConvertible, Binding> { return BindingName<(Binding.ItemIdentifierType) -> ViewControllerConvertible, Binding>({ v in .tabBarControllerBinding(TabBarController<Binding.ItemIdentifierType>.Binding.tabConstructor(v)) }) }
	public static var shouldSelect: BindingName<(Binding.ItemIdentifierType) -> Bool, Binding> { return BindingName<(Binding.ItemIdentifierType) -> Bool, Binding>({ v in .tabBarControllerBinding(TabBarController<Binding.ItemIdentifierType>.Binding.shouldSelect(v)) }) }
	public static var supportedInterfaceOrientations: BindingName<() -> UIInterfaceOrientationMask, Binding> { return BindingName<() -> UIInterfaceOrientationMask, Binding>({ v in .tabBarControllerBinding(TabBarController<Binding.ItemIdentifierType>.Binding.supportedInterfaceOrientations(v)) }) }
	public static var preferredInterfaceOrientationForPresentation: BindingName<() -> UIInterfaceOrientation, Binding> { return BindingName<() -> UIInterfaceOrientation, Binding>({ v in .tabBarControllerBinding(TabBarController<Binding.ItemIdentifierType>.Binding.preferredInterfaceOrientationForPresentation(v)) }) }
	public static var interactionControllerForAnimation: BindingName<(UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning?, Binding> { return BindingName<(UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning?, Binding>({ v in .tabBarControllerBinding(TabBarController<Binding.ItemIdentifierType>.Binding.interactionControllerForAnimation(v)) }) }
	public static var animationControllerForTransition: BindingName<(UIViewController, UIViewController) -> UIViewControllerAnimatedTransitioning?, Binding> { return BindingName<(UIViewController, UIViewController) -> UIViewControllerAnimatedTransitioning?, Binding>({ v in .tabBarControllerBinding(TabBarController<Binding.ItemIdentifierType>.Binding.animationControllerForTransition(v)) }) }
}

public protocol TabBarControllerConvertible {
	func uiTabBarController() -> UITabBarController
}
extension TabBarControllerConvertible {
	public func uiViewController() -> ViewController.Instance { return uiTabBarController() }
}
extension TabBarController.Instance: TabBarControllerConvertible {
	public func uiTabBarController() -> UITabBarController { return self }
}

public protocol TabBarControllerBinding: ViewControllerBinding {
	associatedtype ItemIdentifierType: Hashable
	static func tabBarControllerBinding(_ binding: TabBarController<ItemIdentifierType>.Binding) -> Self
}
extension TabBarControllerBinding {
	public static func viewControllerBinding(_ binding: ViewController.Binding) -> Self {
		return tabBarControllerBinding(.inheritedBinding(binding))
	}
}
