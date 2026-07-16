//
//  MatchStore.swift
//  CalendarMundial
//

import Foundation
import Observation

// MARK: - MatchStore

/// Almacén observable que mantiene los partidos en memoria, los cachea localmente
/// y permite refrescarlos desde un JSON remoto.
///
/// La carga sigue tres fuentes en cascada:
/// 1. Caché en `UserDefaults` si existe (instant load al arrancar).
/// 2. Datos integrados en `MundialData.matchDays` si no hay caché.
/// 3. JSON remoto descargado de `remoteURL` cuando hay conexión.
///
/// El refresh remoto sobrescribe los datos en memoria y guarda el snapshot en
/// caché para la próxima ejecución.
@MainActor
@Observable
final class MatchStore {

    // MARK: Estado observable

    /// Lista vigente de jornadas mostrada en la UI.
    var matchDays: [MatchDay]

    /// `true` mientras hay una petición de refresh en curso.
    var isRefreshing: Bool = false

    /// Fecha de la última actualización remota satisfactoria.
    var lastUpdated: Date?

    /// Descripción del último error de red (`nil` si la última operación fue OK).
    var lastError: String?

    // MARK: Configuración

    /// URL del JSON remoto con la estructura de `MatchSnapshot`.
    ///
    /// Apunta al repositorio público `calendar-mundial-2026`. El workflow
    /// `.github/workflows/update-mundial.yml` regenera `data/mundial2026.json`
    /// cada 30 minutos consultando la API pública de ESPN y haciendo commit
    /// automático. La app sólo necesita descargar este JSON — cero
    /// intervención manual de aquí en adelante.
    static let remoteURL: URL? = URL(
        string: "https://raw.githubusercontent.com/cornellana/calendar-mundial-2026/refs/heads/main/data/mundial2026.json"
    )

    /// Clave bajo la que se persiste el snapshot en `UserDefaults`.
    private static let cacheKey = "mundial2026_cache_v2"

    // MARK: Inicialización

    init() {
        if let cached = Self.loadCache() {
            self.matchDays = cached.matchDays
            self.lastUpdated = cached.lastUpdated
        } else {
            // Sin caché: arrancamos con los datos integrados en el bundle.
            self.matchDays = MundialData.matchDays
            self.lastUpdated = nil
        }
    }

    // MARK: Refresh remoto

    /// Refresca los datos descargando el JSON remoto configurado en `remoteURL`.
    ///
    /// Si la URL no está configurada el método sale sin hacer nada. Si la
    /// petición falla, se conservan los datos actuales y se rellena `lastError`.
    func refresh() async {
        guard let url = Self.remoteURL else { return }

        isRefreshing = true
        defer { isRefreshing = false }

        do {
            // Anexa un timestamp como cache-buster: ni URLCache ni los CDN
            // intermedios (GitHub raw cachea 5 min) servirán versión vieja
            // porque la URL es diferente cada vez.
            let cacheBustedURL = url.appending(queryItems: [
                URLQueryItem(name: "t", value: String(Int(Date().timeIntervalSince1970)))
            ])
            var request = URLRequest(url: cacheBustedURL)
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            request.timeoutInterval = 15
            request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let snapshot = try decoder.decode(MatchSnapshot.self, from: data)

            self.matchDays = snapshot.matchDays
            self.lastUpdated = snapshot.lastUpdated ?? Date()
            self.lastError = nil

            Self.saveCache(snapshot)
        } catch {
            self.lastError = error.localizedDescription
        }
    }

    // MARK: Caché local

    /// Lee el último snapshot persistido en `UserDefaults`.
    private static func loadCache() -> MatchSnapshot? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(MatchSnapshot.self, from: data)
    }

    /// Persiste el snapshot en `UserDefaults`.
    private static func saveCache(_ snapshot: MatchSnapshot) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: cacheKey)
    }
}
