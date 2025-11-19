//
//  EventViewModel.swift
//  MParty
//
//  Created by user285805 on 7/11/25.
//

import Foundation
import Combine
import FirebaseFirestore

@MainActor
class EventViewModel: ObservableObject {
    
    @Published var events: [Event] = [] // Para la lista "Cerca de Ti"
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    private var db = Firestore.firestore()
    
    // --- FUNCIÓN PARA CREAR UN EVENTO ---
    func createEvent(
        title: String,
        description: String,
        gameType: String,
        eventDate: Date,
        location: String,
        mode: String,
        maxPlayers: Int,
        isPaidEvent: Bool,
        host: User // Recibe al usuario que lo está creando
    ) async -> Bool { // Devuelve 'true' si tuvo éxito
        
        isLoading = true
        errorMessage = nil
        
        // 1. Prepara los datos del evento
        let eventData: [String: Any] = [
            "title": title,
            "description": description,
            "gameType": gameType,
            "eventDate": Timestamp(date: eventDate), // Convierte la Fecha a Timestamp
            "location": location,
            "mode": mode,
            "maxPlayers": maxPlayers,
            "isPaidEvent": isPaidEvent,
            "status": "Disponible", // Estado inicial
            "hostId": host.id ?? "",
            "hostName": host.displayName,
            "eventBannerURL": NSNull(), // Sin banner al crear (se puede añadir después)
            "entryFee": NSNull()
        ]
        
        // 2. Guarda en Firebase
        do {
            try await db.collection("events").addDocument(data: eventData)
            isLoading = false
            return true // Éxito
        } catch {
            print("DEBUG: Falló al crear el evento: \(error.localizedDescription)")
            errorMessage = "Error al guardar el torneo."
            isLoading = false
            return false // Falla
        }
    }
    
    // --- FUNCIÓN PARA LEER LOS EVENTOS ---
    func fetchEvents() async {
        isLoading = true
        self.events = [] // Limpia la lista
        
        do {
            let query = db.collection("events")
                .order(by: "eventDate", descending: true) // Ordena por fecha
                .limit(to: 20) // Trae los 20 más nuevos
            
            let snapshot = try await query.getDocuments()
            
            // Usa el 'init' manual que creamos en Event.swift
            self.events = snapshot.documents.compactMap { doc in
                let data = doc.data()
                let id = doc.documentID
                return Event(documentId: id, dictionary: data)
            }
            
        } catch {
            print("DEBUG: Falló al leer eventos: \(error.localizedDescription)")
            errorMessage = "No se pudieron cargar los eventos."
        }
        
        isLoading = false
    }
}
