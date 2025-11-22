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
    let role: String
    let pais: String?
    
    // --- Campos de Gamificación ---
    var xp: Int?                 // Puntos de experiencia REALES
    // Nota: 'level' lo mantenemos por compatibilidad, pero usaremos 'calculatedLevel'
    var level: Int?
    var hostCategory: String?
    var isPremiumSubscriber: Bool?
    
    // --- Estadísticas ---
    var tournamentsPlayed: Int?
    var tournamentsWon: Int?
    var globalRank: Int?
    
    // --- LÓGICA DE NIVELES AUTOMÁTICA (NUEVO) ---
    
    // 1. Calcula el nivel basado en 100 XP por nivel
    // Si tienes 50 XP -> (50/100) + 1 = Nivel 1
    // Si tienes 150 XP -> (150/100) + 1 = Nivel 2
    var calculatedLevel: Int {
        let currentXP = xp ?? 0
        return (currentXP / 100) + 1
    }
    
    // 2. Calcula el progreso de la barra (0.0 a 1.0)
    // Si tienes 150 XP -> 150 % 100 = 50 -> 0.5 (50%)
    var levelProgress: Double {
        let currentXP = xp ?? 0
        let xpInCurrentLevel = currentXP % 100
        return Double(xpInCurrentLevel) / 100.0
    }
    
    // 3. Calcula la tasa de victorias
    var winRate: Double {
        let played = Double(tournamentsPlayed ?? 0)
        let won = Double(tournamentsWon ?? 0)
        if played == 0 { return 0.0 }
        return (won / played) * 100
    }
    
    // --- TRADUCTOR #1 ---
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
        self.tournamentsPlayed = dictionary["tournamentsPlayed"] as? Int ?? 0
        self.tournamentsWon = dictionary["tournamentsWon"] as? Int ?? 0
        self.globalRank = dictionary["globalRank"] as? Int ?? 0
    }
    
    // --- TRADUCTOR #2 ---
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
            "tournamentsPlayed": tournamentsPlayed ?? 0,
            "tournamentsWon": tournamentsWon ?? 0,
            "globalRank": globalRank ?? 0
        ]
    }
    
    // --- INIT PREVIEW ---
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
        self.tournamentsPlayed = tournamentsPlayed
        self.tournamentsWon = tournamentsWon
        self.globalRank = globalRank
    }
}
