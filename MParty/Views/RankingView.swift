//
//  RankingView.swift
//  MParty
//
//  Created by user285805 on 7/11/25.
//

import SwiftUI

struct RankingView: View {
    
    // 1. Crea el cerebro (ViewModel) para esta vista
    @StateObject private var viewModel = RankingViewModel()
    
    // 2. Recibe el cerebro de Auth para saber quién es "TÚ"
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // 3. State para los filtros (Global, Nacional, Local)
    @State private var selectedFilter: RankingFilter = .global
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                
                // --- 1. Tarjeta "Tabla de Líderes" ---
                LeadersCardView(currentUser: authViewModel.currentUser)
                
                // --- 2. Filtros ---
                FilterButtonsView(selectedFilter: $selectedFilter)
                
                // --- 3. El Podio (Top 3) ---
                // Solo muestra el podio si tenemos al menos 3 usuarios
                if viewModel.users.count >= 3 {
                    PodiumView(users: Array(viewModel.users.prefix(3)))
                }
                
                // --- 4. Lista "Todos los Rankings" ---
                RankingListView(
                    users: Array(viewModel.users.dropFirst(3)), // Envía del #4 en adelante
                    currentUser: authViewModel.currentUser
                )
                
            }
            .padding()
        }
        .navigationTitle("Rankings Globales")
        .navigationBarTitleDisplayMode(.inline)
        .task { // 'task' es la forma moderna de '.onAppear' para tareas 'async'
            // 5. Carga el ranking cuando la vista aparece
            await viewModel.fetchRankings(filter: selectedFilter)
        }
        .onChange(of: selectedFilter) { newFilter in
            // 6. Vuelve a cargar si el filtro cambia
            Task {
                await viewModel.fetchRankings(filter: newFilter)
            }
        }
        // Necesitamos un 'id' para que el 'onChange' funcione con un 'enum' complejo
        .id(selectedFilter.id)
    }
}

// MARK: - Sub-Vistas (Componentes)

struct LeadersCardView: View {
    let currentUser: User?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "trophy.fill")
                .font(.title)
                .foregroundColor(.yellow)
            
            Text("Tabla de Líderes")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Compite con los mejores")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text("Tu Ranking Actual")
                .font(.callout)
            
            // TODO: Calcular el ranking real del usuario
            Text("#3")
                .font(.system(size: 40, weight: .bold))
            
            Text("¡Top 10!")
                .font(.caption)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 200)
        .background(Color.purple)
        .foregroundColor(.white)
        .cornerRadius(15)
    }
}

struct FilterButtonsView: View {
    @Binding var selectedFilter: RankingFilter
    
    var body: some View {
        HStack {
            FilterButton(title: "Global", filter: .global, selectedFilter: $selectedFilter)
            FilterButton(title: "Nacional", filter: .national("El Salvador"), selectedFilter: $selectedFilter)
            FilterButton(title: "Local", filter: .local, selectedFilter: $selectedFilter)
        }
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// Botón de filtro individual
struct FilterButton: View {
    let title: String
    let filter: RankingFilter
    @Binding var selectedFilter: RankingFilter
    
    var isSelected: Bool {
        selectedFilter.id == filter.id
    }
    
    var body: some View {
        Text(title)
            .fontWeight(isSelected ? .bold : .regular)
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            .background(isSelected ? .white : Color.clear)
            .cornerRadius(8)
            .onTapGesture {
                selectedFilter = filter
            }
    }
}

struct PodiumView: View {
    // Recibe exactamente 3 usuarios (Top 3)
    let users: [User]
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            // #2 Plata
            PodiumCard(user: users[1], rank: 2, color: Color(.systemGray4))
            
            // #1 Oro
            PodiumCard(user: users[0], rank: 1, color: .yellow)
            
            // #3 Bronce
            PodiumCard(user: users[2], rank: 3, color: .orange)
        }
    }
}

struct PodiumCard: View {
    let user: User
    let rank: Int
    let color: Color
    
    var height: CGFloat {
        switch rank {
        case 1: return 150
        case 2: return 120
        case 3: return 120
        default: return 100
        }
    }
    
    var body: some View {
        VStack {
            // TODO: Reemplazar con la foto de perfil
            Image(systemName: "person.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
                .padding(10)
                .background(Color.white.clipShape(Circle()))
            
            Text("#\(rank)")
                .font(.headline)
            Text(user.displayName)
                .font(.subheadline)
                .fontWeight(.bold)
            Text("Nv. \(user.level ?? 1)")
                .font(.caption)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(color.opacity(0.6))
        .cornerRadius(12)
    }
}

struct RankingListView: View {
    // Recibe los usuarios del #4 en adelante
    let users: [User]
    let currentUser: User?
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Todos los Rankings")
                .font(.title2)
                .fontWeight(.bold)
            
            // El 'ForEach' necesita que 'User' sea 'Identifiable', ¡y ya lo es!
            // Usamos 'enumerated()' para obtener el 'index' (0, 1, 2...)
            // y así calcular el ranking real (4, 5, 6...).
            ForEach(Array(users.enumerated()), id: \.element.id) { index, user in
                
                let rank = index + 4 // Sumamos 4 (porque empezamos desde el 3er índice)
                
                UserRowView(user: user, rank: rank, isCurrentUser: user.id == currentUser?.id)
            }
        }
    }
}

struct UserRowView: View {
    let user: User
    let rank: Int
    let isCurrentUser: Bool
    
    var body: some View {
        HStack {
            Text("#\(rank)")
                .font(.headline)
                .frame(width: 40)
            
            // TODO: Reemplazar con la foto de perfil
            Image(systemName: "person.circle.fill")
                .font(.system(size: 30))
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading) {
                Text(user.displayName)
                    .fontWeight(.bold)
                Text("\(user.pais ?? "??") • Nivel \(user.level ?? 1)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if isCurrentUser {
                Text("TÚ")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.2))
                    .foregroundColor(.purple)
                    .cornerRadius(5)
            }
            
            Spacer()
            
            // TODO: Calcular el % de victorias
            Text("\(user.xp ?? 0)%") // Usando XP como placeholder
                .font(.headline)
        }
        .padding(12)
        .background(isCurrentUser ? Color.purple.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(10)
    }
}


// --- Extensiones de apoyo ---
extension RankingFilter {
    // Un 'id' para que el 'onChange' y los botones funcionen
    var id: String {
        switch self {
        case .global:
            return "global"
        case .national(let country):
            return "national_\(country)"
        case .local:
            return "local"
        }
    }
}
