//
//  EventDetailView.swift
//  MParty
//
//  Created by user285805 on 7/11/25.
//

import SwiftUI
import FirebaseFirestore

struct EventDetailView: View {
    
    @StateObject private var viewModel: EventDetailViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // Para poder regresar manualmente (ya que quitamos la barra por defecto)
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedTab: String = "General"
    
    init(event: Event) {
        _viewModel = StateObject(wrappedValue: EventDetailViewModel(event: event))
    }
    
    var body: some View {
        if let user = authViewModel.currentUser {
            
            ZStack(alignment: .bottom) {
                
                // --- CONTENIDO PRINCIPAL (Scroll) ---
                ScrollView {
                    VStack(spacing: 0) {
                        
                        // 1. HEADER CON IMAGEN Y BADGES
                        // (Pasa el evento y la acción de dismiss)
                        CustomHeaderView(event: viewModel.event, onDismiss: {
                            dismiss()
                        })
                        
                        // 2. CONTENIDO DEL CUERPO
                        VStack(alignment: .leading, spacing: 20) {
                            
                            // Fecha y Ubicación
                            InfoCard(event: viewModel.event)
                            
                            // Organizador
                            OrganizerCard(hostName: viewModel.event.hostName, category: "Diamante") // Placeholder categoría
                            
                            // Pestañas
                            TabSelector(selectedTab: $selectedTab)
                            
                            if selectedTab == "General" {
                                DetailsCard(event: viewModel.event)
                            } else {
                                PlayersListView(participants: viewModel.participants)
                            }
                            
                            // Espacio extra para que el botón flotante no tape el final
                            Spacer().frame(height: 120)
                        }
                        .padding(.top, 20) // Espacio entre imagen y contenido
                        .background(Color(.systemGroupedBackground)) // Color de fondo grisáceo suave
                    }
                }
                .edgesIgnoringSafeArea(.top) // ¡Clave para que la imagen toque el borde superior!
                
                // --- 3. BARRA FLOTANTE INFERIOR ---
                FooterButtonView(
                    viewModel: viewModel,
                    user: user
                )
            }
            // OCULTAR ELEMENTOS NATIVOS
            .navigationBarHidden(true)        // Oculta la barra de título estándar
            .toolbar(.hidden, for: .tabBar)   // Oculta la barra de pestañas inferior (iOS 16+)
            .task {
                await viewModel.fetchEventData(userId: user.id ?? "")
            }
            
        } else {
            ProgressView()
        }
    }
}

// MARK: - NUEVO HEADER PERSONALIZADO (Estilo Figma)

