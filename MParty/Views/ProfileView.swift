//
//  ProfileView.swift
//  MParty
//
//  Created by user285805 on 7/11/25.
//

import SwiftUI
import FirebaseCore

struct ProfileView: View {
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // Inyectamos el EventViewModel para calcular estadísticas y listar torneos
    @StateObject private var eventViewModel = EventViewModel()
    
    var body: some View {
        if let user = authViewModel.currentUser {
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    
                    // 1. Cabecera (Compartida)
                    HeaderView(user: user)
                    
                    // 2. Botones Acción (Compartidos)
                    ProfileActionButtonsView(authViewModel: authViewModel)
                    
                    // 3. Estadísticas (DIFERENCIADAS)
                    if user.role == "Organizador" {
                        // Le pasamos el ViewModel para que muestre los contadores calculados
                        OrganizerStatsView(eventViewModel: eventViewModel)
                    } else {
                        // Le pasamos el User para que muestre sus stats de jugador
                        PlayerStatsView(user: user)
                    }
                    
                    // 4. Sección Inferior (DIFERENCIADA)
                    if user.role == "Organizador" {
                        // Lista de torneos creados
                        OrganizerSummaryView(eventViewModel: eventViewModel)
                    } else {
                        // Barras de rendimiento del jugador
                        PlayerPerformanceView(user: user)
                    }
                    
                    Spacer()
                }
                .padding(.top, 20)
            }
            .navigationTitle("Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                // Si es organizador, cargamos los eventos Y calculamos las estadísticas
                if user.role == "Organizador" {
                    await eventViewModel.fetchEvents() // Baja los datos
                    // Calcula las estadísticas específicas para este Host ID
                    eventViewModel.fetchOrganizerStats(hostId: user.id ?? "")
                }
            }
            
        } else {
            Text("Cargando perfil...")
        }
    }
}

// MARK: - 1. Cabecera y Botones (Compartidos)

