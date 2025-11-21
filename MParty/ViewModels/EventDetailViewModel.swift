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
    
    let event: Event
    private var db = Firestore.firestore()
    
    // 1. El ViewModel se crea CON el evento que va a manejar
    init(event: Event) {
        self.event = event
    }
    
    // 2. Función "maestra" que se llama al abrir la vista
    func fetchEventData(userId: String) async {
        isLoading = true
        await fetchParticipants()
        
        // 3. Revisa si el usuario actual está en la lista que bajamos
        self.hasCurrentUserJoined = participants.contains { $0.id == userId }
        isLoading = false
    }
    
    // 4. Lee la sub-colección "participants" del evento
    private func fetchParticipants() async {
        guard let eventId = event.id else { return }
        
        do {
            let snapshot = try await db.collection("events").document(eventId)
                                      .collection("participants").getDocuments()
            
            // Usa el 'init' manual que creamos en Participant.swift
            self.participants = snapshot.documents.compactMap { doc in
                let data = doc.data()
                let id = doc.documentID
                return Participant(documentId: id, dictionary: data)
            }
        } catch {
            print("DEBUG: Falló al cargar participantes: \(error.localizedDescription)")
            self.errorMessage = "Error al cargar la lista de jugadores."
        }
    }
    
    // --- ACCIONES DEL JUGADOR ---
    
    func joinEvent(user: User) async {
        guard let eventId = event.id, let userId = user.id else { return }
        isLoading = true
        
        // 1. Crea un objeto Participante a partir del Usuario
        let newParticipant = Participant(from: user)
        
        do {
            // A. Guarda el 'dictionary' del participante en la sub-colección del evento
            try await db.collection("events").document(eventId)
                      .collection("participants").document(userId)
                      .setData(newParticipant.dictionary)
            
            // B. NUEVO: Incrementa el contador 'tournamentsPlayed' del USUARIO
            // Usamos FieldValue.increment(1) para que sea exacto y seguro
            try await db.collection("users").document(userId).updateData([
                "tournamentsPlayed": FieldValue.increment(Int64(1))
            ])
            
            // (Opcional: También podrías incrementar 'currentPlayers' en el documento del evento aquí)
            try await db.collection("events").document(eventId).updateData([
                "currentPlayers": FieldValue.increment(Int64(1))
            ])
            
            // 3. Actualiza el estado local para que la UI cambie inmediatamente
            self.participants.append(newParticipant)
            self.hasCurrentUserJoined = true
            
        } catch {
            print("DEBUG: Falló al unirse al evento: \(error.localizedDescription)")
            self.errorMessage = "Hubo un error al unirte."
        }
        isLoading = false
    }
    
    func cancelParticipation(userId: String) async {
        guard let eventId = event.id else { return }
        isLoading = true
        
        do {
            // 1. Borra el documento del participante
            try await db.collection("events").document(eventId)
                      .collection("participants").document(userId)
                      .delete()
            
            // 2. (Opcional) Restar 1 al contador del evento
             try await db.collection("events").document(eventId).updateData([
                 "currentPlayers": FieldValue.increment(Int64(-1))
             ])
            
            // Nota: Generalmente NO restamos 'tournamentsPlayed' del usuario histórico
            // porque técnicamente sí participó (se inscribió), pero eso es decisión tuya.
            
            // 3. Actualiza el estado local
            self.participants.removeAll { $0.id == userId }
            self.hasCurrentUserJoined = false
            
        } catch {
            print("DEBUG: Falló al cancelar: \(error.localizedDescription)")
            self.errorMessage = "Hubo un error al cancelar."
        }
        isLoading = false
    }
}
