//
//  Decodable.swift
//  CoreNetwork
//
//  Created by Karolis Misiūra on 17/09/2024.
//

import Alamofire
import Combine
import Dispatch
import Foundation

extension DataRequest {
    @available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
    public func publishDecodable<T: Decodable>(type: T.Type = T.self,
                                               queue: DispatchQueue = .main,
                                               preprocessor: DataPreprocessor = DecodableResponseSerializer<T>.defaultDataPreprocessor,
                                               decoder: DataDecoder = JSONDecoder(),
                                               emptyResponseCodes: Set<Int> = DecodableResponseSerializer<T>.defaultEmptyResponseCodes,
                                               emptyRequestMethods: Set<HTTPMethod> = DecodableResponseSerializer<T>.defaultEmptyRequestMethods) -> DataResponsePublisher<T> {
        publishResponse(using: DecodableResponseSerializer(dataPreprocessor: preprocessor,
                                                           decoder: decoder,
                                                           emptyResponseCodes: emptyResponseCodes,
                                                           emptyRequestMethods: emptyRequestMethods),
                        on: queue)
    }
}
