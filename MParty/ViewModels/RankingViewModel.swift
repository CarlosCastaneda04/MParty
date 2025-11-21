//
//  RankingViewModel.swift
//  MParty
//
//  Created by user285805 on 7/11/25.
//

import Foundation
import FirebaseFirestore
import Combine

@MainActor
class RankingViewModel: ObservableObject {
    
    @Published var users: [User] = []
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    private var db = Firestore.firestore()
    
    func fetchRankings(filter: RankingFilter) async {
        self.isLoading = true
        self.users = []
        self.errorMessage = nil
        
        // 1. Empezamos la consulta a la colección 'users'
        var query: Query = db.collection("users")
        
        // 2. FILTRO CLAVE: Solo mostramos "Jugadores"
        // (Asegúrate de que en Firebase el rol esté guardado como "Jugador" o "player")
        // Si usas "Jugador" en el registro, déjalo así. Si usas "player", cámbialo.
        query = query.whereField("role", isEqualTo: "Jugador")
        
        // --- Lógica de Filtros Geográficos ---
        switch filter {
        case .global:
            // No filtramos por país, traemos a todos los jugadores del mundo
            break
            
        case .national(let country):
            // Filtramos por el país del usuario actual
            query = query.whereField("pais", isEqualTo: country)
        }
        
        // 3. ORDENAMIENTO: El que tenga más XP va primero
        query = query.order(by: "xp", descending: true)
        query = query.limit(to: 50) // Top 50 para no sobrecargar
        
        do {
            let snapshot = try await query.getDocuments()
            
            self.users = snapshot.documents.compactMap { doc in
                let data = doc.data()
                let uid = doc.documentID
                var user = User(uid: uid, dictionary: data)
                
                // Asignamos el ranking basado en el orden de la lista (1, 2, 3...)
                // Esto es solo visual, no se guarda en la base de datos aquí
                // El índice 0 es el rank 1.
                return user
            }
            
        } catch {
            print("DEBUG: Falló al cargar ranking: \(error.localizedDescription)")
            // Nota: Si ves un error de "index", revisa la consola de Xcode,
            // Firebase te dará un link para crear el índice necesario automáticamente.
            self.errorMessage = "Error al cargar. Verifica tu conexión."
        }
        
        self.isLoading = false
    }
}

// --- Filtros Actualizados (Sin Local) ---
enum RankingFilter: Equatable {
    case global
    case national(String) // Ej. "MX" o "El Salvador"
    
    var title: String {
        switch self {
        case .global: return "Global"
        case .national: return "Nacional"
        }
    }
}
