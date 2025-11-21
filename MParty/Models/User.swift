//
//  User.swift
//  MParty
//
//  Created by user285805 on 7/11/25.
//

import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    
    @DocumentID var id: String?
    
    let email: String
    let displayName: String
    var profilePhotoURL: String?
    let role: String // "host" o "player" (o "Organizador")
    let pais: String?
    
    // --- Campos de Gamificación y Estadísticas ---
    var xp: Int?                 // Puntos de experiencia
    var level: Int?              // Nivel actual
    var hostCategory: String?    // Solo para Hosts: "Bronce", etc.
    var isPremiumSubscriber: Bool?
    
    // --- NUEVOS CAMPOS DE ESTADÍSTICAS ---
    var tournamentsPlayed: Int?  // Cantidad de torneos unidos
    var tournamentsWon: Int?     // Cantidad de torneos ganados
    var globalRank: Int?         // Posición en el ranking (ej. #5)
    
    // --- PROPIEDAD COMPUTADA (Cálculo automático) ---
    // Calcula la tasa de victorias al vuelo
    var winRate: Double {
        let played = Double(tournamentsPlayed ?? 0)
        let won = Double(tournamentsWon ?? 0)
        
        if played == 0 { return 0.0 }
        return (won / played) * 100
    }
    
    // --- TRADUCTOR #1: Convertir de Firestore a User ---
    init(uid: String, dictionary: [String: Any]) {
        self.id = uid
        self.email = dictionary["email"] as? String ?? ""
        self.displayName = dictionary["displayName"] as? String ?? ""
        self.profilePhotoURL = dictionary["profilePhotoURL"] as? String
        self.role = dictionary["role"] as? String ?? ""
        self.pais = dictionary["pais"] as? String
        self.xp = dictionary["xp"] as? Int ?? 0
        self.level = dictionary["level"] as? Int ?? 1
        self.hostCategory = dictionary["hostCategory"] as? String
        self.isPremiumSubscriber = dictionary["isPremiumSubscriber"] as? Bool ?? false
        
        // Nuevos campos
        self.tournamentsPlayed = dictionary["tournamentsPlayed"] as? Int ?? 0
        self.tournamentsWon = dictionary["tournamentsWon"] as? Int ?? 0
        self.globalRank = dictionary["globalRank"] as? Int ?? 0
    }
    
    // --- TRADUCTOR #2: Convertir de User a Firestore ---
    var dictionary: [String: Any] {
        return [
            "email": email,
            "displayName": displayName,
            "role": role,
            "pais": pais ?? "",
            "xp": xp ?? 0,
            "level": level ?? 1,
            "hostCategory": hostCategory ?? NSNull(),
            "isPremiumSubscriber": isPremiumSubscriber ?? false,
            "profilePhotoURL": profilePhotoURL ?? NSNull(),
            
            // Nuevos campos
            "tournamentsPlayed": tournamentsPlayed ?? 0,
            "tournamentsWon": tournamentsWon ?? 0,
            "globalRank": globalRank ?? 0
        ]
    }
    
    // --- INIT PARA PREVIEWS ---
    init(id: String?, email: String, displayName: String, profilePhotoURL: String? = nil, role: String, pais: String?, xp: Int? = 0, level: Int? = 1, hostCategory: String? = nil, isPremiumSubscriber: Bool? = false, tournamentsPlayed: Int? = 0, tournamentsWon: Int? = 0, globalRank: Int? = 0) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.profilePhotoURL = profilePhotoURL
        self.role = role
        self.pais = pais
        self.xp = xp
        self.level = level
        self.hostCategory = hostCategory
        self.isPremiumSubscriber = isPremiumSubscriber
        
        // Nuevos campos
        self.tournamentsPlayed = tournamentsPlayed
        self.tournamentsWon = tournamentsWon
        self.globalRank = globalRank
    }
}
