//
//  RankingViewModel.swift
//  MParty
//
//  Created by user285805 on 7/11/25.
//

import Foundation
import FirebaseFirestore // ¡Importante!
import Combine // <-- ¡ESTA ERA LA LÍNEA QUE FALTABA!
// 1. Usamos 'MainActor' para asegurar que
//    los cambios de 'users' se publiquen en el hilo principal
@MainActor
class RankingViewModel: ObservableObject {
    
    // 2. Aquí guardaremos la lista de usuarios del ranking
    @Published var users: [User] = []
    
    // 3. Para mostrar un error si falla
    @Published var errorMessage: String?
    
    private var db = Firestore.firestore()
    
    // 4. Esta función carga los datos
    func fetchRankings(filter: RankingFilter) async {
        self.users = [] // Limpia la lista anterior
        self.errorMessage = nil
        
        // 5. 'query' es la variable que contendrá la consulta a Firebase
        var query: Query = db.collection("users")
        
        // --- Lógica de Filtros ---
        // (Por ahora, 'Nacional' y 'Local' son placeholders,
        // pero la base ya está lista)
        
        switch filter {
        case .global:
            // Ordena por 'level' (nivel) de mayor a menor
            query = query.order(by: "level", descending: true)
        
        case .national(let country):
            // Filtra por 'pais' Y ordena por 'level'
            query = query.whereField("pais", isEqualTo: country)
                         .order(by: "level", descending: true)
            
        case .local:
            // TODO: Implementar lógica de cercanía (más compleja)
            query = query.order(by: "level", descending: true)
        }
        
        // 6. Limita los resultados a los 100 mejores
        query = query.limit(to: 100)
        
        // --- Ejecutar la Consulta ---
        do {
            let snapshot = try await query.getDocuments()
            
            // 7. Traduce los documentos de Firebase a nuestro 'struct User'
            //    usando el 'init(uid:dictionary:)' que creamos.
            self.users = snapshot.documents.compactMap { doc in
                let data = doc.data()
                let uid = doc.documentID
                return User(uid: uid, dictionary: data)
            }
            
        } catch {
            print("DEBUG: Falló al cargar el ranking: \(error.localizedDescription)")
            self.errorMessage = "No se pudo cargar el ranking."
        }
    }
}

// Un 'enum' simple para manejar los filtros
enum RankingFilter: Equatable {
    case global
    case national(String) // Ej. "El Salvador"
    case local // (A futuro)
}
