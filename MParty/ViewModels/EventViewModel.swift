//
//  EventViewModel.swift
//  MParty
//
//  Created by user285805 on 7/11/25.
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseStorage // <-- IMPORTANTE
import SwiftUI // Para UIImage

@MainActor
class EventViewModel: ObservableObject {
    
    @Published var events: [Event] = []
    @Published var organizerEvents: [Event] = []
    
    // Estadísticas
    @Published var createdCount: Int = 0
    @Published var activeCount: Int = 0
    @Published var totalPlayersCount: Int = 0
    
    // Métricas de Organizador
    @Published var successRate: Double = 0.0
    @Published var averageAttendance: Double = 0.0
    @Published var activeRatio: Double = 0.0
    
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    private var db = Firestore.firestore()
    private var storage = Storage.storage() // <-- Referencia a Storage
    
    // --- FUNCIÓN PARA SUBIR IMAGEN ---
    private func uploadBannerImage(_ image: UIImage) async -> String? {
        // Generamos un nombre único para la imagen
        let filename = UUID().uuidString
        let storageRef = storage.reference().child("event_banners/\(filename).jpg")
        
        guard let imageData = image.jpegData(compressionQuality: 0.5) else { return nil }
        
        do {
            let _ = try await storageRef.putDataAsync(imageData, metadata: nil)
            let downloadURL = try await storageRef.downloadURL()
            return downloadURL.absoluteString
        } catch {
            print("DEBUG: Falló subida de banner: \(error.localizedDescription)")
            return nil
        }
    }
    
    // --- CREAR EVENTO (AHORA RECIBE IMAGEN) ---
    func createEvent(
        title: String,
        description: String,
        gameType: String,
        eventDate: Date,
        location: String,
        mode: String,
        maxPlayers: Int,
        isPaidEvent: Bool,
        host: User,
        bannerImage: UIImage? // <-- NUEVO PARÁMETRO
    ) async -> Bool {
        
        isLoading = true
        errorMessage = nil
        
        // 1. Subir Imagen (si existe)
        var bannerURL: String? = nil
        if let image = bannerImage {
            bannerURL = await uploadBannerImage(image)
        }
        
        // 2. Preparar datos
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
            "eventBannerURL": bannerURL ?? NSNull(), // <-- GUARDAMOS LA URL
            "entryFee": NSNull(),
            "currentPlayers": 0
        ]
        
        // 3. Guardar en Firestore
        do {
            try await db.collection("events").addDocument(data: eventData)
            isLoading = false
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
            let query = db.collection("events").order(by: "eventDate", descending: true)
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
    
    // --- CALCULAR ESTADÍSTICAS ---
    func fetchOrganizerStats(hostId: String) {
        self.organizerEvents = self.events.filter { $0.hostId == hostId }
        
        let totalEvents = Double(organizerEvents.count)
        self.createdCount = Int(totalEvents)
        
        let activeEvents = organizerEvents.filter { $0.status == "Disponible" || $0.status == "En Curso" }
        self.activeCount = activeEvents.count
        
        let totalPlayers = organizerEvents.reduce(0) { $0 + $1.currentPlayers }
        self.totalPlayersCount = totalPlayers
        
        if totalEvents > 0 {
            let finishedEvents = organizerEvents.filter { $0.status == "Finalizado" }.count
            self.successRate = Double(finishedEvents) / totalEvents
            
            let avg = Double(totalPlayers) / totalEvents
            self.averageAttendance = min(avg / 20.0, 1.0)
            
            self.activeRatio = Double(self.activeCount) / totalEvents
        } else {
            self.successRate = 0
            self.averageAttendance = 0
            self.activeRatio = 0
        }
    }
}
