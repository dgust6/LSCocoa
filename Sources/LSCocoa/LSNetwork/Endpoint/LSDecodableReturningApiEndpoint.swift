//
//  DecodableReturningApiEndpoint.swift
//  
//
//  Created by Dino Gustin on 24.01.2023..
//

import LSData

public protocol DecodableReturningApiEndpoint: ApiEndpoint {
    associatedtype ReturnDecodable: Decodable
}

extension DecodableReturningApiEndpoint {
    public func createDecodingDataSource() -> LSOutputMappingDataSource<LSAPINetworkDataSource, LSJsonDecodingMapper<ReturnDecodable>> {
        createDataSource().jsonDecodeMap(to: ReturnDecodable.self)
    }
}
