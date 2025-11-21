//
//  RankingView.swift
//  MParty
//
//  Created by user285805 on 7/11/25.
//

import SwiftUI

struct RankingView: View {
    
    @StateObject private var viewModel = RankingViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // Estado del filtro (Global por defecto)
    @State private var selectedFilter: RankingFilter = .global
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 25) {
                
                // --- 1. Tarjeta "Tu Ranking Actual" ---
                if let currentUser = authViewModel.currentUser {
                    MyRankingCard(currentUser: currentUser, allUsers: viewModel.users)
                }
                
                // --- 2. Filtros (Global / Nacional) ---
                HStack(spacing: 15) {
                    FilterOption(title: "Global", isActive: isGlobal, action: {
                        selectedFilter = .global
                    })
                    
                    FilterOption(title: "Nacional", isActive: !isGlobal, action: {
                        // Usamos el país del usuario actual
                        if let country = authViewModel.currentUser?.pais {
                            selectedFilter = .national(country)
                        }
                    })
                }
                .padding(.horizontal)
                
                // --- 3. Dropdown de Juegos ---
                HStack {
                    Text("Filtrar por juego:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                
                HStack {
                    Text("Todos los juegos")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                
                if viewModel.isLoading {
                    ProgressView()
                        .padding(.top, 50)
                } else {
                    // --- 4. El Podio (Top 3) ---
                    // CORRECCIÓN: Muestra el podio aunque sea solo 1 persona
                    if !viewModel.users.isEmpty {
                        PodiumView(users: Array(viewModel.users.prefix(3)))
                    }
                    
                    // --- 5. Lista del Resto (#4 en adelante) ---
                    LazyVStack(spacing: 10) {
                        // Empezamos desde el índice 3 (el cuarto jugador)
                        ForEach(Array(viewModel.users.dropFirst(3).enumerated()), id: \.element.id) { index, user in
                            // El rango real es índice + 4 (porque saltamos 3)
                            UserRankRow(user: user, rank: index + 4)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .padding(.top)
        }
        .navigationTitle("Rankings Globales")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchRankings(filter: selectedFilter)
        }
        .onChange(of: selectedFilter) { newFilter in
            Task {
                await viewModel.fetchRankings(filter: newFilter)
            }
        }
    }
    
    var isGlobal: Bool {
        if case .global = selectedFilter { return true }
        return false
    }
}

// MARK: - Componentes de Diseño

// 1. Tarjeta Morada "Tu Ranking"
struct MyRankingCard: View {
    let currentUser: User
    let allUsers: [User]
    
    var myRank: String {
        if let index = allUsers.firstIndex(where: { $0.id == currentUser.id }) {
            return "#\(index + 1)"
        }
        return "-"
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "6A5AE0"), Color(hex: "342686")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Image(systemName: "trophy")
                        .font(.title2)
                        .foregroundColor(.yellow)
                    Text("Tabla de Líderes")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                Text("Compite con los mejores")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, 15)
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Tu Ranking Actual")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        Text(myRank)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        Text("¡Sigue así!")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    Spacer()
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.green)
                        .font(.title2)
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            }
            .padding(20)
        }
        .frame(height: 220)
        .cornerRadius(20)
        .padding(.horizontal)
        .shadow(color: .purple.opacity(0.4), radius: 10, x: 0, y: 5)
    }
}

// 2. Botones de Filtro
struct FilterOption: View {
    let title: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isActive ? Color(hex: "6A5AE0") : Color.white)
                .foregroundColor(isActive ? .white : .black)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.2), lineWidth: isActive ? 0 : 1)
                )
        }
    }
}

// 3. El Podio
struct PodiumView: View {
    let users: [User]
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // #2 Plata
            if users.indices.contains(1) {
                PodiumCard(user: users[1], rank: 2, color: Color(hex: "E8E8E8"), height: 160)
            }
            // #1 Oro
            if users.indices.contains(0) {
                PodiumCard(user: users[0], rank: 1, color: Color(hex: "FFD700").opacity(0.5), height: 190, isGold: true)
            }
            // #3 Bronce
            if users.indices.contains(2) {
                PodiumCard(user: users[2], rank: 3, color: Color(hex: "CD7F32").opacity(0.7), height: 140)
            }
        }
        .padding(.horizontal)
    }
}

struct PodiumCard: View {
    let user: User
    let rank: Int
    let color: Color
    let height: CGFloat
    var isGold: Bool = false
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(isGold ? Color.yellow : Color.white, lineWidth: 2)
                    .frame(width: 50, height: 50)
                Text("\(rank)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(isGold ? .yellow : .gray)
            }
            .offset(y: -15)
            
            Spacer()
            
            Text("#\(rank)")
                .font(.headline)
                .foregroundColor(.black.opacity(0.7))
            
            Text(user.displayName)
                .font(.subheadline)
                .fontWeight(.bold)
                .lineLimit(1)
                .padding(.horizontal, 2)
            
            Text("Nv. \(user.level ?? 1)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(color)
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(isGold ? Color.yellow : Color.clear, lineWidth: isGold ? 2 : 0)
        )
    }
}

// 4. Fila de la Lista
struct UserRankRow: View {
    let user: User
    let rank: Int
    
    var body: some View {
        HStack(spacing: 15) {
            Text("#\(rank)")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.gray)
                .frame(width: 30)
            
            Image(systemName: "person.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.5))
            
            VStack(alignment: .leading) {
                Text(user.displayName)
                    .fontWeight(.semibold)
                Text("Nivel \(user.level ?? 1) • \(user.xp ?? 0) XP")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            
            if rank <= 10 {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
    }
}

// Helper para colores Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue:  Double(b) / 255, opacity: Double(a) / 255)
    }
}
