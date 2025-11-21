//
//  EditProfileView.swift
//  MParty
//
//  Created by user285805 on 7/11/25.
//

import SwiftUI
import PhotosUI // Para el selector de fotos

struct EditProfileView: View {
    
    // 1. Recibe el "cerebro" de Autenticación
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // 2. NUEVO: Inicia el cerebro de Ubicación
    @StateObject private var locationManager = LocationManager()
    
    // 3. Para cerrar la vista (Cancelar, Guardar)
    @Environment(\.dismiss) var dismiss
    
    // 4. States para los campos editables
    @State private var fullName: String = ""
    @State private var pais: String = ""
    
    // 5. States para el selector de fotos
    @State private var selectedImageItem: PhotosPickerItem?
    @State private var selectedProfileImage: UIImage?
    
    var body: some View {
        if let user = authViewModel.currentUser {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    
                    // --- 1. Sección de Foto ---
                    PhotoPickerView(user: user, selectedProfileImage: $selectedProfileImage, selectedImageItem: $selectedImageItem)
                    
                    // --- 2. Información Personal (CON UBICACIÓN) ---
                    // Pasamos el locationManager aquí
                    PersonalDataView(fullName: $fullName, pais: $pais, user: user, locationManager: locationManager)
                    
                    // --- 3. Estadísticas (No editable) ---
                    StatsPreviewView(user: user)
                    
                    // --- 4. Consejos ---
                    TipsView()
                    
                    // --- 5. Botones de Guardar/Cancelar ---
                    SaveChangesButtons(
                        onSave: {
                            Task {
                                // Llama al ViewModel para guardar
                                await authViewModel.updateUserProfile(
                                    newFullName: fullName,
                                    newPais: pais,
                                    newProfileImage: selectedProfileImage
                                )
                                // Si todo salió bien, cierra la vista
                                if authViewModel.errorMessage == nil {
                                    dismiss()
                                }
                            }
                        },
                        onCancel: {
                            dismiss()
                        },
                        isLoading: authViewModel.isLoading
                    )
                    
                    // Muestra el error si falla el guardado
                    if let error = authViewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    // Muestra error de ubicación si falla
                    if let locError = locationManager.errorMessage {
                        Text(locError)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Editar Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Pre-llena los campos cuando la vista aparece
                self.fullName = user.displayName
                self.pais = user.pais ?? ""
                authViewModel.errorMessage = nil
            }
            .background(Color(.systemGray6))
            
        } else {
            Text("Cargando...")
        }
    }
}


// MARK: - Sub-Vistas

struct PhotoPickerView: View {
    let user: User
    @Binding var selectedProfileImage: UIImage?
    @Binding var selectedImageItem: PhotosPickerItem?
    
    var body: some View {
        VStack(spacing: 10) {
            Group {
                if let image = selectedProfileImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else if let photoURL = user.profilePhotoURL, let url = URL(string: photoURL) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)
                    }
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())
            .overlay(
                PhotosPicker(selection: $selectedImageItem, matching: .images) {
                    Image(systemName: "camera.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.purple)
                        .background(Color.white.clipShape(Circle()))
                }
                .offset(x: 35, y: 35)
            )
            
            Text("Haz clic en el ícono de la cámara para cambiar tu foto de perfil")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text("Formatos permitidos: JPG, PNG, GIF (máx. 5MB)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal)
        .onChange(of: selectedImageItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    if let uiImage = UIImage(data: data) {
                        selectedProfileImage = uiImage
                    }
                }
            }
        }
    }
}

// --- VISTA DE DATOS PERSONALES (ACTUALIZADA CON UBICACIÓN) ---
struct PersonalDataView: View {
    @Binding var fullName: String
    @Binding var pais: String
    let user: User
    
    // Recibimos el Manager
    @ObservedObject var locationManager: LocationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Información Personal")
                .font(.headline)
            
            // Nombre Completo
            Text("Nombre Completo")
                .font(.caption)
                .foregroundColor(.secondary)
            TextField("Nombre Completo", text: $fullName)
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            
            // Correo
            Text("Correo Electrónico")
                .font(.caption)
                .foregroundColor(.secondary)
            TextField("", text: .constant(user.email))
                .padding(12)
                .background(Color(.systemGray5))
                .cornerRadius(8)
                .disabled(true)
            
            // --- PAÍS CON BOTÓN DE UBICACIÓN ---
            Text("País")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                TextField("País", text: $pais)
                
                Button {
                    locationManager.requestLocation()
                } label: {
                    if locationManager.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "location.fill")
                            .foregroundColor(.purple)
                    }
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            // Escuchamos al manager: Si encuentra país, actualiza el campo
            .onChange(of: locationManager.country) { newCountry in
                if let country = newCountry {
                    self.pais = country
                }
            }
            
            // Tipo de Cuenta
            HStack {
                Image(systemName: "circle.fill")
                    .font(.caption)
                    .foregroundColor(.purple)
                Text("Tipo de cuenta:")
                    .font(.footnote)
                Text(user.role.capitalized)
                    .font(.footnote)
                    .fontWeight(.bold)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct StatsPreviewView: View {
    let user: User
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Estadísticas")
                .font(.headline)
            
            HStack(spacing: 10) {
                StatCard(title: "Nivel", value: "\(user.level ?? 1)")
                StatCard(title: "Ranking", value: "#\(user.globalRank ?? 0)")
                StatCard(title: "Torneos", value: "\(user.tournamentsPlayed ?? 0)")
            }
            
            Text("Las estadísticas no se pueden editar manualmente")
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    struct StatCard: View {
        let title: String
        let value: String
        
        var body: some View {
            VStack {
                Text(title)
                    .font(.caption)
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}

struct TipsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("💡 Consejos para tu perfil")
                .font(.headline)
            
            Text("• Usa una foto clara y profesional para tu avatar")
            Text("• Mantén tu información actualizada para recibir notificaciones")
            Text("• Tu nombre aparecerá en los rankings y torneos")
        }
        .font(.caption)
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct SaveChangesButtons: View {
    var onSave: () -> Void
    var onCancel: () -> Void
    var isLoading: Bool
    
    var body: some View {
        HStack(spacing: 10) {
            Button {
                onCancel()
            } label: {
                Text("Cancelar")
                    .fontWeight(.semibold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(10)
            }
            
            Button {
                onSave()
            } label: {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple.opacity(0.7))
                        .cornerRadius(10)
                } else {
                    Text("Guardar Cambios")
                        .fontWeight(.semibold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .disabled(isLoading)
        }
        .padding(.horizontal)
    }
}
