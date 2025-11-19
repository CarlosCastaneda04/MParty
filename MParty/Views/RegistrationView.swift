//
//  RegistrationView.swift
//  MParty
//
//  Created by user285805 on 7/11/25.
//
import SwiftUI

struct RegistrationView: View {
    
    // 1. RECIBE el "cerebro" (ViewModel)
    @EnvironmentObject var viewModel: AuthViewModel
    
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
                
                TextField("Nombre Completo", text: $fullName)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                
                TextField("Correo Electrónico", text: $email)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                TextField("País", text: $pais)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                SecurePasswordView(passwordText: $password, title: "Contraseña")
                
                SecurePasswordView(passwordText: $confirmPassword, title: "Confirmar Contraseña")
                
                Text("Tipo de cuenta seleccionado: \(role)")
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .background(Color.purple.opacity(0.1))
                    .foregroundColor(.purple)
                    .cornerRadius(8)
                
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
                
                if let error = validationError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                } else if let error = viewModel.errorMessage {
                    Text(error)
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
            // 2. Llama al "cerebro" que recibió
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
