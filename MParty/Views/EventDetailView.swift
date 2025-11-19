//
//  EventDetailView.swift
//  MParty
//
//  Created by user285805 on 7/11/25.
//

import SwiftUI
import FirebaseFirestore // ¡Importante para el .dateValue()!

struct EventDetailView: View {
    
    // 1. El cerebro para ESTA vista. Se crea usando el 'init'
    @StateObject private var viewModel: EventDetailViewModel
    
    // 2. El cerebro global, para saber quién es el usuario actual
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // 3. State para las pestañas "General" / "Jugadores"
    @State private var selectedTab: String = "General"
    
    // 4. El 'init' que recibe el evento desde HomeView
    init(event: Event) {
        _viewModel = StateObject(wrappedValue: EventDetailViewModel(event: event))
    }
    
    var body: some View {
        // 5. Asegúrate de que tenemos al usuario actual
        if let user = authViewModel.currentUser {
            
            ZStack(alignment: .bottom) { // ZStack para el botón flotante
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // --- 1. Banner (usaremos el 'event' del viewModel) ---
                        EventBannerView(event: viewModel.event)
                        
                        // --- 2. Info Rápida (Fecha, Hora, Ubicación) ---
                        InfoCard(event: viewModel.event)
                        
                        // --- 3. Organizador ---
                        OrganizerCard(hostName: viewModel.event.hostName)
                        
                        // --- 4. Selector de Pestañas ---
                        TabSelector(selectedTab: $selectedTab)
                        
                        // --- 5. Contenido de la Pestaña ---
                        if selectedTab == "General" {
                            // Muestra la info general
                            DetailsCard(event: viewModel.event)
                        } else {
                            // Muestra la lista de jugadores inscritos
                            PlayersListView(participants: viewModel.participants)
                        }
                        
                        // Espacio extra para que el botón no tape
                        Spacer().frame(height: 100)
                    }
                }
                .ignoresSafeArea(edges: .top) // Para que la imagen pegue arriba
                
                // --- 6. El Botón de "Unirme" (flotante) ---
                FooterButtonView(
                    viewModel: viewModel,
                    user: user
                )
            }
            .navigationTitle(viewModel.event.title)
            .navigationBarTitleDisplayMode(.inline)
            .task {
                // 7. Carga los datos (participantes) cuando la vista aparece
                await viewModel.fetchEventData(userId: user.id ?? "")
            }
        } else {
            ProgressView() // Muestra 'cargando' si no hay usuario
        }
    }
}

// MARK: - Sub-vistas de Detalle (Actualizadas)

struct EventBannerView: View {
    let event: Event
    var body: some View {
        // TODO: Reemplazar con AsyncImage y 'event.eventBannerURL'
        Color.secondary
            .frame(height: 200)
            .overlay(
                VStack {
                    Spacer()
                    Text(event.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                }
            )
    }
}

struct InfoCard: View {
    let event: Event
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: "calendar")
                Text(event.eventDate.dateValue(), style: .date)
                Spacer()
                Image(systemName: "clock")
                Text(event.eventDate.dateValue(), style: .time)
            }
            HStack {
                Image(systemName: "location.fill")
                Text(event.location)
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct OrganizerCard: View {
    let hostName: String
    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            VStack(alignment: .leading) {
                Text("Organizador")
                    .font(.caption)
                Text(hostName)
                    .fontWeight(.bold)
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct TabSelector: View {
    @Binding var selectedTab: String
    
    var body: some View {
        HStack {
            Text("General")
                .fontWeight(selectedTab == "General" ? .bold : .regular)
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedTab == "General" ? Color.white : Color.clear)
                .onTapGesture { selectedTab = "General" }
            
            Text("Jugadores")
                .fontWeight(selectedTab == "Jugadores" ? .bold : .regular)
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedTab == "Jugadores" ? Color.white : Color.clear)
                .onTapGesture { selectedTab = "Jugadores" }
        }
        .background(Color(.systemGray5))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct DetailsCard: View {
    let event: Event
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sobre este Torneo")
                .font(.title2)
                .fontWeight(.bold)
            Text(event.description)
            Divider()
            DetailRow(title: "Tipo de Juego", value: event.gameType)
            DetailRow(title: "Modalidad", value: event.mode)
            DetailRow(title: "Máx. Jugadores", value: "\(event.maxPlayers)")
            DetailRow(title: "Estado", value: event.status)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

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

// --- NUEVA VISTA: Lista de Jugadores ---
struct PlayersListView: View {
    let participants: [Participant]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Jugadores Inscritos (\(participants.count))")
                .font(.title2)
                .fontWeight(.bold)
            
            if participants.isEmpty {
                Text("¡Sé el primero en unirte!")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(participants) { player in
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 30))
                        VStack(alignment: .leading) {
                            Text(player.displayName).fontWeight(.bold)
                            Text("Nivel \(player.level) • Rank #\(player.rank)")
                                .font(.caption)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 5)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// --- NUEVA VISTA: El Botón de Abajo ---
struct FooterButtonView: View {
    @ObservedObject var viewModel: EventDetailViewModel
    let user: User
    
    var body: some View {
        VStack {
            // Lógica de error
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            // Lógica del botón
            if user.role == "Organizador" {
                // --- Caso 1: Eres un Host ---
                Text("Los organizadores no pueden unirse a torneos")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .cornerRadius(10)
                
            } else if viewModel.hasCurrentUserJoined {
                // --- Caso 2: Eres Jugador Y YA TE UNISTE ---
                Button {
                    Task { await viewModel.cancelParticipation(userId: user.id ?? "") }
                } label: {
                    Text("Cancelar Participación")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                }
                
            } else {
                // --- Caso 3: Eres Jugador Y NO TE HAS UNIDO ---
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
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(.bar) // Un fondo semi-transparente
    }
}




