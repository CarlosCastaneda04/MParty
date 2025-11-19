//
//  LoginView.swift
//  MParty
//
//  Created by user285805 on 7/11/25.
//
import SwiftUI

struct LoginView: View {
    
    // 1. RECIBE el "cerebro" (ViewModel) desde MPartyApp
    @EnvironmentObject var viewModel: AuthViewModel
    
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                
                Spacer()
                
                Image(systemName: "trophy.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.purple)
                
                Text("Bienvenido a MParty")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Inicia sesión para continuar")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 15) {
                    Text("Correo Electrónico")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    TextField("tu@gmail.com", text: $email)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    SecurePasswordView(passwordText: $password, title: "Contraseña")
                }
                
                Button {
                    Task {
                        // 2. Llama al "cerebro" que recibió
                        await viewModel.signIn(withEmail: email, password: password)
                    }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple.opacity(0.7))
                            .cornerRadius(10)
                    } else {
                        Text("Iniciar Sesión")
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
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Spacer()
                
                HStack {
                    Text("¿No tienes cuenta?")
                    NavigationLink("Regístrate") {
                        RoleSelectionView()
                    }
                    .foregroundColor(.purple)
                    .fontWeight(.bold)
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 30)
            
            // 3. Importante: Como esta vista (LoginView) recibe el
            // ViewModel, también debe pasárselo a la siguiente
            // vista (RoleSelectionView) para que no se "rompa" la cadena.
            // PERO... SwiftUI es lo bastante inteligente para pasarlo
            // automáticamente a través del NavigationLink.
            // Si no lo hiciera, lo añadiríamos aquí.
        }
    }
}
