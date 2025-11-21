//
//  RegistrationView.swift
//  MParty
//
//  Created by user285805 on 7/11/25.
//


import SwiftUI

struct RegistrationView: View {
    
    // 1. Recibe el "cerebro" de Autenticación
    @EnvironmentObject var viewModel: AuthViewModel
    
    // 2. NUEVO: El cerebro para la ubicación
    @StateObject private var locationManager = LocationManager()
    
    let role: String
    
    @State private var fullName = ""
    @State private var email = ""
    @State private var pais = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    @State private var validationError: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                Text("Únete a la comunidad de MParty")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 10)
                
                // --- Campo de Nombre ---
                TextField("Nombre Completo", text: $fullName)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                
                // --- Campo de Correo ---
                TextField("Correo Electrónico", text: $email)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                // --- Campo de País (CON AUTODETECCIÓN) ---
                HStack {
                    TextField("País", text: $pais)
                    
                    // Botón para pedir ubicación
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
                .cornerRadius(10)
                // Escuchamos al manager: Si encuentra país, actualiza el campo
                .onChange(of: locationManager.country) { newCountry in
                    if let country = newCountry {
                        self.pais = country
                    }
                }

                // --- Campo de Contraseña ---
                SecurePasswordView(passwordText: $password, title: "Contraseña")
                
                // --- Campo de Confirmar ---
                SecurePasswordView(passwordText: $confirmPassword, title: "Confirmar Contraseña")
                
                // --- Muestra el rol seleccionado ---
                Text("Tipo de cuenta seleccionado: \(role)")
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .background(Color.purple.opacity(0.1))
                    .foregroundColor(.purple)
                    .cornerRadius(8)
                
                // --- Botón de Crear Cuenta ---
                Button {
                    validateAndRegister()
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple.opacity(0.7))
                            .cornerRadius(10)
                    } else {
                        Text("Crear Cuenta")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .cornerRadius(10)
                    }
                }
                .disabled(viewModel.isLoading)
                
                // --- Mensajes de Error ---
                if let error = validationError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                } else if let locError = locationManager.errorMessage {
                    // Error de ubicación si falla
                    Text(locError)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Text("Al registrarte, aceptas nuestros Términos de Servicio...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
                
                Spacer()
                
            }
            .padding(.horizontal, 30)
            .padding(.top, 20)
        }
        .navigationTitle("Crear Cuenta")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // --- FUNCIÓN DE VALIDACIÓN ---
    private func validateAndRegister() {
        if fullName.isEmpty || email.isEmpty || pais.isEmpty || password.isEmpty {
            validationError = "Por favor, llena todos los campos."
            viewModel.errorMessage = nil
            return
        }
        
        if password != confirmPassword {
            validationError = "Las contraseñas no coinciden."
            viewModel.errorMessage = nil
            return
        }
        
        if password.count < 6 {
            validationError = "La contraseña debe tener al menos 6 caracteres."
            viewModel.errorMessage = nil
            return
        }
        
        validationError = nil
        
        Task {
            await viewModel.createUser(
                withEmail: email,
                password: password,
                fullName: fullName,
                pais: pais,
                role: role
            )
        }
    }
}
