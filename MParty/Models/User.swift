//
//  User.swift
//  MParty
//
//  Created by user285805 on 7/11/25.
//

import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    
    // El 'id' debe coincidir con el UID de Firebase Authentication
    @DocumentID var id: String?
    
    let email: String
    let displayName: String
    var profilePhotoURL: String?
    let role: String // "host" o "player"
    let pais: String?
    
    // --- Campos de Gamificación ---
    var xp: Int?
    var level: Int?
    var hostCategory: String?
    var isPremiumSubscriber: Bool?
    
    
    // --- TRADUCTOR #1: Convertir de Firestore a User ---
    // (Iniciador que acepta un diccionario de Firestore)
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
    }
    
    // --- TRADUCTOR #2: Convertir de User a Firestore ---
    // (Una variable que CREA el diccionario para guardar)
    var dictionary: [String: Any] {
        return [
            "email": email,
            "displayName": displayName,
            "role": role,
            "pais": pais ?? "",
            "xp": xp ?? 0,
            "level": level ?? 1,
            "hostCategory": hostCategory ?? NSNull(), // Usa NSNull si es nil
            "isPremiumSubscriber": isPremiumSubscriber ?? false,
            "profilePhotoURL": profilePhotoURL ?? NSNull()
        ]
    }
    
    // --- ESTE ES EL 'INIT' PARA LA VISTA PREVIA ---
    init(id: String?, email: String, displayName: String, profilePhotoURL: String? = nil, role: String, pais: String?, xp: Int? = 0, level: Int? = 1, hostCategory: String? = nil, isPremiumSubscriber: Bool? = false) {
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
    }
}
