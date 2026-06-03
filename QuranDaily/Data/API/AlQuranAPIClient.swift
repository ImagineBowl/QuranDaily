//
//  AlQuranAPIClient.swift
//  QuranDaily
//
//  Created by Ahsan Minhas on 30/05/2026.
//

import Foundation

final class AlQuranAPIClient: APIClientProtocol, Sendable {
    private let baseURL = URL(string: "https://api.alquran.cloud/v1")!
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchArabicQuran() async throws -> QuranEditionResponse {
        try await fetchEdition(named: "quran-uthmani")
    }

    func fetchUrduTranslation() async throws -> QuranEditionResponse {
        try await fetchEdition(named: "ur.jalandhry")
    }

    func fetchMeta() async throws -> MetaResponse {
        let url = baseURL.appendingPathComponent("meta")
        return try await performRequest(url: url)
    }

    func surahAudioURL(for surahNumber: Int) -> URL {
        URL(string: "https://cdn.islamic.network/quran/audio-surah/128/ar.alafasy/\(surahNumber).mp3")!
    }

    func ayahAudioURL(forAbsoluteNumber number: Int) -> URL {
        URL(string: "https://cdn.islamic.network/quran/audio/128/ar.alafasy/\(number).mp3")!
    }

    private func fetchEdition(named edition: String) async throws -> QuranEditionResponse {
        let url = baseURL.appendingPathComponent("quran/\(edition)")
        return try await performRequest(url: url)
    }

    private func performRequest<T: Decodable>(url: URL) async throws -> T {
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw QuranError.invalidResponse
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw QuranError.invalidResponse
        }
    }
}
