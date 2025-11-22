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
    @Published var event: Event
    @Published var generatedPairings: [String] = []
    
    private var db = Firestore.firestore()
    
    init(event: Event) {
        self.event = event
    }
    
    // --- CARGAR DATOS ---
    func fetchEventData(userId: String) async {
        isLoading = true
        await fetchParticipants()
        
        // Recargamos el evento para tener el estado más reciente
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
        // VALIDACIÓN 1: Estado
        guard event.status == "Disponible" else {
            self.errorMessage = "El torneo ya inició o finalizó."
            return
        }
        
        // VALIDACIÓN 2: Capacidad (CORRECCIÓN CLAVE)
        if participants.count >= event.maxPlayers {
            self.errorMessage = "El torneo ya está lleno."
            return
        }
        
        guard let eventId = event.id, let userId = user.id else { return }
        
        isLoading = true
        let newParticipant = Participant(from: user)
        
        do {
            // 1. Guardar participante
            try await db.collection("events").document(eventId)
                      .collection("participants").document(userId)
                      .setData(newParticipant.dictionary)
            
            // 2. Incrementar contador personal
            try await db.collection("users").document(userId).updateData([
                "tournamentsPlayed": FieldValue.increment(Int64(1))
            ])
            
            // 3. Incrementar contador del evento
            try await db.collection("events").document(eventId).updateData([
                "currentPlayers": FieldValue.increment(Int64(1))
            ])
            
            self.participants.append(newParticipant)
            self.hasCurrentUserJoined = true
            self.event.currentPlayers += 1 // Actualizar localmente
            
        } catch {
            self.errorMessage = "Hubo un error al unirte."
        }
        isLoading = false
    }
    
    func cancelParticipation(userId: String) async {
        guard event.status == "Disponible" else {
            self.errorMessage = "No puedes salirte, el torneo ya está en curso."
            return
        }
        guard let eventId = event.id else { return }
        
        isLoading = true
        do {
            // 1. Borrar participante
            try await db.collection("events").document(eventId)
                      .collection("participants").document(userId)
                      .delete()
            
            // 2. Decrementar contador del evento
            try await db.collection("events").document(eventId).updateData([
                "currentPlayers": FieldValue.increment(Int64(-1))
            ])
            
            self.participants.removeAll { $0.id == userId }
            self.hasCurrentUserJoined = false
            self.event.currentPlayers -= 1 // Actualizar localmente
            
        } catch {
            self.errorMessage = "Hubo un error al cancelar."
        }
        isLoading = false
    }
    
    // --- GESTIÓN DEL HOST ---
    
    func startTournament() async {
        guard let eventId = event.id else { return }
        isLoading = true
        
        do {
            try await db.collection("events").document(eventId).updateData([
                "status": "En Curso"
            ])
            // Actualizar localmente creando una copia del evento con el nuevo estado
            var updatedEvent = event
            // (Truco: Como 'let' no se puede cambiar, recreamos el struct con el nuevo valor)
            // En tu modelo Event, 'status' es 'let'.
            // Para simplificar, recargamos todo:
            await fetchEventData(userId: "")
            
        } catch {
            errorMessage = "Error al iniciar el torneo."
        }
        isLoading = false
    }
    
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
            pairings.append("\(player1.displayName) VS \(player2.displayName)")
        }
        
        if let oddOne = shuffledPlayers.first {
            pairings.append("\(oddOne.displayName) pasa automáticamente (Bye)")
        }
        
        self.generatedPairings = pairings
    }
    
    func finalizeTournament(winner: Participant, second: Participant?, third: Participant?) async {
        guard let eventId = event.id else { return }
        isLoading = true
        
        let batch = db.batch()
        let eventRef = db.collection("events").document(eventId)
        
        // A. Finalizar Evento
        batch.updateData(["status": "Finalizado"], forDocument: eventRef)
        
        // B. Repartir XP
        for player in participants {
            guard let pid = player.id else { continue }
            let userRef = db.collection("users").document(pid)
            var xpGain = 25
            
            if pid == winner.id {
                xpGain = 100
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
                batch.updateData(["xp": FieldValue.increment(Int64(xpGain))], forDocument: userRef)
            }
        }
        
        do {
            try await batch.commit()
            await fetchEventData(userId: "")
        } catch {
            errorMessage = "Error al finalizar el torneo."
        }
        
        isLoading = false
    }
}
