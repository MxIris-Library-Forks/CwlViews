//
//  CwlGestureRecognizer_iOS.swift
//  CwlViews
//
//  Created by Matt Gallagher on 2017/03/26.
//  Copyright © 2017 Matt Gallagher ( https://www.cocoawithlove.com ). All rights reserved.
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

#if os(iOS)

extension BindingParser where Downcast: GestureRecognizerBinding {
	// You can easily convert the `Binding` cases to `BindingParser` using the following Xcode-style regex:
	// Replace: case ([^\(]+)\((.+)\)$
	// With:    public static var $1: BindingParser<$2, GestureRecognizer.Binding, Downcast> { return .init(extract: { if case .$1(let x) = \$0 { return x } else { return nil } }, upcast: { \$0.asGestureRecognizerBinding() }) }
	
	//	0. Static bindings are applied at construction and are subsequently immutable.
	
	// 1. Value bindings may be applied at construction and may subsequently change.
	public static var allowedPressTypes: BindingParser<Dynamic<[NSNumber]>, GestureRecognizer.Binding, Downcast> { return .init(extract: { if case .allowedPressTypes(let x) = $0 { return x } else { return nil } }, upcast: { $0.asGestureRecognizerBinding() }) }
	public static var allowedTouchTypes: BindingParser<Dynamic<[NSNumber]>, GestureRecognizer.Binding, Downcast> { return .init(extract: { if case .allowedTouchTypes(let x) = $0 { return x } else { return nil } }, upcast: { $0.asGestureRecognizerBinding() }) }
	public static var cancelsTouchesInView: BindingParser<Dynamic<Bool>, GestureRecognizer.Binding, Downcast> { return .init(extract: { if case .cancelsTouchesInView(let x) = $0 { return x } else { return nil } }, upcast: { $0.asGestureRecognizerBinding() }) }
	public static var delaysTouchesBegan: BindingParser<Dynamic<Bool>, GestureRecognizer.Binding, Downcast> { return .init(extract: { if case .delaysTouchesBegan(let x) = $0 { return x } else { return nil } }, upcast: { $0.asGestureRecognizerBinding() }) }
	public static var delaysTouchesEnded: BindingParser<Dynamic<Bool>, GestureRecognizer.Binding, Downcast> { return .init(extract: { if case .delaysTouchesEnded(let x) = $0 { return x } else { return nil } }, upcast: { $0.asGestureRecognizerBinding() }) }
	public static var requiresExclusiveTouchType: BindingParser<Dynamic<Bool>, GestureRecognizer.Binding, Downcast> { return .init(extract: { if case .requiresExclusiveTouchType(let x) = $0 { return x } else { return nil } }, upcast: { $0.asGestureRecognizerBinding() }) }
	
	// 2. Signal bindings are performed on the object after construction.
	
	// 3. Action bindings are triggered by the object after construction.
	public static var action: BindingParser<SignalInput<Any?>, GestureRecognizer.Binding, Downcast> { return .init(extract: { if case .action(let x) = $0 { return x } else { return nil } }, upcast: { $0.asGestureRecognizerBinding() }) }
	
	// 4. Delegate bindings require synchronous evaluation within the object's context.
	public static var shouldBegin: BindingParser<(UIGestureRecognizer) -> Bool, GestureRecognizer.Binding, Downcast> { return .init(extract: { if case .shouldBegin(let x) = $0 { return x } else { return nil } }, upcast: { $0.asGestureRecognizerBinding() }) }
	public static var shouldBeRequiredToFail: BindingParser<(UIGestureRecognizer, _ by: UIGestureRecognizer) -> Bool, GestureRecognizer.Binding, Downcast> { return .init(extract: { if case .shouldBeRequiredToFail(let x) = $0 { return x } else { return nil } }, upcast: { $0.asGestureRecognizerBinding() }) }
	public static var shouldReceivePress: BindingParser<(UIGestureRecognizer, UIPress) -> Bool, GestureRecognizer.Binding, Downcast> { return .init(extract: { if case .shouldReceivePress(let x) = $0 { return x } else { return nil } }, upcast: { $0.asGestureRecognizerBinding() }) }
	public static var shouldReceiveTouch: BindingParser<(UIGestureRecognizer, UITouch) -> Bool, GestureRecognizer.Binding, Downcast> { return .init(extract: { if case .shouldReceiveTouch(let x) = $0 { return x } else { return nil } }, upcast: { $0.asGestureRecognizerBinding() }) }
	public static var shouldRecognizeSimultanously: BindingParser<(UIGestureRecognizer, UIGestureRecognizer) -> Bool, GestureRecognizer.Binding, Downcast> { return .init(extract: { if case .shouldRecognizeSimultanously(let x) = $0 { return x } else { return nil } }, upcast: { $0.asGestureRecognizerBinding() }) }
	public static var shouldRequireFailure: BindingParser<(UIGestureRecognizer, _ of: UIGestureRecognizer) -> Bool, GestureRecognizer.Binding, Downcast> { return .init(extract: { if case .shouldRequireFailure(let x) = $0 { return x } else { return nil } }, upcast: { $0.asGestureRecognizerBinding() }) }
}

#endif
