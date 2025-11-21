//
//  RankingViewModel.swift
//  MParty
//
//  Created by user285805 on 7/11/25.
//

import Foundation
import FirebaseFirestore
import Combine
import FirebaseAuth

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
            
            var query: Query = db.collection("users")
            query = query.whereField("role", isEqualTo: "Jugador")
            
            switch filter {
            case .global: break
            case .national(let country):
                query = query.whereField("pais", isEqualTo: country)
            }
            
            query = query.order(by: "xp", descending: true)
            query = query.limit(to: 50)
            
            do {
                let snapshot = try await query.getDocuments()
                
                self.users = snapshot.documents.compactMap { doc in
                    let data = doc.data()
                    let uid = doc.documentID
                    return User(uid: uid, dictionary: data)
                }
                
                // --- NUEVO: Actualizar el ranking del usuario actual en Firebase ---
                // Obtenemos el ID del usuario actual
                if let currentUserID = Auth.auth().currentUser?.uid {
                    // Buscamos en qué posición quedó en la lista que acabamos de bajar
                    if let index = self.users.firstIndex(where: { $0.id == currentUserID }) {
                        let newRank = index + 1
                        
                        // Solo actualizamos si el ranking cambió para ahorrar escrituras
                        // (Nota: Esto es una simplificación, idealmente verificaríamos el valor anterior)
                        try? await db.collection("users").document(currentUserID).updateData([
                            "globalRank": newRank
                        ])
                    }
                }
                // ------------------------------------------------------------------
                
            } catch {
                print("DEBUG: Falló al cargar ranking: \(error.localizedDescription)")
                self.errorMessage = "Error al cargar ranking."
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
