//
//  CreateEventView.swift
//  MParty
//
//  Created by user285805 on 7/11/25.
//


import SwiftUI
import PhotosUI // Para el selector de fotos

struct CreateEventView: View {
    
    // 1. El cerebro para guardar el evento
    @StateObject private var viewModel = EventViewModel()
    
    // 2. El cerebro para saber QUIÉN crea el evento
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // 3. El cerebro para la ubicación
    @StateObject private var locationManager = LocationManager()
    
    // 4. Para cerrar la vista (Cancelar, Guardar)
    @Environment(\.dismiss) var dismiss
    
    // --- States para todos los campos del formulario ---
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var gameType: String = "Ajedrez"
    @State private var eventDate: Date = Date()
    @State private var location: String = ""
    @State private var mode: String = "Amistoso"
    @State private var maxPlayers: Int = 16
    @State private var isPaidEvent: Bool = false
    
    // --- IMAGEN DEL BANNER (NUEVO) ---
    @State private var selectedBannerItem: PhotosPickerItem?
    @State private var selectedBannerImage: UIImage?
    
    // Opciones para los Pickers
    let gameOptions = ["Ajedrez", "Monopoly", "Cartas", "Catan", "Otro"]
    let modeOptions = ["Amistoso", "Competitivo"]
    let playerOptions = [2, 4, 8, 16, 32]
    
    var body: some View {
        if let user = authViewModel.currentUser {
            Form {
                
                // --- SECCIÓN 0: BANNER DEL EVENTO ---
                Section {
                    VStack(spacing: 10) {
                        if let image = selectedBannerImage {
                            // Muestra la imagen seleccionada
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 150)
                                .cornerRadius(10)
                                .clipped()
                        } else {
                            // Placeholder
                            Rectangle()
                                .fill(Color(.systemGray5))
                                .frame(height: 150)
                                .cornerRadius(10)
                                .overlay(
                                    VStack {
                                        Image(systemName: "photo.badge.plus")
                                            .font(.system(size: 30))
                                            .foregroundColor(.purple)
                                        Text("Añadir Banner")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                )
                        }
                    }
                    .overlay(
                        // El selector invisible encima
                        PhotosPicker(selection: $selectedBannerItem, matching: .images) {
                            Color.clear // Hace que toda el área sea tocable
                        }
                    )
                    .listRowInsets(EdgeInsets()) // Quita márgenes de la lista
                }
                .onChange(of: selectedBannerItem) { newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            if let uiImage = UIImage(data: data) {
                                selectedBannerImage = uiImage
                            }
                        }
                    }
                }
                
                // --- Sección 1: Información Básica ---
                Section(header: Text("Información Básica")) {
                    TextField("Nombre del Torneo", text: $title)
                    TextField("Describe tu torneo...", text: $description, axis: .vertical)
                        .lineLimit(3...)
                    Picker("Juego", selection: $gameType) {
                        ForEach(gameOptions, id: \.self) { Text($0) }
                    }
                }
                
                // --- Sección 2: Fecha y Hora ---
                Section(header: Text("Fecha y Hora")) {
                    DatePicker(
                        "Fecha y Hora",
                        selection: $eventDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
                
                // --- Sección 3: Ubicación ---
                Section(header: Text("Ubicación")) {
                    HStack {
                        TextField("Dirección del Lugar", text: $location)
                        
                        Button {
                            locationManager.requestLocation()
                        } label: {
                            if locationManager.isLoading {
                                ProgressView().scaleEffect(0.8)
                            } else {
                                Image(systemName: "location.fill").foregroundColor(.purple)
                            }
                        }
                    }
                    .onChange(of: locationManager.address) { newAddress in
                        if let address = newAddress {
                            self.location = address
                        }
                    }
                    
                    if let locError = locationManager.errorMessage {
                        Text(locError).font(.caption).foregroundColor(.red)
                    }
                }
                
                // --- Sección 4: Configuración ---
                Section(header: Text("Configuración")) {
                    Picker("Tipo", selection: $mode) {
                        ForEach(modeOptions, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.segmented)
                    
                    Picker("Jugadores", selection: $maxPlayers) {
                        ForEach(playerOptions, id: \.self) { Text("\($0)") }
                    }
                    
                    Toggle("Torneo de Pago", isOn: $isPaidEvent)
                }
                
                // --- Botones ---
                Section {
                    Button {
                        Task {
                            // Llama al ViewModel con todos los datos, INCLUYENDO LA IMAGEN
                            let success = await viewModel.createEvent(
                                title: title,
                                description: description,
                                gameType: gameType,
                                eventDate: eventDate,
                                location: location,
                                mode: mode,
                                maxPlayers: maxPlayers,
                                isPaidEvent: isPaidEvent,
                                host: user,
                                bannerImage: selectedBannerImage // <-- AQUÍ PASAMOS LA IMAGEN
                            )
                            
                            if success {
                                dismiss()
                            }
                        }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("Crear Torneo")
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .tint(.purple)
                    .disabled(title.isEmpty || location.isEmpty)
                    
                    Button("Cancelar", role: .destructive) {
                        dismiss()
                    }
                }
            }
            .navigationTitle("Crear Torneo")
            .navigationBarTitleDisplayMode(.inline)
            .disabled(viewModel.isLoading)
            .overlay(
                VStack {
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(10)
                            .padding(.top, 50)
                        Spacer()
                    }
                }
            )
            
        } else {
            Text("Error: No se pudo cargar el usuario.")
        }
    }
}
