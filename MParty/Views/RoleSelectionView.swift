//
//  RoleSelectionView.swift
//  MParty
//
//  Created by user285805 on 7/11/25.
//

import SwiftUI

struct RoleSelectionView: View {
    
    // "Jugador" o "Organizador"
    @State private var selectedRole: String = "Jugador"
    
    var body: some View {
        VStack(spacing: 25) {
            
            // --- Título ---
            Text("Elige tu Camino")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)
            
            Text("Selecciona el tipo de cuenta que mejor se adapte a ti")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            
            // --- Botón de Jugador ---
            RoleButton(
                icon: "person.fill", // Placeholder del ícono
                title: "Jugador",
                subtitle: "Únete a torneos, compite globalmente y escala en el ranking",
                isSelected: selectedRole == "Jugador"
            )
            .onTapGesture {
                selectedRole = "Jugador"
            }
            
            // --- Botón de Organizador ---
            RoleButton(
                icon: "person.3.fill", // Placeholder del ícono
                title: "Organizador",
                subtitle: "Organiza eventos, construye comunidad y gana reputación",
                isSelected: selectedRole == "Organizador"
            )
            .onTapGesture {
                selectedRole = "Organizador"
            }
            
            Spacer()
            
            // --- Botón de Continuar ---
            // Pasa el rol seleccionado a la siguiente vista
            NavigationLink {
                RegistrationView(role: selectedRole)
            } label: {
                Text("Continuar")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .cornerRadius(10)
            }
            
        }
        .padding(.horizontal, 30)
        .navigationTitle("Crear Cuenta") // Pone el título en la barra de navegación
        .navigationBarTitleDisplayMode(.inline)
    }
}

// --- Vista de apoyo para los botones de rol ---
struct RoleButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(isSelected ? .purple : .secondary)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.green)
            }
        }
        .padding(20)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        // El borde seleccionado de tu diseño
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? .purple : Color.clear, lineWidth: 2)
        )
    }
}

struct RoleSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        // Para previsualizar, mételo en un NavigationStack
        NavigationStack {
            RoleSelectionView()
        }
    }
}
