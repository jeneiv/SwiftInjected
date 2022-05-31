//
//  File.swift
//  
//
//  Created by Viktor Jenei on 2022. 05. 31..
//

import Foundation

/// Property wrapper that resolves dependencies when type instances are created.
///
///  Usage:
///
///     @Injected var memberName: MemberType
///
///  WHERE
///
///  memberName will be the wrapped property by which the dependency is accessible
///
///  MemberType refers to the type
@propertyWrapper
public struct Injected<DependencyType> {
    private var dependency: DependencyType
    private var resolver: Resolver

    public init(resolver: Resolver = Resolver.shared) {
        self.resolver = resolver
        // swiftlint:disable:next force_try
        dependency = try! resolver.injected()
    }

    public var wrappedValue: DependencyType {
        dependency
    }
}

/// Property wrapper that resolves dependencies when the property first accessed
///
///  Usage:
///
///     @LazyInjected var memberName: MemberType
@propertyWrapper
public struct LazyInjected<DependencyType> {
    private var resolver: Resolver

    public init(resolver: Resolver = Resolver.shared) {
        self.resolver = resolver
    }

    public lazy var wrappedValue: DependencyType = {
        // swiftlint:disable:next force_try
        try! resolver.injected()
    }()
}
