//
//  CreateEventView.swift
//  MParty
//
//  Created by user285805 on 7/11/25.
//


import SwiftUI
import PhotosUI

struct CreateEventView: View {
    
    @StateObject private var viewModel = EventViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var locationManager = LocationManager()
    @Environment(\.dismiss) var dismiss
    
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var gameType: String = "Ajedrez"
    @State private var eventDate: Date = Date()
    @State private var location: String = ""
    @State private var mode: String = "Amistoso"
    @State private var maxPlayers: Int = 16
    @State private var isPaidEvent: Bool = false
    
    // Pago
    @State private var entryFeeString: String = "10"
    @State private var showPaymentSheet = false // <-- PARA MOSTRAR LA HOJA
    
    // Imagen
    @State private var selectedBannerItem: PhotosPickerItem?
    @State private var selectedBannerImage: UIImage?
    
    let gameOptions = ["Ajedrez", "Monopoly", "Cartas", "Catan", "Otro"]
    let modeOptions = ["Amistoso", "Competitivo"]
    let playerOptions = [2, 4, 8, 10, 16, 32]
    
    // Calculadora de ganancias (mismo modelo simple)
    var appFee: Double {
        let fee = Double(entryFeeString) ?? 0
        return (fee * 10) * 0.17 // 17% del pot total (precio * 10 jugadores)
    }
    
    var body: some View {
        if let user = authViewModel.currentUser {
            Form {
                // --- SECCIÓN 0: BANNER ---
                Section {
                    VStack(spacing: 10) {
                        if let image = selectedBannerImage {
                            Image(uiImage: image).resizable().scaledToFill().frame(height: 150).cornerRadius(10).clipped()
                        } else {
                            Rectangle().fill(Color(.systemGray5)).frame(height: 150).cornerRadius(10).overlay(
                                VStack {
                                    Image(systemName: "photo.badge.plus").font(.system(size: 30)).foregroundColor(.purple)
                                    Text("Añadir Banner").font(.caption).foregroundColor(.secondary)
                                }
                            )
                        }
                    }
                    .overlay(PhotosPicker(selection: $selectedBannerItem, matching: .images) { Color.clear })
                    .listRowInsets(EdgeInsets())
                }
                .onChange(of: selectedBannerItem) { newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            if let uiImage = UIImage(data: data) { selectedBannerImage = uiImage }
                        }
                    }
                }
                
                // --- INFORMACIÓN BÁSICA ---
                Section(header: Text("Información Básica")) {
                    TextField("Nombre del Torneo", text: $title)
                    TextField("Describe tu torneo...", text: $description, axis: .vertical).lineLimit(3...)
                    Picker("Juego", selection: $gameType) {
                        ForEach(gameOptions, id: \.self) { Text($0) }
                    }
                }
                
                Section(header: Text("Fecha y Ubicación")) {
                    DatePicker("Fecha y Hora", selection: $eventDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                    HStack {
                        TextField("Dirección", text: $location)
                        Button { locationManager.requestLocation() } label: {
                            if locationManager.isLoading { ProgressView() } else { Image(systemName: "location.fill").foregroundColor(.purple) }
                        }
                    }
                    .onChange(of: locationManager.address) { newAddress in if let address = newAddress { self.location = address } }
                }
                
                // --- CONFIGURACIÓN Y PAGO ---
                Section(header: Text("Configuración")) {
                    Picker("Tipo", selection: $mode) {
                        ForEach(modeOptions, id: \.self) { Text($0) }
                    }.pickerStyle(.segmented)
                    
                    Toggle("Torneo de Paga (Con Premios)", isOn: $isPaidEvent)
                        .tint(.green)
                        .onChange(of: isPaidEvent) { isPaid in
                            if isPaid {
                                maxPlayers = 10
                                mode = "Competitivo"
                            }
                        }
                    
                    if isPaidEvent {
                        HStack {
                            Text("Precio de Entrada ($)")
                            Spacer()
                            TextField("0", text: $entryFeeString)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                        }
                        Text("🔒 Los torneos de paga están limitados a 10 jugadores.").font(.caption).foregroundColor(.secondary)
                        
                        // Desglose rápido
                        HStack {
                            Text("Comisión por crear:")
                            Spacer()
                            Text("$\(String(format: "%.2f", appFee))").bold().foregroundColor(.red)
                        }
                    } else {
                        Picker("Jugadores", selection: $maxPlayers) {
                            ForEach(playerOptions, id: \.self) { Text("\($0)") }
                        }
                    }
                }
                
                // --- BOTONES ---
                Section {
                    Button {
                        if isPaidEvent {
                            // Mostrar Hoja de Pago
                            showPaymentSheet = true
                        } else {
                            // Crear directo
                            Task { await submitEvent(user: user) }
                        }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView().frame(maxWidth: .infinity)
                        } else {
                            Text(isPaidEvent ? "Pagar $\(String(format: "%.0f", appFee)) y Crear" : "Crear Torneo")
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .tint(isPaidEvent ? .green : .purple)
                    .disabled(title.isEmpty || location.isEmpty)
                    
                    Button("Cancelar", role: .destructive) { dismiss() }
                }
            }
            .navigationTitle("Crear Torneo")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showPaymentSheet) {
                // AQUÍ LLAMAMOS A LA NUEVA HOJA DE PAGO BONITA
                PaymentSheetView(
                    title: "Creación de Torneo",
                    subtitle: title,
                    amount: appFee,
                    onPaymentSuccess: {
                        Task { await submitEvent(user: user) }
                    }
                )
                .presentationDetents([.large]) // Pantalla completa para que se vea bien
            }
            .overlay(
                VStack {
                    if let error = viewModel.errorMessage {
                        Text(error).font(.caption).foregroundColor(.white).padding().background(Color.red).cornerRadius(10).padding(.top, 50)
                        Spacer()
                    }
                }
            )
            
        } else {
            Text("Error de usuario")
        }
    }
    
    func submitEvent(user: User) async {
        let entryFeeDouble = Double(entryFeeString)
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
            bannerImage: selectedBannerImage,
            entryFee: entryFeeDouble
        )
        if success { dismiss() }
    }
}
