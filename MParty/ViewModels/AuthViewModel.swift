//
//  AuthViewModel.swift
//  MParty
//
//  Created by user285805 on 7/11/25.
//

import Foundation
import Combine // Para ObservableObject
import FirebaseAuth // Para crear usuarios
import FirebaseFirestore // Para la base de datos
import FirebaseStorage // Para las fotos
import PhotosUI // Para el selector de fotos
import SwiftUI // Para UIImage

class AuthViewModel: ObservableObject {
    
    // --- Variables Publicadas (para que la Vista reaccione) ---
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: User?
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    // --- Conexiones a Firebase ---
    private var db = Firestore.firestore()
    private var storage = Storage.storage()
    
    // --- INICIALIZADOR ---
    // Se ejecuta en cuanto la app arranca
    init() {
        self.userSession = Auth.auth().currentUser
        
        // Si hay una sesión guardada, carga los datos de ese usuario
        if let session = userSession {
            Task {
                await fetchUser(uid: session.uid)
            }
        }
    }
    
    // --- FUNCIÓN DE LOGIN ---
    @MainActor
    func signIn(withEmail email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            self.userSession = authResult.user
            await fetchUser(uid: authResult.user.uid)
            
        } catch {
            print("DEBUG: Falló el inicio de sesión: \(error.localizedDescription)")
            self.errorMessage = "Correo o contraseña incorrectos. Intenta de nuevo."
        }
        
        isLoading = false
    }
    
    // --- FUNCIÓN DE REGISTRO (Corregida) ---
    @MainActor
    func createUser(withEmail email: String,
                      password: String,
                      fullName: String,
                      pais: String,
                      role: String) async {
        
        isLoading = true
        errorMessage = nil
        
        do {
            // 1. Crea el usuario en Firebase Authentication
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            self.userSession = authResult.user
            let uid = authResult.user.uid
            
            // 2. Prepara el "Molde" (Modelo) del nuevo usuario
            // (Usamos el 'init' largo de User.swift)
            let newUser = User(
                id: uid,
                email: email,
                displayName: fullName,
                role: role,
                pais: pais,
                xp: 0,
                level: 1,
                hostCategory: role == "host" ? "Bronce" : nil,
                isPremiumSubscriber: false
            )
            
            // 3. Guarda el 'dictionary' en Firestore
            let userRef = db.collection("users").document(uid)
            // Usa el traductor '.dictionary' que creamos en User.swift
            try await userRef.setData(newUser.dictionary)
            
            // 4. Guarda el usuario recién creado en el ViewModel
            self.currentUser = newUser
            
        } catch {
            // 5. Si falla, guarda el error
            print("DEBUG: Falló al crear usuario: \(error.localizedDescription)")
            self.errorMessage = "Error al crear la cuenta. El correo podría ya estar en uso."
        }
        
        isLoading = false
    }
    
    // --- FUNCIÓN AUXILIAR (Corregida) ---
    // Carga los datos de un usuario desde Firestore
    @MainActor
    func fetchUser(uid: String) async {
        do {
            let snapshot = try await db.collection("users").document(uid).getDocument()
            
            // 1. Asegúrate de que el documento y los datos existen
            guard let data = snapshot.data(), snapshot.exists else {
                print("DEBUG: El documento del usuario no existe.")
                self.errorMessage = "No se encontraron los datos del usuario."
                self.signOut()
                return
            }
            
            // 2. Creamos el usuario usando nuestro 'init' traductor
            self.currentUser = User(uid: uid, dictionary: data)
            
        } catch {
            print("DEBUG: No se pudo cargar el usuario: \(error.localizedDescription)")
            self.errorMessage = "Error al cargar los datos del usuario."
            self.signOut()
        }
    }
    
    // --- FUNCIÓN PARA SUBIR LA FOTO DE PERFIL ---
    private func uploadProfileImage(imageData: Data, forUser uid: String) async -> String? {
        let storageRef = storage.reference().child("profile_images/\(uid).jpg")
        
        do {
            let _ = try await storageRef.putDataAsync(imageData, metadata: nil)
            let downloadURL = try await storageRef.downloadURL()
            return downloadURL.absoluteString
            
        } catch {
            print("DEBUG: Falló la subida de imagen: \(error.localizedDescription)")
            return nil
        }
    }
    
    // --- FUNCIÓN PRINCIPAL PARA ACTUALIZAR EL PERFIL ---
    @MainActor
    func updateUserProfile(newFullName: String, newPais: String, newProfileImage: UIImage?) async {
        
        guard let user = self.currentUser, let uid = user.id else {
            errorMessage = "No se pudo encontrar el usuario."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        var dataToUpdate: [String: Any] = [:]
        
        // --- 1. Lógica de la Imagen ---
        if let newImage = newProfileImage, let imageData = newImage.jpegData(compressionQuality: 0.5) {
            if let newPhotoURL = await uploadProfileImage(imageData: imageData, forUser: uid) {
                dataToUpdate["profilePhotoURL"] = newPhotoURL
            }
        }
        
        // --- 2. Lógica de los Nombres ---
        if newFullName != user.displayName {
            dataToUpdate["displayName"] = newFullName
        }
        if newPais != user.pais {
            dataToUpdate["pais"] = newPais
        }
        
        // --- 3. Guardar en Firestore ---
        if !dataToUpdate.isEmpty {
            do {
                let userRef = db.collection("users").document(uid)
                try await userRef.updateData(dataToUpdate)
                
                // 4. ¡Éxito! Refresca los datos del usuario localmente
                await fetchUser(uid: uid)
                
            } catch {
                print("DEBUG: Falló al actualizar el perfil: \(error.localizedDescription)")
                errorMessage = "Hubo un error al guardar los cambios."
            }
        }
        
        isLoading = false
    }
    
    // --- CERRAR SESIÓN ---
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.userSession = nil
            self.currentUser = nil
        } catch {
            print("DEBUG: Error al cerrar sesión: \(error.localizedDescription)")
        }
    }
}
