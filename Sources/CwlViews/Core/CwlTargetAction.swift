//
//  CwlTargetAction.swift
//  CwlViews
//
//  Created by Matt Gallagher on 2017/03/23.
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

/// This type encapsulates the idea that target-action pairs in Cocoa may target a specific object (by setting the target to non-nil) or may let the responder chain search for a responder that handles a specific selector.
public enum TargetAction {
	case firstResponder(Selector)
	case singleTarget(SignalInput<Any?>)
}

public protocol TargetActionSender: class {
	var action: Selector? { get set }
	var target: AnyObject? { get set }
}

extension TargetAction {
	public func apply<Source: TargetActionSender, Value>(instance: Source, constructTarget: () -> SignalActionTarget, processor: @escaping (Any?) -> Value) -> Lifetime? {
		switch self {
		case .firstResponder(let s):
			instance.target = nil
			instance.action = s
			return nil
		case .singleTarget(let s):
			let target = constructTarget()
			instance.target = target
			instance.action = SignalActionTarget.selector
			return target.signal.map(processor).cancellableBind(to: s)
		}
	}
}
