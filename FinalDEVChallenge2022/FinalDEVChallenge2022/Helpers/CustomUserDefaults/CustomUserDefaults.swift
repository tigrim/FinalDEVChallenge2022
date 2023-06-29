//
//  CustomUserDefaults.swift
//
//

import Foundation

extension UserDefaults {
    static let user = CustomUserDefaults(withIdentifier: "id")
}

class CustomUserDefaults {
    fileprivate let standard = UserDefaults.standard
    fileprivate var userDefaults = [String: Any]()
    fileprivate var identifier: String
    
    init(withIdentifier identifier: String) {
        self.identifier = "userdefaults.identifier.\(identifier)"
        guard let defaults = standard.value(forKey: self.identifier) as? [String: Any] else {
            return
        }
        
        userDefaults = defaults
    }
    
    func updateIdentifier(identifier: String) {
        self.identifier = "userdefaults.identifier.\(identifier)"
    }
    
    func removeUser() {
        userDefaults.removeAll()
        standard.set(nil, forKey: identifier)
        standard.synchronize()
    }
    
    func synchronize() {
        standard.set(userDefaults, forKey: identifier)
        standard.synchronize()
    }
    
    // MARK: - Getter
    func data(for key: String) -> Data? {
        userDefaults[key] as? Data
    }
    
    func string(for key: String) -> String? {
        userDefaults[key] as? String
    }
    
    func bool(for key: String) -> Bool {
        userDefaults[key] as? Bool ?? false
    }
    
    func integer(for key: String) -> Int? {
        userDefaults[key] as? Int
    }
    
    func float(for key: String) -> Float? {
        userDefaults[key] as? Float
    }
    
    func url(for key: String) -> URL? {
        userDefaults[key] as? URL
    }
    
    func object(for key: String) -> Any? {
        userDefaults[key]
    }
    
    // MARK: - Setter
    
    func register(defaults: [String: Any]) {
        for (key, value) in defaults where userDefaults[key] == nil {
            userDefaults[key] = value
        }
        
        synchronize()
    }
    
    func set(_ value: Any?, forKey key: String) {
        userDefaults[key] = value
        synchronize()
    }
    
    func removeObject(key: String) {
        userDefaults[key] = nil
        synchronize()
    }
}

extension CustomUserDefaults {
    
    subscript(key: String) -> Any? {
        get {
            return object(for: key)
        }
        set {
            set(newValue, forKey: key)
        }
    }
    
    /// Retrieves a Codable object from UserDefaults.
    ///
    /// - Parameters:
    ///   - type: Class that conforms to the Codable protocol.
    ///   - key: Identifier of the object.
    ///   - decoder: Custom JSONDecoder instance. Defaults to `JSONDecoder()`.
    /// - Returns: Codable object for key (if exists).
    func object<T: Codable>(_ type: T.Type, with key: String, usingDecoder decoder: JSONDecoder = JSONDecoder()) -> T? {
        guard let data = data(for: key) else {
            return nil
        }
        return try? decoder.decode(type.self, from: data)
    }
    
    /// Allows storing of Codable objects to UserDefaults.
    ///
    /// - Parameters:
    ///   - object: Codable object to store.
    ///   - key: Identifier of the object.
    ///   - encoder: Custom JSONEncoder instance. Defaults to `JSONEncoder()`.
    func set<T: Codable>(object: T, forKey key: String, usingEncoder encoder: JSONEncoder = JSONEncoder()) {
        let data = try? encoder.encode(object)
        set(data, forKey: key)
    }
}
