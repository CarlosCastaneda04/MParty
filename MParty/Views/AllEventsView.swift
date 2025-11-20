//
//  AllEventsView.swift
//  MParty
//
//  Created by Carlos Castaneda on 8/11/25.
//

import SwiftUI

struct AllEventsView: View {
    
    @EnvironmentObject var authViewModel: AuthViewModel
    // Usamos el mismo EventViewModel que ya creamos
    @StateObject private var viewModel = EventViewModel()
    
    @State private var searchText = ""
    
    // Filtra los eventos según el texto
    var filteredEvents: [Event] {
        if searchText.isEmpty {
            return viewModel.events
        } else {
            return viewModel.events.filter { event in
                event.title.localizedCaseInsensitiveContains(searchText) ||
                event.location.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) { // ZStack para el botón flotante (+)
                
                VStack(alignment: .leading) {
                    
                    // --- BUSCADOR ---
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Buscar torneos...", text: $searchText)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // --- CONTADOR DE RESULTADOS ---
                    if !viewModel.isLoading {
                        Text("\(filteredEvents.count) torneos encontrados")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.top, 5)
                    }
                    
                    // --- LISTA DE EVENTOS ---
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .padding(.top, 50)
                            } else if filteredEvents.isEmpty {
                                VStack {
                                    Image(systemName: "calendar.badge.exclamationmark")
                                        .font(.largeTitle)
                                        .padding()
                                    Text("No se encontraron torneos")
                                }
                                .foregroundColor(.secondary)
                                .padding(.top, 50)
                            } else {
                                ForEach(filteredEvents) { event in
                                    // Navegación al detalle
                                    NavigationLink(destination: EventDetailView(event: event)) {
                                        EventListCard(event: event)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .padding(.top)
                        .padding(.bottom, 80) // Espacio para el FAB
                    }
                    .refreshable {
                        await viewModel.fetchEvents()
                    }
                }
                
                // --- BOTÓN FLOTANTE (+) PARA ORGANIZADORES ---
                if let user = authViewModel.currentUser, user.role == "Organizador" {
                    NavigationLink(destination: CreateEventView()) {
                        Image(systemName: "plus")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.purple) // Color primario
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 4)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Todos los Torneos")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.fetchEvents()
            }
        }
    }
}

struct AllEventsView_Previews: PreviewProvider {
    static var previews: some View {
        AllEventsView()
            .environmentObject(AuthViewModel())
    }
}
