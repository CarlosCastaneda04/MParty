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
    
    // 2. NUEVO: Inyecta el cerebro de Eventos
    @StateObject private var eventViewModel = EventViewModel()
    
    @State private var searchText = ""
    
    var body: some View {
        // Usamos un 'if let' para asegurarnos de que tenemos los datos del usuario
        if let user = authViewModel.currentUser {
            
            NavigationStack {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        TopBarView(user: user)
                        SearchBarView(searchText: $searchText)
                        
                        if user.role == "Organizador" {
                            HostStatsView(user: user)
                        }
                        
                        // 3. ACTUALIZADO: Pasa el 'user'
                        HomeActionButtonsView(user: user)
                        
                        // 4. ACTUALIZADO: Pasa el ViewModel
                        NearbyEventsView(viewModel: eventViewModel)
                        
                        Spacer()
                    }
                    .padding()
                }
                .navigationTitle("MParty")
                .navigationBarHidden(true)
                .task {
                    // 5. NUEVO: Carga los eventos cuando aparece el Home
                    await eventViewModel.fetchEvents()
                }
            }
        } else {
            ProgressView()
        }
    }
}

// --- Vista Previa ---
// (Comentada para evitar errores de 'init' complejos)
/*
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = AuthViewModel()
        viewModel.currentUser = User(
            id: "123", email: "host@test.com", displayName: "Host de Prueba",
            role: "host", pais: "El Salvador", hostCategory: "Oro"
        )
        
        return HomeView()
            .environmentObject(viewModel)
    }
}
*/


// MARK: - Componentes de la Vista (Sub-vistas)

// --- 1. Barra Superior (Sin cambios) ---
struct TopBarView: View {
    let user: User
    var body: some View {
        HStack {
            Text("MParty")
                .font(.largeTitle)
                .fontWeight(.bold)
            Spacer()
            NavigationLink(destination: ProfileView()) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
            }
        }
    }
}

// --- 2. Barra de Búsqueda (Sin cambios) ---
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

// --- 3. Estadísticas del Host (Sin cambios) ---
struct HostStatsView: View {
    let user: User
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Tus Estadísticas de Organizador") //...
            // ... (el resto del código de esta vista se queda igual) ...
            HStack(spacing: 15) {
                StatCard(title: "Torneos Creados", value: "12", icon: "trophy.fill", color: .purple)
                StatCard(title: "Participantes", value: "234", icon: "person.2.fill", color: .green)
            }
            HStack {
                Image(systemName: "star.fill") // ...
                VStack(alignment: .leading) {
                    Text("Categoría") // ...
                    Text(user.hostCategory ?? "Bronce") // ...
                }
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}

// --- 4. Botones de Acción (CON NAVEGACIÓN A "CREAR") ---
struct HomeActionButtonsView: View {
    let user: User
    
    var body: some View {
        HStack(spacing: 10) {
            // --- MODIFICACIÓN CLAVE ---
            // Solo se muestra si es 'host'
            if user.role == "Organizador" {
                // Ahora es un NavigationLink
                NavigationLink(destination: CreateEventView()) {
                    ActionButton(title: "Crear Torneo", icon: "plus", color: .purple)
                }
                .buttonStyle(PlainButtonStyle())
            }
            // --- FIN DE LA MODIFICACIÓN ---
            
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

// --- 5. Sección Cerca de Ti (CON DATOS REALES) ---
struct NearbyEventsView: View {
    
    // Recibe el ViewModel
    @ObservedObject var viewModel: EventViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Cerca de Ti")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("Ver Todos") { /* TODO: Navegar */ }
            }
            
            // --- MODIFICACIÓN CLAVE ---
            // Muestra los eventos leídos de Firebase
            if viewModel.isLoading {
                ProgressView() // Muestra 'cargando'
            } else if viewModel.events.isEmpty {
                Text("¡Aún no hay eventos! Sé el primero en crear uno.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                // Hay eventos, los muestra en un ForEach
                ForEach(viewModel.events) { event in
                    // Cada tarjeta es un NavigationLink a la vista de detalle
                    NavigationLink(destination: EventDetailView(event: event)) {
                        EventCardView(event: event)
                    }
                    .buttonStyle(PlainButtonStyle()) // Quita el tinte azul
                }
            }
        }
    }
}

// --- TARJETA DE EVENTO (NUEVA) ---
struct EventCardView: View {
    let event: Event
    
    var body: some View {
        VStack(alignment: .leading) {
            // Placeholder de la imagen
            Color.secondary
                .frame(height: 150)
                .overlay(
                    Text("Imagen del Evento (Próximamente)")
                        .foregroundColor(.white)
                )
            
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


// MARK: - Piezas Reutilizables (Sin cambios)

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
