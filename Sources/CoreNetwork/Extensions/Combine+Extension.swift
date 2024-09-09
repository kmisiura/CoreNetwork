//
//  AnyPublisher.swift
//
//
//  Created by Karolis Misiūra on 08/09/2024.
//

import Combine

public enum AsyncError: Error {
    case finishedWithoutValue
}

public extension AnyPublisher {
    public func async() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            var finishedWithoutValue = true
            cancellable = first()
                .sink { result in
                    switch result {
                        case .finished:
                            if finishedWithoutValue {
                                continuation.resume(throwing: AsyncError.finishedWithoutValue)
                            }
                        case let .failure(error):
                            continuation.resume(throwing: error)
                    }
                    cancellable?.cancel()
                } receiveValue: { value in
                    finishedWithoutValue = false
                    continuation.resume(with: .success(value))
                }
        }
    }
}
