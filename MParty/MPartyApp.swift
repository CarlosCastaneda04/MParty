//
//  MPartyApp.swift
//  MParty
//
//  Created by user285805 on 11/7/25.
//

import SwiftUI
import FirebaseCore
import Combine // <-- Importante para @StateObject

@main
struct MPartyApp: App {
  
  // 1. Aquí se crea el ÚNICO "cerebro" (ViewModel)
  @StateObject private var authViewModel = AuthViewModel()
  
  init() {
    FirebaseApp.configure()
  }

  var body: some Scene {
    WindowGroup {
        // 2. Lógica para decidir qué vista mostrar
        if authViewModel.userSession != nil && authViewModel.currentUser != nil {
            
            // Usuario LOGUEADO: Muestra la app principal
            MainTabView()
                // Pasa el "cerebro" a la app principal
                .environmentObject(authViewModel)
            
        } else {
            
            // Usuario NO LOGUEADO: Muestra el Login
            LoginView()
                // Pasa el "cerebro" a la vista de Login
                .environmentObject(authViewModel)
        }
    }
  }
}
