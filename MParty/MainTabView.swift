//
//  ContentView.swift
//  MParty
//
//  Created by user285805 on 11/7/25.
//

import SwiftUI

struct MainTabView: View {
    
    // 1. Recibimos el AuthViewModel desde MPartyApp
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        // 2. El TabView es la navegación principal de tu app
        TabView {
            // Pestaña 1: Inicio (El diseño que me mostraste)
            HomeView() // <-- Crearemos esta vista ahora
                .tabItem {
                    Label("Inicio", systemImage: "house.fill")
                }
            
            // Pestaña 2: Ranking (Placeholder)
            NavigationStack { // <-- Añade NavigationStack
                        RankingView() // <-- Reemplaza el 'Text'
                    }
                .tabItem {
                    Label("Ranking", systemImage: "chart.bar.xaxis")
                }
            
            // Pestaña 3: Eventos (Placeholder)
            Text("Eventos (próximamente)")
                .tabItem {
                    Label("Eventos", systemImage: "calendar")
                }
            
            // Pestaña 4: Perfil (Placeholder)
            NavigationStack {
                ProfileView()
            }
                .tabItem {
                    Label("Perfil", systemImage: "person.fill")
                }
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        // Necesitamos simular un AuthViewModel para la vista previa
        MainTabView()
            .environmentObject(AuthViewModel())
    }
}
