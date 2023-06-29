//
//  CustomUserDefaults+Keys.swift
//

import Foundation

enum UserDefaultsKey: String {
    case sensorLightning
    case sensorID
}

extension CustomUserDefaults {
    
    subscript<T: Codable>(key: UserDefaultsKey) -> T? {
        get {
            return object(T.self, with: key.rawValue)
        }
        set {
            set(object: newValue, forKey: key.rawValue)
        }
    }
}

// UserDefaultsKey
extension CustomUserDefaults {
    func data(for key: UserDefaultsKey) -> Data? {
        data(for: key.rawValue)
    }
    
    func set(_ value: Any, for key: UserDefaultsKey) {
        set(value, forKey: key.rawValue)
    }
    
    func bool(for key: UserDefaultsKey) -> Bool {
        bool(for: key.rawValue)
    }
    
    func string(for key: UserDefaultsKey) -> String? {
        string(for: key.rawValue)
    }
    
    func integer(for key: UserDefaultsKey) -> Int? {
        integer(for: key.rawValue)
    }
    
    func float(for key: UserDefaultsKey) -> Float? {
        float(for: key.rawValue)
    }
    
    func url(for key: UserDefaultsKey) -> URL? {
        url(for: key.rawValue)
    }
    
    /// Retrieves a Codable object from UserDefaults.
    ///
    /// - Parameters:
    ///   - type: Class that conforms to the Codable protocol.
    ///   - key: Identifier of the object.
    ///   - decoder: Custom JSONDecoder instance. Defaults to `JSONDecoder()`.
    /// - Returns: Codable object for key (if exists).
    func object<T: Codable>(_ type: T.Type, with key: UserDefaultsKey, usingDecoder decoder: JSONDecoder = JSONDecoder()) -> T? {
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
    func set<T: Codable>(object: T, forKey key: UserDefaultsKey, usingEncoder encoder: JSONEncoder = JSONEncoder()) {
        let data = try? encoder.encode(object)
        set(data, forKey: key.rawValue)
    }
}

extension UserDefaults {
    func set(_ value: Any, for key: UserDefaultsKey) {
        set(value, forKey: key.rawValue)
    }

    func bool(for key: UserDefaultsKey) -> Bool {
        bool(forKey: key.rawValue)
    }

    func data(for key: UserDefaultsKey) -> Data? {
        data(forKey: key.rawValue)
    }

    func string(for key: UserDefaultsKey) -> String? {
        string(forKey: key.rawValue)
    }

    func integer(for key: UserDefaultsKey) -> Int? {
        integer(forKey: key.rawValue)
    }

    func float(for key: UserDefaultsKey) -> Float? {
        float(forKey: key.rawValue)
    }

    func url(for key: UserDefaultsKey) -> URL? {
        url(forKey: key.rawValue)
    }

    func value(for key: UserDefaultsKey) -> Any? {
        value(forKey: key.rawValue)
    }
}

extension UserDefaults {

    subscript(key: String) -> Any? {
        get {
            return object(forKey: key)
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
        guard let data = value(forKey: key) as? Data else {
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

