//
//  UserDefaultsItemRepositoryTests.swift
//  
//
//  Created by Dino Gustin on 21.07.2023..
//

import XCTest
import Combine
@testable import LSCocoa

final class UserDefaultsItemRepositoryTests: XCTestCase {
    
    struct MockItem: Codable, Equatable {
        let name: String
    }
    
    let mockItem1 = MockItem(name: "1")
    let mockItem2 = MockItem(name: "2")
    
    var repository: UserDefaultsItemRepository<[MockItem]>!
    var cancelBag: Set<AnyCancellable>!
    
    override func setUp() {
        repository = UserDefaultsItemRepository<[MockItem]>()
        cancelBag = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        repository.store([])
//        repository = nil
//        cancelBag = nil
    }
    
    func testAdd() throws {
        let expectation = expectation(description: "testAdd")
        repository.store([mockItem1])
        repository.publisher()
            .sink { items in
                if let items = items, items.contains(where: { $0 == self.mockItem2 }) {
                    expectation.fulfill()
                }
            }.store(in: &cancelBag)
        repository.store([mockItem1, mockItem2])
        waitForExpectations(timeout: 3)
    }
    
    func testComplexOperations() throws {
        let expectation = expectation(description: "testComplexOperations")
        repository.store([mockItem1])
        var operationCount = 0
        repository.publisher()
            .sink { items in
                switch operationCount {
                case 0:
                    break
                case 1:
                    XCTAssertTrue(items?.count == 2)
                case 2:
                    XCTAssertTrue(items?.count == 1)
                case 3:
                    XCTAssertTrue(items?.count == 0)
                case 4:
                    XCTAssertTrue(items?.count == 2)
                    expectation.fulfill()
                default:
                    break
                }
                operationCount += 1
            }.store(in: &cancelBag)
        repository.store([mockItem1, mockItem2])
        repository.store([mockItem2])
        repository.store([])
        repository.store([mockItem2, mockItem1])
        waitForExpectations(timeout: 3)
    }
}
