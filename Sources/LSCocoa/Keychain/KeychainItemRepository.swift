//
//  File.swift
//  
//
//  Created by Dino Gustin on 21.03.2022..
//

import Foundation
import LSData
import Combine
import Security

public class KeychainItemRepository<T: Codable>: NSObject, DataBasicRepository, DeletableStorage {

    public typealias Output = T?
    public typealias StoredItem = T?
    public typealias OutputError = Never
    
    let itemKey: String
    
    private let subject: CurrentValueSubject<T?, Never>
    
    public init(itemKey: String) {
        self.itemKey = itemKey
        subject = CurrentValueSubject<T?, Never>(nil)
        super.init()
        subject.send(storedItem)
    }
    
    public func store(_ item: T?) {
        guard let itemData = try? JSONEncoder().encode(item) else { return }
        let query = [
            kSecClass as String       : kSecClassGenericPassword as String,
            kSecAttrAccount as String : itemKey,
            kSecValueData as String   : itemData ] as [String : Any]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
        subject.send(item)
    }
    
    public var storedItem: T? {
        let query = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : itemKey,
            kSecReturnData as String  : kCFBooleanTrue!,
            kSecMatchLimit as String  : kSecMatchLimitOne ] as [String : Any]

        var dataTypeRef: AnyObject? = nil

        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == noErr, let data = dataTypeRef as? Data {
            return try? JSONDecoder().decode(T.self, from: data)
        } else {
            return nil
        }
    }
    
    public func publisher(parameter: ()) -> AnyPublisher<T?, Never> {
        subject.eraseToAnyPublisher()
    }
    
    public func delete(_ item: T?) {
        store(nil)
    }
    
    public func deleteAll() {
        store(nil)
    }
}
