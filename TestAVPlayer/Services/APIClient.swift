import Foundation
import XMLCoder

// MARK: APIClientProvider

protocol APIClientProvider: Sendable {
    func fetch<Model: Sendable>(_ request: URLRequest) async throws -> Model where Model: Decodable
    func fetch(_ request: URLRequest) async throws -> Data
}

// MARK: APIClient

struct APIClient: APIClientProvider {
    init(keyDecodingStrategy: XMLDecoder.KeyDecodingStrategy = .useDefaultKeys, dateDecodingStrategy: XMLDecoder.DateDecodingStrategy = .iso8601, urlSession: any URLSessionProvider = URLSession.shared) {
        self.urlSession = urlSession
        self.keyDecodingStrategy = keyDecodingStrategy
        self.dateDecodingStrategy = dateDecodingStrategy
    }

    let urlSession: URLSessionProvider
    let keyDecodingStrategy: XMLDecoder.KeyDecodingStrategy
    let dateDecodingStrategy: XMLDecoder.DateDecodingStrategy

    func fetch<Model: Sendable>(_ request: URLRequest) async throws -> Model where Model: Decodable {
        let decoder = XMLDecoder()
        decoder.keyDecodingStrategy = keyDecodingStrategy
        return try decoder.decode(Model.self, from: await fetch(request))
    }

    func fetch(_ request: URLRequest) async throws -> Data {
        let (data, _) = try await urlSession.data(for: request)
        return data
    }
}

// MARK: Nested models

extension APIClient {
    enum APIClientError: Error {
        case unknownResponse
    }
}

// MARK: Dependency extensions

extension XMLDecoder.KeyDecodingStrategy: @unchecked Sendable {}
extension XMLDecoder.DateDecodingStrategy: @unchecked Sendable {}

protocol URLSessionProvider: Sendable {
    func data(for request: URLRequest, delegate: (any URLSessionTaskDelegate)?) async throws -> (Data, URLResponse)
}

extension URLSessionProvider {
    func data(for request: URLRequest, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> (Data, URLResponse) {
        try await data(for: request, delegate: delegate)
    }
}

extension URLSession: URLSessionProvider {}
