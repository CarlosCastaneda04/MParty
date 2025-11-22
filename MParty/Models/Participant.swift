//
//  Participant.swift
//  MParty
//
//  Created by user285805 on 7/11/25.
//

import Foundation
import FirebaseFirestore

struct Participant: Identifiable, Codable, Hashable {
    
    // Usaremos el UID del usuario como el ID del documento
    @DocumentID var id: String?
    
    let displayName: String
    let profilePhotoURL: String?
    let level: Int
    let rank: Int // Placeholder para el rank
    
    // --- TRADUCTOR #1: Convertir de Firestore a Participant ---
    init(documentId: String, dictionary: [String: Any]) {
        self.id = documentId
        self.displayName = dictionary["displayName"] as? String ?? ""
        self.profilePhotoURL = dictionary["profilePhotoURL"] as? String
        self.level = dictionary["level"] as? Int ?? 1
        self.rank = dictionary["rank"] as? Int ?? 0
    }
    
    // --- TRADUCTOR #2: Convertir de Participant a Firestore ---
    var dictionary: [String: Any] {
        return [
            "displayName": displayName,
            "profilePhotoURL": profilePhotoURL ?? NSNull(),
            "level": level,
            "rank": rank
        ]
    }
    
    // --- Init para crear un Participante desde un User ---
    init(from user: User) {
        self.id = user.id
        self.displayName = user.displayName
        self.profilePhotoURL = user.profilePhotoURL
        self.level = user.level ?? 1
        self.rank = user.xp ?? 0 // Usando XP como placeholder del Rank
    }
}
