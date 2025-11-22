//
//  EventDetailViewModel.swift
//  MParty
//
//  Created by user285805 on 7/11/25.
//

import Foundation
import Combine
import FirebaseFirestore

@MainActor
class EventDetailViewModel: ObservableObject {
    
    @Published var participants: [Participant] = []
    @Published var hasCurrentUserJoined: Bool = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // --- Variables para la Gestión del Torneo ---
    @Published var event: Event // Ahora es @Published para que la UI reaccione a cambios de estado
    @Published var generatedPairings: [String] = [] // Lista de textos "Jugador A vs Jugador B"
    
    private var db = Firestore.firestore()
    
    init(event: Event) {
        self.event = event
    }
    
    // --- CARGAR DATOS ---
    func fetchEventData(userId: String) async {
        isLoading = true
        await fetchParticipants()
        
        // Recargamos el evento para tener el estado más reciente (Disponible, En Curso, etc)
        if let eventId = event.id {
            do {
                let doc = try await db.collection("events").document(eventId).getDocument()
                if let data = doc.data() {
                    self.event = Event(documentId: eventId, dictionary: data)
                }
            } catch { print("Error recargando evento") }
        }
        
        self.hasCurrentUserJoined = participants.contains { $0.id == userId }
        isLoading = false
    }
    
    private func fetchParticipants() async {
        guard let eventId = event.id else { return }
        do {
            let snapshot = try await db.collection("events").document(eventId)
                                      .collection("participants").getDocuments()
            self.participants = snapshot.documents.compactMap { doc in
                let data = doc.data()
                let id = doc.documentID
                return Participant(documentId: id, dictionary: data)
            }
        } catch {
            self.errorMessage = "Error al cargar jugadores."
        }
    }
    
    // --- ACCIONES DEL JUGADOR ---
    func joinEvent(user: User) async {
        // VALIDACIÓN: No unirse si ya empezó
        guard event.status == "Disponible" else {
            self.errorMessage = "El torneo ya inició o finalizó."
            return
        }
        guard let eventId = event.id, let userId = user.id else { return }
        
        isLoading = true
        let newParticipant = Participant(from: user)
        
        do {
            try await db.collection("events").document(eventId)
                      .collection("participants").document(userId)
                      .setData(newParticipant.dictionary)
            
            try await db.collection("users").document(userId).updateData([
                "tournamentsPlayed": FieldValue.increment(Int64(1))
            ])
            
            // Incrementa contador visual en el evento
            try await db.collection("events").document(eventId).updateData([
                "currentPlayers": FieldValue.increment(Int64(1))
            ])
            
            self.participants.append(newParticipant)
            self.hasCurrentUserJoined = true
            // Actualizamos el evento localmente
            self.event.currentPlayers += 1
            
        } catch {
            self.errorMessage = "Hubo un error al unirte."
        }
        isLoading = false
    }
    
    func cancelParticipation(userId: String) async {
        // VALIDACIÓN: No salir si ya empezó
        guard event.status == "Disponible" else {
            self.errorMessage = "No puedes salirte, el torneo ya está en curso."
            return
        }
        guard let eventId = event.id else { return }
        
        isLoading = true
        do {
            try await db.collection("events").document(eventId)
                      .collection("participants").document(userId)
                      .delete()
            
            try await db.collection("events").document(eventId).updateData([
                "currentPlayers": FieldValue.increment(Int64(-1))
            ])
            
            self.participants.removeAll { $0.id == userId }
            self.hasCurrentUserJoined = false
            self.event.currentPlayers -= 1
            
        } catch {
            self.errorMessage = "Hubo un error al cancelar."
        }
        isLoading = false
    }
    
    // --- GESTIÓN DEL HOST (NUEVO) ---
    
    // 1. Iniciar Torneo
    func startTournament() async {
        guard let eventId = event.id else { return }
        isLoading = true
        
        do {
            try await db.collection("events").document(eventId).updateData([
                "status": "En Curso"
            ])
            self.event = Event(id: event.id, title: event.title, description: event.description, gameType: event.gameType, mode: event.mode, location: event.location, maxPlayers: event.maxPlayers, eventDate: event.eventDate, status: "En Curso", hostId: event.hostId, hostName: event.hostName) // Actualizar local
            // (Nota: idealmente actualizarías todo el objeto, aquí simplificamos para la UI)
        } catch {
            errorMessage = "Error al iniciar el torneo."
        }
        isLoading = false
    }
    
    // 2. Generar Emparejamientos (Random 1vs1)
    func generatePairings() {
        guard participants.count >= 2 else {
            errorMessage = "Se necesitan al menos 2 jugadores."
            return
        }
        
        var shuffledPlayers = participants.shuffled()
        var pairings: [String] = []
        
        while shuffledPlayers.count >= 2 {
            let player1 = shuffledPlayers.removeFirst()
            let player2 = shuffledPlayers.removeFirst()
            pairings.append("⚔️ \(player1.displayName) VS \(player2.displayName)")
        }
        
        // Si sobra uno (impar)
        if let oddOne = shuffledPlayers.first {
            pairings.append("🛡️ \(oddOne.displayName) pasa automáticamente (Bye)")
        }
        
        self.generatedPairings = pairings
    }
    
    // 3. Finalizar y Repartir Premios (El Gran Final)
    func finalizeTournament(winner: Participant, second: Participant?, third: Participant?) async {
        guard let eventId = event.id else { return }
        isLoading = true
        
        let batch = db.batch() // Usamos batch para que todo se guarde junto o nada
        
        // A. Actualizar Estado del Torneo
        let eventRef = db.collection("events").document(eventId)
        batch.updateData(["status": "Finalizado"], forDocument: eventRef)
        
        // B. Repartir XP y Victorias
        for player in participants {
            guard let pid = player.id else { continue }
            let userRef = db.collection("users").document(pid)
            
            var xpGain = 25 // Base por participación
            
            if pid == winner.id {
                xpGain = 100
                // Sumar victoria al ganador
                batch.updateData([
                    "tournamentsWon": FieldValue.increment(Int64(1)),
                    "xp": FieldValue.increment(Int64(xpGain))
                ], forDocument: userRef)
                
            } else if pid == second?.id {
                xpGain = 75
                batch.updateData(["xp": FieldValue.increment(Int64(xpGain))], forDocument: userRef)
                
            } else if pid == third?.id {
                xpGain = 50
                batch.updateData(["xp": FieldValue.increment(Int64(xpGain))], forDocument: userRef)
                
            } else {
                // Participación normal
                batch.updateData(["xp": FieldValue.increment(Int64(xpGain))], forDocument: userRef)
            }
        }
        
        // C. Ejecutar todo
        do {
            try await batch.commit()
            // Actualizar UI local
            // self.event.status = "Finalizado" (Necesitamos recrear el objeto struct)
            // Para simplificar, recargamos:
            await fetchEventData(userId: "")
        } catch {
            errorMessage = "Error al finalizar el torneo."
        }
        
        isLoading = false
    }
}
