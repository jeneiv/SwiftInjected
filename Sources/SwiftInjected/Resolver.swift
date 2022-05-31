//
//  File.swift
//  
//
//  Created by Viktor Jenei on 2022. 05. 31..
//

import Foundation

/// Type that handles dependency Injection by using the `@Injected` and `@LazyInjected` property wrappers
public class Resolver {
    public enum ResolverError: Error {
        case unregisteredDependencyType(type: Any.Type)
    }

    public static let shared = Resolver()

    private var instances = [String: AnyObject]()
    private var factories = [String: () -> Any]()
    private var constructorFunctions = [String: () -> Any]()
    private var staticTypes = [String: Any.Type]()

    /**
     Registers shared instances to the DI container.
     
     - Parameters:
        - instance: the instance to be resolved
        - type: the type to resolve the instance against
        - override: flag that allows the DI container to overwrite dependencies if already registered
     */
    public func registerInstance<DependencyType: AnyObject, ServiceType>(_ instance: DependencyType, type: ServiceType.Type, override: Bool = false) {
        let key = String(describing: type.self).lastTypeSegment()
        removeDependencyIfOverwritten(type: type, overwritten: override)
        if !instances.keys.contains(key) || override {
            instances[key] = instance
        }
    }

    /**
     Registers closures to create dependencies.
     Factory closures are executed every time when a client asks for a dependency.
     
     - Parameters:
        - factory: Any closure that returns an instance for its return value
        - override: flag that allows the DI container to overwrite dependencies if already registered
     */
    public func registerFactory<DependencyType>(_ factory: @escaping () -> DependencyType, override: Bool = false) {
        let key = String(describing: DependencyType.self).lastTypeSegment()
        removeDependencyIfOverwritten(type: DependencyType.self, overwritten: override)
        if !factories.keys.contains(key) || override {
            factories[key] = factory
        }
    }

    /**
     Registers function pointers to create dependencies.
     Constructor functions are called every time when a client asks for a dependency.
     
     - Parameters:
        - constructor: the constructor function to be added to the DI container
        - type: the type to resolve the instance against
        - override: flag that allows the DI container to overwrite dependencies if already registered
     */
    public func registerConstructor<DependencyType: Any, ServiceType>(_ constructor: @escaping () -> DependencyType, type: ServiceType.Type, override: Bool = false) {
        let key = String(describing: type.self).lastTypeSegment()
        removeDependencyIfOverwritten(type: type, overwritten: override)
        if !constructorFunctions.keys.contains(key) || override {
            constructorFunctions[key] = constructor
        }
    }

    public func register<ServiceType>(staticType: Any.Type, for type: ServiceType.Type, override: Bool = false) {
        let key = String(describing: type.self).lastTypeSegment() + ".Type"
        if !staticTypes.keys.contains(key) || override {
            staticTypes[key] = staticType
        }
    }

    func injected<DependencyType>() throws -> DependencyType {
        let key = String(describing: DependencyType.self).lastTypeSegment()
        if let constructorFunction = constructorFunctions[key], let dependency = constructorFunction() as? DependencyType {
            return dependency
        } else if let dependencyFactory = factories[key], let dependency = dependencyFactory() as? DependencyType {
            return dependency
        } else if let dependency = instances[key] as? DependencyType {
            return dependency
        } else if let dependency = staticTypes[key] as? DependencyType {
            return dependency
        }
        throw ResolverError.unregisteredDependencyType(type: DependencyType.self)
    }

    private func removeDependencyIfOverwritten<ServiceType>(type: ServiceType.Type, overwritten: Bool) {
        guard overwritten == true else { return }
        let key = String(describing: type.self)
        instances.removeValue(forKey: key)
        factories.removeValue(forKey: key)
        constructorFunctions.removeValue(forKey: key)
        staticTypes.removeValue(forKey: key)
    }
}

fileprivate extension String {
    func lastTypeSegment() -> String {
        guard let lastSeparatorIndex = self.lastIndex(of: ".") else {
            return self
        }
        let range = self.index(after: lastSeparatorIndex) ..< self.endIndex
        return String(self[range])
    }
}
