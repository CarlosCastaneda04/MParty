//
//  Event.swift
//  MParty
//
//  Created by user285805 on 7/11/25.
//

import Foundation
import FirebaseFirestore

struct Event: Identifiable, Codable {
    
    @DocumentID var id: String?
    
    // --- Datos del Evento ---
    let title: String
    let description: String
    let gameType: String
    let mode: String
    let location: String
    let maxPlayers: Int
    let eventDate: Timestamp
    let status: String
    var eventBannerURL: String?
    
    // --- NUEVO: Contador de Jugadores ---
    var currentPlayers: Int // <-- AÑADIDO
    
    // --- Campos de Pago ---
    let isPaidEvent: Bool
    var entryFee: Double?
    
    // --- Datos del Organizador ---
    let hostId: String
    let hostName: String
    
    // --- TRADUCTOR #1: Convertir de Firestore a Event ---
    init(documentId: String, dictionary: [String: Any]) {
        self.id = documentId
        self.title = dictionary["title"] as? String ?? ""
        self.description = dictionary["description"] as? String ?? ""
        self.gameType = dictionary["gameType"] as? String ?? ""
        self.mode = dictionary["mode"] as? String ?? ""
        self.location = dictionary["location"] as? String ?? ""
        self.maxPlayers = dictionary["maxPlayers"] as? Int ?? 0
        self.eventDate = dictionary["eventDate"] as? Timestamp ?? Timestamp(date: Date())
        self.status = dictionary["status"] as? String ?? ""
        self.eventBannerURL = dictionary["eventBannerURL"] as? String
        
        self.currentPlayers = dictionary["currentPlayers"] as? Int ?? 0 // <-- AÑADIDO
        
        self.isPaidEvent = dictionary["isPaidEvent"] as? Bool ?? false
        self.entryFee = dictionary["entryFee"] as? Double
        self.hostId = dictionary["hostId"] as? String ?? ""
        self.hostName = dictionary["hostName"] as? String ?? ""
    }
    
    // --- TRADUCTOR #2: Convertir de Event a Firestore ---
    var dictionary: [String: Any] {
        return [
            "title": title,
            "description": description,
            "gameType": gameType,
            "mode": mode,
            "location": location,
            "maxPlayers": maxPlayers,
            "eventDate": eventDate,
            "status": status,
            "eventBannerURL": eventBannerURL ?? NSNull(),
            "currentPlayers": currentPlayers, // <-- AÑADIDO
            "isPaidEvent": isPaidEvent,
            "entryFee": entryFee ?? NSNull(),
            "hostId": hostId,
            "hostName": hostName
        ]
    }
    
    // --- Init para crear un Evento (Preview) ---
    init(id: String?, title: String, description: String, gameType: String, mode: String, location: String, maxPlayers: Int, eventDate: Timestamp, status: String, hostId: String, hostName: String) {
        self.id = id
        self.title = title
        self.description = description
        self.gameType = gameType
        self.mode = mode
        self.location = location
        self.maxPlayers = maxPlayers
        self.eventDate = eventDate
        self.status = status
        self.currentPlayers = 0 // <-- AÑADIDO
        self.isPaidEvent = false
        self.hostId = hostId
        self.hostName = hostName
    }
}