struct HeaderView: View {
    let user: User
    var body: some View {
        VStack(spacing: 10) {
            Rectangle()
                .fill(
                    LinearGradient(colors: [Color.purple, Color.blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(height: 100)
                .cornerRadius(15)
                .padding(.horizontal)
                .overlay(
                    // Foto de perfil
                    Group {
                        if let photoURL = user.profilePhotoURL, let url = URL(string: photoURL) {
                            AsyncImage(url: url) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.white)
                            }
                        } else {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: 100, height: 100)
                    .background(Color.orange.opacity(0.8))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                    .offset(y: 50)
                    , alignment: .bottom
                )
                .padding(.bottom, 40)
            
            Text(user.displayName)
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(spacing: 5) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(.gray)
                Text(user.pais ?? "Ubicación")
                Text("•")
                Text("Nivel \(user.level ?? 1)")
                    .foregroundColor(.gray)
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
    }
}

struct ProfileActionButtonsView: View {
    @ObservedObject var authViewModel: AuthViewModel
    var body: some View {
        HStack(spacing: 15) {
            NavigationLink(destination: EditProfileView()) {
                Label("Editar Perfil", systemImage: "square.and.pencil")
                    .fontWeight(.semibold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                    .foregroundColor(.black)
                    .cornerRadius(10)
            }
            
            Button {
                authViewModel.signOut()
            } label: {
                Label("Cerrar Sesión", systemImage: "rectangle.portrait.and.arrow.right")
                    .fontWeight(.semibold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.05))
                    .foregroundColor(.red)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.red.opacity(0.3), lineWidth: 1))
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - 2. Estadísticas (Diferenciadas)

// Vista para ORGANIZADOR (3 Tarjetas con datos del ViewModel)
struct OrganizerStatsView: View {
    @ObservedObject var eventViewModel: EventViewModel // <-- Recibe el ViewModel
    
    var body: some View {
        HStack(spacing: 10) {
            StatBox(label: "Creados", value: "\(eventViewModel.createdCount)", bgColor: .purple, textColor: .white)
            StatBox(label: "Activos", value: "\(eventViewModel.activeCount)", bgColor: .white, textColor: .green)
            StatBox(label: "Total Jugadores", value: "\(eventViewModel.totalPlayersCount)", bgColor: .white, textColor: .black)
        }
        .padding(.horizontal)
    }
}

// Vista para JUGADOR (4 Tarjetas con datos del User)
struct PlayerStatsView: View {
    let user: User
    var body: some View {
        HStack(spacing: 10) {
            // Ranking (Morado Grande)
            VStack {
                Text("Ranking")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                // Muestra el ranking o un guion si es 0
                Text(user.globalRank ?? 0 > 0 ? "#\(user.globalRank!)" : "-")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .frame(width: 90, height: 90)
            .background(Color.purple)
            .cornerRadius(15)
            
            // % Victorias
            StatBoxSimple(label: "% Vict.", value: String(format: "%.0f", user.winRate), valueColor: .green, unit: "%")
            
            // Victorias
            StatBoxSimple(label: "Victorias", value: "\(user.tournamentsWon ?? 0)", valueColor: .black)
            
            // Torneos Jugados
            StatBoxSimple(label: "Torneos", value: "\(user.tournamentsPlayed ?? 0)", valueColor: .black)
        }
        .padding(.horizontal)
    }
}

// Auxiliar para cajitas simples (Jugador)
struct StatBoxSimple: View {
    let label: String
    let value: String
    let valueColor: Color
    var unit: String = ""
    
    var body: some View {
        VStack(spacing: 5) {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            
            VStack(spacing: 0) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(valueColor)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption2)
                        .foregroundColor(valueColor)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 90)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.gray.opacity(0.1), lineWidth: 1))
    }
}

// Auxiliar para cajitas (Organizador)
struct StatBox: View {
    let label: String
    let value: String
    let bgColor: Color
    let textColor: Color
    
    var body: some View {
        VStack {
            Text(label)
                .font(.caption)
                .foregroundColor(textColor == .white ? .white.opacity(0.8) : .gray)
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(textColor)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .background(bgColor)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.gray.opacity(0.1), lineWidth: 1))
    }
}

// MARK: - 3. Sección Inferior (Diferenciada)

// ORGANIZADOR: Pestañas + Lista de sus torneos
struct OrganizerSummaryView: View {
    @ObservedObject var eventViewModel: EventViewModel
    @State private var selectedTab = "Torneos"
    
    var body: some View {
        VStack(spacing: 15) {
            // Selector
            HStack {
                TabButton(title: "General", selectedTab: $selectedTab)
                TabButton(title: "Torneos", selectedTab: $selectedTab)
            }
            .padding(4)
            .background(Color(.systemGray6))
            .cornerRadius(25)
            .padding(.horizontal)
            
            if selectedTab == "General" {
                // --- PESTAÑA GENERAL (ACTUALIZADA CON DATOS REALES) ---
                VStack(alignment: .leading, spacing: 15) {
                    Text("Resumen de Organización")
                        .font(.headline)
                        .padding(.top)
                    
                    // 1. Tasa de Éxito (Torneos Finalizados vs Totales)
                    ProgressRow(
                        title: "Tasa de Éxito",
                        value: String(format: "%.0f%%", eventViewModel.successRate * 100),
                        progress: eventViewModel.successRate
                    )
                    
                    // 2. Asistencia Promedio
                    // Calculamos el número real para mostrarlo en texto
                    let realAvg = eventViewModel.createdCount > 0 ? Double(eventViewModel.totalPlayersCount) / Double(eventViewModel.createdCount) : 0.0
                    
                    ProgressRow(
                        title: "Asistencia Promedio",
                        value: String(format: "%.1f / torneo", realAvg),
                        progress: eventViewModel.averageAttendance // Usamos el valor normalizado (0-1) para la barra
                    )
                    
                    // 3. Torneos Activos
                    ProgressRow(
                        title: "Torneos Activos",
                        value: "\(eventViewModel.activeCount) de \(eventViewModel.createdCount) totales",
                        progress: eventViewModel.activeRatio
                    )
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
            } else {
                // LISTA DE TORNEOS DE ESTE ORGANIZADOR
                VStack(spacing: 15) {
                    if eventViewModel.organizerEvents.isEmpty {
                        Text("No has creado torneos aún.")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(eventViewModel.organizerEvents) { event in
                            EventListMiniCard(event: event)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// JUGADOR: Resumen de Desempeño
struct PlayerPerformanceView: View {
    let user: User
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Resumen de Desempeño")
                .font(.headline)
            
            // % de Victorias
            ProgressBarRow(
                label: "% de Victorias",
                valueText: String(format: "%.1f", user.winRate),
                subText: "%",
                progress: user.winRate / 100,
                color: .black
            )
            
            // Progreso de Nivel
            ProgressBarRow(
                label: "Progreso de Nivel",
                valueText: "Nivel \(user.level ?? 1)",
                subText: "",
                progress: 0.45, // Placeholder (podrías calcularlo con user.xp)
                color: .black
            )
            
            // Actividad (Torneos jugados)
            ProgressBarRow(
                label: "Actividad",
                valueText: "\(user.tournamentsPlayed ?? 0)",
                subText: "torneos",
                // Meta arbitraria de 100 para la barra visual
                progress: Double(user.tournamentsPlayed ?? 0) / 100.0,
                color: .black
            )
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}


// MARK: - Componentes Auxiliares UI

struct TabButton: View {
    let title: String
    @Binding var selectedTab: String
    var body: some View {
        Button(action: { selectedTab = title }) {
            Text(title)
                .font(.subheadline)
                .fontWeight(selectedTab == title ? .semibold : .regular)
                .foregroundColor(selectedTab == title ? .black : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(selectedTab == title ? Color.white : Color.clear)
                .cornerRadius(20)
                .shadow(color: selectedTab == title ? .black.opacity(0.1) : .clear, radius: 2)
        }
    }
}

struct ProgressBarRow: View {
    let label: String
    let valueText: String
    let subText: String
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Spacer()
                Text(valueText)
                    .fontWeight(.bold) +
                Text(" " + subText)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                    
                    Capsule()
                        .fill(color)
                        .frame(width: min(geo.size.width * progress, geo.size.width), height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}

// Tarjeta pequeña de evento para la lista del perfil
struct EventListMiniCard: View {
    let event: Event
    var body: some View {
        HStack(spacing: 15) {
            // Imagen pequeña (CORREGIDO: Ahora usa la URL real)
            Group {
                if let bannerURL = event.eventBannerURL, let url = URL(string: bannerURL) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Color.gray
                    }
                } else {
                    Color.gray // Placeholder si no hay imagen
                }
            }
            .frame(width: 80, height: 80)
            .cornerRadius(10)
            .clipped() // Importante para recortar la imagen
            
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(event.title)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .lineLimit(1)
                    Spacer()
                    Text(event.status == "Disponible" ? "Próximo" : event.status)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple)
                        .cornerRadius(8)
                }
                
                Text(event.gameType)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    // Usamos el format simple para evitar errores de importación en esta vista
                    Text(event.eventDate.dateValue().formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                    
                    Spacer()
                    
                    Text("\(event.currentPlayers)/\(event.maxPlayers) jugadores")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .foregroundColor(.gray)
            }
        }
        .padding(10)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.gray.opacity(0.1), lineWidth: 1))
    }
}
struct ProgressRow: View {
    let title: String
    let value: String
    let progress: Double
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                Spacer()
                Text(value)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            ProgressView(value: progress)
                .tint(.purple)
        }
    }
}
