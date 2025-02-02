//
//  Injection.swift
//  RestSync
//
//  Created by Rahul Pawar on 1/7/25.
//

import SwiftUI
import Swinject

final class Injection {
    static let shared = Injection()
    var container: Container {
        get {
            if _container == nil {
                _container = buildContainer()
            }
            return _container!
        }
        
        set {
            _container = newValue
        }
    }
    
    private var _container: Container?
    
    // Register global level dependencies here
    private func buildContainer() -> Container {
        let container = Container()
        //TimerManager container registration
        container.register(TimerManager.self) { _ in
            TimerManager.shared
        }.inObjectScope(.container)
        
        //LaunchAtLogin container registration
        container.register(LaunchAtLogin.self) { _ in
            LaunchAtLogin.shared
        }.inObjectScope(.container)
        
        //EventChecker container registration
        container.register(EventChecker.self) { _ in
            EventChecker.shared
        }.inObjectScope(.container)
        
        return container
    }
}

@propertyWrapper struct Injected<Dependency> {
    let wrappedValue: Dependency
    
    init() {
        self.wrappedValue = Injection.shared.container.resolve(Dependency.self)! // We are force unwrapping this to insure the dependency is registered always before use
    }
}