struct CustomHeaderView: View {
    let event: Event
    var onDismiss: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            
            // A. IMAGEN DE FONDO
            // (Usamos Color.gray como placeholder, aquí iría tu AsyncImage)
            GeometryReader { geometry in
                Color.gray // TODO: Cambiar por AsyncImage(url: ...)
                    .overlay(
                        // Un gradiente oscuro abajo para que el texto blanco se lea bien
                        LinearGradient(
                            gradient: Gradient(colors: [.clear, .black.opacity(0.8)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .frame(height: 300) // Altura fija para el header
            
            // B. BOTÓN ATRÁS (Top Left)
            Button(action: { onDismiss() }) {
                Image(systemName: "arrow.left")
                    .font(.title3)
                    .foregroundColor(.black)
                    .padding(10)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .padding(.top, 50) // Ajuste para Safe Area (Isla dinámica/Notch)
            .padding(.leading, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            
            // C. TÍTULO Y BADGES (Bottom Left)
            VStack(alignment: .leading, spacing: 8) {
                
                // Badges
                HStack {
                    // Badge Modalidad (Rojo)
                    Text(event.mode)
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                    
                    // Badge Juego (Blanco)
                    Text(event.gameType)
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(4)
                }
                
                // Título Grande
                Text(event.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(radius: 2)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(height: 300)
    }
}

// MARK: - COMPONENTES ESTILIZADOS

struct InfoCard: View {
    let event: Event
    var body: some View {
        VStack(spacing: 0) {
            // Fila Fecha
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.purple)
                    .frame(width: 30)
                VStack(alignment: .leading) {
                    Text("Fecha")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(event.eventDate.dateValue(), style: .date)
                        .fontWeight(.semibold)
                }
                Spacer()
                
                // Hora (Lado derecho)
                Image(systemName: "clock")
                    .foregroundColor(.green)
                VStack(alignment: .trailing) {
                    Text("Hora")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(event.eventDate.dateValue(), style: .time)
                        .fontWeight(.semibold)
                }
            }
            .padding()
            
            Divider().padding(.leading, 50) // Línea separadora
            
            // Fila Ubicación
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(.gray)
                    .frame(width: 30)
                VStack(alignment: .leading) {
                    Text("Ubicación")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(event.location)
                        .fontWeight(.semibold)
                }
                Spacer()
            }
            .padding()
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}

struct OrganizerCard: View {
    let hostName: String
    let category: String // "Oro", "Diamante", etc.
    
    var body: some View {
        HStack(spacing: 15) {
            // Avatar
            Image(systemName: "person.crop.circle.fill") // Placeholder
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundColor(.orange) // Color placeholder
            
            VStack(alignment: .leading) {
                Text("Organizador")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(hostName)
                    .font(.headline)
                
                // Badge Categoría pequeña
                Text(category.capitalized)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
            }
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}

struct TabSelector: View {
    @Binding var selectedTab: String
    var body: some View {
        HStack(spacing: 0) {
            // Botón General
            Button(action: { selectedTab = "General" }) {
                Text("General")
                    .font(.subheadline)
                    .fontWeight(selectedTab == "General" ? .semibold : .regular)
                    .foregroundColor(selectedTab == "General" ? .black : .gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(selectedTab == "General" ? Color.white : Color.clear)
                    .cornerRadius(20)
                    .shadow(color: selectedTab == "General" ? .black.opacity(0.1) : .clear, radius: 2)
            }
            
            // Botón Jugadores
            Button(action: { selectedTab = "Jugadores" }) {
                Text("Jugadores")
                    .font(.subheadline)
                    .fontWeight(selectedTab == "Jugadores" ? .semibold : .regular)
                    .foregroundColor(selectedTab == "Jugadores" ? .black : .gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(selectedTab == "Jugadores" ? Color.white : Color.clear)
                    .cornerRadius(20)
                    .shadow(color: selectedTab == "Jugadores" ? .black.opacity(0.1) : .clear, radius: 2)
            }
        }
        .padding(4)
        .background(Color(.systemGray6))
        .cornerRadius(25)
        .padding(.horizontal)
    }
}

struct DetailsCard: View {
    let event: Event
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Sobre este Torneo")
                .font(.headline)
            
            Text(event.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineSpacing(4)
            
            Divider().padding(.vertical, 5)
            
            // Grilla de detalles
            VStack(spacing: 12) {
                DetailRow(title: "Tipo de Juego", value: event.gameType)
                DetailRow(title: "Modalidad", value: event.mode)
                DetailRow(title: "Máx. Jugadores", value: "\(event.maxPlayers)")
                DetailRow(title: "Estado", value: event.status)
                
                // Precio (si aplica)
                if let fee = event.entryFee, event.isPaidEvent {
                    DetailRow(title: "Inscripción", value: "$\(String(format: "%.2f", fee))")
                } else {
                    DetailRow(title: "Inscripción", value: "Gratis")
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20) // Más redondeado arriba
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}

// --- BOTTOM BAR (PIE DE PÁGINA) MEJORADO ---
struct FooterButtonView: View {
    @ObservedObject var viewModel: EventDetailViewModel
    let user: User
    
    var body: some View {
        VStack(spacing: 15) {
            
            // Info de Disponibles y Precio
            HStack {
                Image(systemName: "person.2")
                    .foregroundColor(.gray)
                Text("Disponibles: \(viewModel.event.maxPlayers - viewModel.participants.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let fee = viewModel.event.entryFee, viewModel.event.isPaidEvent {
                    Text("$\(String(format: "%.2f", fee))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                } else {
                    Text("Gratis")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            
            // Mensaje de error si existe
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            // El Botón Grande
            if user.role == "Organizador" {
                Text("Los organizadores no pueden unirse a torneos")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                
            } else if viewModel.hasCurrentUserJoined {
                Button {
                    Task { await viewModel.cancelParticipation(userId: user.id ?? "") }
                } label: {
                    Text("Cancelar Participación")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                }
                
            } else {
                Button {
                    Task { await viewModel.joinEvent(user: user) }
                } label: {
                    Text("Unirme al Torneo")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .cornerRadius(12)
                }
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 10) // Espacio extra abajo para iPhones sin botón
        .padding(.horizontal)
        .background(Color.white)
        // Sombra superior para separar del contenido
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
    }
}

// Pequeño helper para las filas
struct DetailRow: View {
    let title: String
    let value: String
    var body: some View {
        HStack {
            Text(title).foregroundColor(.secondary)
            Spacer()
            Text(value).fontWeight(.semibold)
        }
    }
}

// Lista de jugadores (sin cambios, pero necesaria para que compile)
struct PlayersListView: View {
    let participants: [Participant]
    var body: some View {
        VStack(alignment: .leading) {
            Text("Jugadores Inscritos (\(participants.count))")
                .font(.headline)
                .padding(.bottom, 5)
            
            if participants.isEmpty {
                Text("¡Sé el primero en unirte!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                ForEach(participants) { player in
                    HStack {
                        // Número de ranking (placeholder)
                        Text("#\(player.rank > 0 ? String(player.rank) : "-")")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(width: 30)
                        
                        VStack(alignment: .leading) {
                            Text(player.displayName)
                                .fontWeight(.semibold)
                            Text("Nivel \(player.level) • Rank \(player.rank)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
                }
            }
        }
        .padding(.horizontal)
    }
}




