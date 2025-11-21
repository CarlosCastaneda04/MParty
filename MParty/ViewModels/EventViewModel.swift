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
    
    @Published var events: [Event] = [] // Todos los eventos (para el Home)
    @Published var organizerEvents: [Event] = [] // Solo los eventos de ESTE organizador
    
    // --- Estadísticas del Organizador (Tarjetas Superiores) ---
    @Published var createdCount: Int = 0
    @Published var activeCount: Int = 0
    @Published var totalPlayersCount: Int = 0
    
    // --- Estadísticas del Organizador (Pestaña General - Barras de Progreso) ---
    @Published var successRate: Double = 0.0       // Tasa de Éxito
    @Published var averageAttendance: Double = 0.0 // Asistencia Promedio (Normalizada 0-1)
    @Published var activeRatio: Double = 0.0       // Proporción Activos/Totales
    
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    private var db = Firestore.firestore()
    
    // --- CREAR EVENTO ---
    func createEvent(title: String, description: String, gameType: String, eventDate: Date, location: String, mode: String, maxPlayers: Int, isPaidEvent: Bool, host: User) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        let eventData: [String: Any] = [
            "title": title,
            "description": description,
            "gameType": gameType,
            "eventDate": Timestamp(date: eventDate),
            "location": location,
            "mode": mode,
            "maxPlayers": maxPlayers,
            "isPaidEvent": isPaidEvent,
            "status": "Disponible",
            "hostId": host.id ?? "",
            "hostName": host.displayName,
            "eventBannerURL": NSNull(),
            "entryFee": NSNull(),
            "currentPlayers": 0 // Inicializa en 0
        ]
        
        do {
            try await db.collection("events").addDocument(data: eventData)
            isLoading = false
            // Recargar eventos para actualizar la lista inmediatamente
            await fetchEvents()
            return true
        } catch {
            print("DEBUG: Error al crear: \(error.localizedDescription)")
            errorMessage = "Error al guardar el torneo."
            isLoading = false
            return false
        }
    }
    
    // --- LEER EVENTOS ---
    func fetchEvents() async {
        isLoading = true
        self.events = []
        
        do {
            // 1. Trae TODOS los eventos (para el Home)
            let query = db.collection("events")
                .order(by: "eventDate", descending: true)
            
            let snapshot = try await query.getDocuments()
            
            self.events = snapshot.documents.compactMap { doc in
                let data = doc.data()
                let id = doc.documentID
                return Event(documentId: id, dictionary: data)
            }
            
        } catch {
            print("DEBUG: Error al leer eventos: \(error.localizedDescription)")
            errorMessage = "No se pudieron cargar los eventos."
        }
        
        isLoading = false
    }
    
    // --- CALCULAR ESTADÍSTICAS DEL ORGANIZADOR (ACTUALIZADO) ---
    func fetchOrganizerStats(hostId: String) {
        
        // 1. Filtramos la lista global para obtener solo los de este host
        self.organizerEvents = self.events.filter { $0.hostId == hostId }
        
        let totalEvents = Double(organizerEvents.count)
        
        // --- Tarjetas Superiores ---
        self.createdCount = Int(totalEvents)
        
        let activeEvents = organizerEvents.filter {
            $0.status == "Disponible" || $0.status == "En Curso"
        }
        self.activeCount = activeEvents.count
        
        let totalPlayers = organizerEvents.reduce(0) { $0 + $1.currentPlayers }
        self.totalPlayersCount = totalPlayers
        
        // --- Barras de Progreso (Pestaña General) ---
        
        if totalEvents > 0 {
            // A. Tasa de Éxito (Torneos Finalizados / Totales)
            let finishedEvents = organizerEvents.filter { $0.status == "Finalizado" }.count
            self.successRate = Double(finishedEvents) / totalEvents
            
            // B. Asistencia Promedio (Jugadores / Eventos)
            let avg = Double(totalPlayers) / totalEvents
            // Normalizamos para la barra (meta arbitraria: 20 jugadores = barra llena)
            self.averageAttendance = min(avg / 20.0, 1.0)
            
            // C. Torneos Activos (Ratio para la barra)
            self.activeRatio = Double(self.activeCount) / totalEvents
            
        } else {
            // Si no hay eventos, todo es 0
            self.successRate = 0
            self.averageAttendance = 0
            self.activeRatio = 0
        }
    }
}
