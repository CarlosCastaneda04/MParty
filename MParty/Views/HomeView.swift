//
//  HomeView.swift
//  MParty
//
//  Created by user285805 on 7/11/25.
//

import SwiftUI

struct HomeView: View {
    
    // 1. Recibe el AuthViewModel para saber el rol
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // 2. Inyecta el cerebro de Eventos
    @StateObject private var eventViewModel = EventViewModel()
    
    @State private var searchText = ""
    
    var body: some View {
        if let user = authViewModel.currentUser {
            
            NavigationStack {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        TopBarView(user: user)
                        SearchBarView(searchText: $searchText)
                        
                        // --- 3. PANEL DE ESTADÍSTICAS (SEGÚN ROL) ---
                        if user.role == "Organizador" {
                            // Vista para el Host (AHORA RECIBE EL VIEWMODEL)
                            HostStatsView(user: user, eventViewModel: eventViewModel)
                        } else {
                            // Vista para el Jugador
                            PlayerHomeStatsView(user: user)
                        }
                        
                        // 4. Botones de Acción
                        HomeActionButtonsView(user: user)
                        
                        // 5. Sección Cerca de Ti
                        NearbyEventsView(viewModel: eventViewModel)
                        
                        Spacer()
                    }
                    .padding()
                }
                .navigationTitle("MParty")
                .navigationBarHidden(true)
                .task {
                    // 1. Carga TODOS los eventos
                    await eventViewModel.fetchEvents()
                    
                    // 2. Recarga datos del usuario (para ranking)
                    if let uid = user.id {
                        await authViewModel.fetchUser(uid: uid)
                        
                        // 3. NUEVO: Si es organizador, calcula sus estadísticas
                        if user.role == "Organizador" {
                            eventViewModel.fetchOrganizerStats(hostId: uid)
                        }
                    }
                }
            }
        } else {
            ProgressView()
        }
    }
}

// MARK: - Componentes de la Vista (Sub-vistas)

// --- VISTA DE ESTADÍSTICAS PARA JUGADOR (HOME) ---
struct PlayerHomeStatsView: View {
    let user: User
    
    var body: some View {
        VStack(spacing: 15) {
            HStack(spacing: 15) {
                // 1. Ranking Global (Morado)
                VStack(alignment: .leading) {
                    HStack {
                        Text("Ranking Global")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                    
                    Text("#\(user.globalRank ?? 0 > 0 ? String(user.globalRank!) : "-")")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("↑ 2 desde la semana pasada")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 110)
                .background(Color(hex: "6A5AE0"))
                .cornerRadius(15)
                
                // 2. % Victorias (Blanco)
                VStack(alignment: .leading) {
                    HStack {
                        Text("% Victorias")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                    }
                    
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(String(format: "%.0f", user.winRate))
                            .font(.system(size: 32, weight: .bold))
                        Text("%")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    
                    let losses = (user.tournamentsPlayed ?? 0) - (user.tournamentsWon ?? 0)
                    Text("\(user.tournamentsWon ?? 0)V - \(losses)D")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 110)
                .background(Color.white)
                .cornerRadius(15)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
            
            // 3. Nivel (Largo abajo)
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("Nivel")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                    
                    Text("\(user.level ?? 1)")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 6)
                            
                            Capsule()
                                .fill(Color.orange)
                                .frame(width: geo.size.width * (Double((user.xp ?? 0) % 100) / 100.0), height: 6)
                        }
                    }
                    .frame(height: 6)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

// --- 1. Barra Superior ---
struct TopBarView: View {
    let user: User
    var body: some View {
        HStack {
            Text("MParty")
                .font(.largeTitle)
                .fontWeight(.bold)
            Spacer()
            NavigationLink(destination: ProfileView()) {
                // --- Lógica para mostrar la foto real ---
                if let photoURL = user.profilePhotoURL, let url = URL(string: photoURL) {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                } else {
                    // Placeholder si no hay foto
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

// --- 2. Barra de Búsqueda ---
struct SearchBarView: View {
    @Binding var searchText: String
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Buscar torneos o jugadores...", text: $searchText)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// --- 3. Estadísticas del Host (ACTUALIZADA CON DATOS REALES) ---
struct HostStatsView: View {
    let user: User
    @ObservedObject var eventViewModel: EventViewModel // Recibe el ViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Tus Estadísticas de Organizador")
                .font(.headline)
            
            HStack(spacing: 15) {
                // DATOS REALES DEL VIEWMODEL
                StatCard(title: "Torneos Creados", value: "\(eventViewModel.createdCount)", icon: "trophy.fill", color: .purple)
                StatCard(title: "Participantes", value: "\(eventViewModel.totalPlayersCount)", icon: "person.2.fill", color: .green)
            }
            
            HStack {
                Image(systemName: "star.fill")
                    .font(.title)
                    .foregroundColor(.yellow)
                VStack(alignment: .leading) {
                    Text("Categoría")
                        .font(.caption)
                    Text(user.hostCategory ?? "Bronce")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}

// --- 4. Botones de Acción ---
struct HomeActionButtonsView: View {
    let user: User
    
    var body: some View {
        HStack(spacing: 10) {
            if user.role == "Organizador" {
                NavigationLink(destination: CreateEventView()) {
                    ActionButton(title: "Crear Torneo", icon: "plus", color: .purple)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            NavigationLink(destination: RankingView()) {
                ActionButton(title: "Rankings", icon: "chart.bar.xaxis", color: .green)
            }
            .buttonStyle(PlainButtonStyle())
            
            NavigationLink(destination: ProfileView()) {
                ActionButton(title: "Perfil", icon: "person.fill", color: .yellow)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// --- 5. Sección Cerca de Ti ---
struct NearbyEventsView: View {
    @ObservedObject var viewModel: EventViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Cerca de Ti")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("Ver Todos") { /* TODO */ }
            }
            
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.events.isEmpty {
                Text("¡Aún no hay eventos! Sé el primero en crear uno.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(viewModel.events) { event in
                    NavigationLink(destination: EventDetailView(event: event)) {
                        EventCardView(event: event)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

// --- TARJETA DE EVENTO ---
struct EventCardView: View {
    let event: Event
    
    var body: some View {
        VStack(alignment: .leading) {
            // Imagen (CORREGIDO: Ahora usa la URL real)
            Group {
                if let bannerURL = event.eventBannerURL, let url = URL(string: bannerURL) {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.overlay(ProgressView())
                    }
                } else {
                    Color.secondary
                        .overlay(
                            Text("Sin Imagen")
                                .foregroundColor(.white)
                        )
                }
            }
            .frame(height: 150)
            .clipped() // Recorta lo que sobre
            
            Text(event.title)
                .font(.headline)
                .padding([.horizontal, .top])
                .lineLimit(1)
            
            Text(event.mode)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(event.mode == "Competitivo" ? Color.red : Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding([.horizontal, .bottom])
        }
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
}


// MARK: - Piezas Reutilizables

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var body: some View {
        VStack(alignment: .leading) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
            Text(value)
                .font(.title)
                .fontWeight(.bold)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    var body: some View {
        VStack {
            Image(systemName: icon)
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.8))
        .foregroundColor(.white)
        .cornerRadius(10)
    }
}
