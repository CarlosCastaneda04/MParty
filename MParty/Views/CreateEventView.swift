//
//  CreateEventView.swift
//  MParty
//
//  Created by user285805 on 7/11/25.
//


import SwiftUI

struct CreateEventView: View {
    
    // 1. El cerebro para guardar el evento
    @StateObject private var viewModel = EventViewModel()
    // 2. El cerebro para saber QUIÉN crea el evento
    @EnvironmentObject var authViewModel: AuthViewModel
    // 3. Para cerrar la vista (Cancelar, Guardar)
    @Environment(\.dismiss) var dismiss
    
    // --- States para todos los campos del formulario ---
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var gameType: String = "Ajedrez" // Valor inicial
    @State private var eventDate: Date = Date()
    @State private var location: String = ""
    @State private var mode: String = "Amistoso"
    @State private var maxPlayers: Int = 16
    @State private var isPaidEvent: Bool = false
    
    // Opciones para los Pickers
    let gameOptions = ["Ajedrez", "Monopoly", "Cartas", "Catan", "Otro"]
    let modeOptions = ["Amistoso", "Competitivo"]
    let playerOptions = [2, 4, 8, 16, 32]
    
    var body: some View {
        if let user = authViewModel.currentUser {
            Form { // 'Form' es genial para este tipo de vistas
                // --- Sección 1: Información Básica ---
                Section(header: Text("Información Básica")) {
                    TextField("Nombre del Torneo", text: $title)
                    TextField("Describe tu torneo...", text: $description, axis: .vertical)
                        .lineLimit(4...)
                    Picker("Juego", selection: $gameType) {
                        ForEach(gameOptions, id: \.self) { Text($0) }
                    }
                }
                
                // --- Sección 2: Fecha y Hora ---
                Section(header: Text("Fecha y Hora")) {
                    DatePicker(
                        "Fecha y Hora",
                        selection: $eventDate,
                        in: Date()..., // Solo fechas futuras
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
                
                // --- Sección 3: Ubicación ---
                Section(header: Text("Ubicación")) {
                    TextField("Dirección del Lugar", text: $location)
                }
                
                // --- Sección 4: Configuración ---
                Section(header: Text("Configuración del Torneo")) {
                    Picker("Tipo de Torneo", selection: $mode) {
                        ForEach(modeOptions, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.segmented)
                    
                    Picker("Máximo de Jugadores", selection: $maxPlayers) {
                        ForEach(playerOptions, id: \.self) { Text("\($0) Jugadores") }
                    }
                    
                    Toggle("Torneo de Pago", isOn: $isPaidEvent)
                }
                
                // --- Sección 5: Disclaimer ---
                Section {
                    Text("Al crear este torneo, aceptas: Proporcionar información precisa, Honrar inscripciones, etc.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // --- Sección 6: Botones ---
                Section {
                    Button {
                        // --- Acción de Crear Torneo ---
                        Task {
                            let success = await viewModel.createEvent(
                                title: title,
                                description: description,
                                gameType: gameType,
                                eventDate: eventDate,
                                location: location,
                                mode: mode,
                                maxPlayers: maxPlayers,
                                isPaidEvent: isPaidEvent,
                                host: user // Pasa el usuario 'host'
                            )
                            
                            if success {
                                dismiss() // Cierra la vista si tuvo éxito
                            }
                        }
                    } label: {
                        Text("Crear Torneo")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                    }
                    .tint(.purple)
                    
                    Button("Cancelar", role: .destructive) {
                        dismiss() // Solo cierra la vista
                    }
                }
            }
            .navigationTitle("Crear Torneo")
            .navigationBarTitleDisplayMode(.inline)
            .disabled(viewModel.isLoading) // Desactiva el form mientras carga
            .overlay(
                // Muestra el círculo de carga
                viewModel.isLoading ? ProgressView() : nil
            )
            .overlay(
                // Muestra el error
                Text(viewModel.errorMessage ?? "")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding()
            )
            
        } else {
            Text("Error: No se pudo cargar el usuario.")
        }
    }
}
