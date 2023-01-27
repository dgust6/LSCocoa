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
    public func createDataSource() -> OutputMappingDataSource<APINetworkDataSource<Self>, JsonDecodingMapper<ReturnDecodable>> {
        createDataSource().jsonDecodeMap(to: ReturnDecodable.self)
    }
}
