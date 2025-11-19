//
//  ProfileView.swift
//  MParty
//
//  Created by user285805 on 7/11/25.
//

import SwiftUI

struct ProfileView: View {
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        // Usamos un 'if let' para cargar el usuario de forma segura
        if let user = authViewModel.currentUser {
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    
                    // --- 1. Cabecera y Foto de Perfil ---
                    HeaderView(user: user)
                    
                    // --- 2. Botones de Acción ---
                    ProfileActionButtonsView(authViewModel: authViewModel)
                    
                    // --- 3. Tarjetas de Estadísticas ---
                    StatsView()
                    
                    // --- 4. Resumen de Organización (Pestañas) ---
                    SummaryView()
                    
                    Spacer()
                }
                .padding(.top, 20) // Espacio para que no pegue arriba
            }
            .navigationTitle("Perfil")
            .navigationBarTitleDisplayMode(.inline)
            
        } else {
            // Esto se ve si el usuario no ha cargado
            Text("Cargando perfil...")
        }
    }
}

// MARK: - Componentes de Perfil

struct HeaderView: View {
    let user: User
    
    var body: some View {
        VStack(spacing: 10) {
            // --- Banner de fondo (Placeholder) ---
            Rectangle()
                .fill(Color.purple.opacity(0.7))
                .frame(height: 120)
                .cornerRadius(15)
                .padding(.horizontal)
                .overlay(
                    // --- Foto de Perfil (Placeholder) ---
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                        .background(Color.gray.opacity(0.5))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                        .offset(y: 60) // Mueve la foto hacia abajo
                )
            
            // --- Información del Usuario ---
            Text(user.displayName)
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 60) // Espacio para la foto
            
            HStack(spacing: 10) {
                Text(user.pais ?? "Ubicación")
                Text("•")
                Text("Nivel \(user.level ?? 1)")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
    }
}

struct ProfileActionButtonsView: View {
    @ObservedObject var authViewModel: AuthViewModel
    
    var body: some View {
            HStack(spacing: 15) {

                // --- MODIFICACIÓN AQUÍ ---
                NavigationLink(destination: EditProfileView()) {
                    Text("Editar Perfil")
                        .fontWeight(.semibold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .foregroundColor(.primary) // Para que el texto no sea azul
                }
                // --- FIN DE LA MODIFICACIÓN ---

                // Botón de Cerrar Sesión (se queda igual)
                Button {
                    authViewModel.signOut()
                } label: {
                    // --- CÓDIGO AÑADIDO ---
                    Text("Cerrar Sesión")
                        .fontWeight(.semibold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(10)
                    // --- FIN DEL CÓDIGO AÑADIDO ---
                }
            }
            .padding(.horizontal)
        }
    }

struct StatsView: View {
    var body: some View {
        HStack(spacing: 10) {
            StatCard(title: "Creados", value: "12", color: .purple)
            StatCard(title: "Activos", value: "3", color: .green)
            StatCard(title: "Total Jugadores", value: "234", color: .gray)
        }
        .padding(.horizontal)
    }
    
    struct StatCard: View {
        let title: String
        let value: String
        let color: Color
        
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
            .background(color.opacity(0.1))
            .cornerRadius(10)
        }
    }
}

struct SummaryView: View {
    @State private var selectedTab = "General"
    
    var body: some View {
        VStack {
            HStack {
                Text("General")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(selectedTab == "General" ? Color.white : Color.clear)
                    .onTapGesture { selectedTab = "General" }
                
                Text("Torneos")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(selectedTab == "Torneos" ? Color.white : Color.clear)
                    .onTapGesture { selectedTab = "Torneos" }
            }
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 15) {
                Text("Resumen de Organización")
                    .font(.headline)
                    .padding(.top)
                
                ProgressRow(title: "Tasa de Éxito", value: "92%", progress: 0.92)
                ProgressRow(title: "Asistencia Promedio", value: "85%", progress: 0.85)
                ProgressRow(title: "Torneos Activos", value: "3 de 12 totales", progress: 0.25)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }
}

struct ProgressRow: View {
    let title: String
    let value: String
    let progress: Double
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                Spacer()
                Text(value)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            ProgressView(value: progress)
                .tint(.purple)
        }
    }
}


// ...
// --- Vista Previa ---
/* <-- AÑADE ESTO
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = AuthViewModel()
        
        viewModel.currentUser = User(
            id: "123",
            email: "host@test.com",
            displayName: "María García",
            profilePhotoURL: nil,
            role: "host",
            pais: "MX",
            xp: 1200,
            level: 24,
            hostCategory: "Oro",
            isPremiumSubscriber: false
        )
        
        NavigationStack {
            ProfileView()
                .environmentObject(viewModel)
        }
    }
}
*/ // <-- AÑADE ESTO
