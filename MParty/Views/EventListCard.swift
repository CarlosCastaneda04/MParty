//
//  EventListCard.swift
//  MParty
//
//  Created by Carlos Castaneda on 8/11/25.
//

import SwiftUI
import FirebaseFirestore

struct EventListCard: View {
    let event: Event
    
    // Calcula el progreso de 0.0 a 1.0
    var progress: Double {
        return Double(event.currentPlayers) / Double(event.maxPlayers)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            // --- 1. IMAGEN Y HEADER ---
            ZStack(alignment: .bottomLeading) {
                // Placeholder de imagen
                Color.gray
                    .overlay(
                        AsyncImage(url: URL(string: "https://picsum.photos/seed/\(event.id ?? "")/600/300")) { img in
                            img.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray
                        }
                    )
                    .frame(height: 140)
                    .clipped()
                    .overlay(
                        LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                    )
                
                VStack(alignment: .leading) {
                    // Badge de Modalidad
                    Text(event.mode)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(event.mode == "Competitivo" ? Color.red : Color.green)
                        .cornerRadius(4)
                        .frame(maxWidth: .infinity, alignment: .trailing) // Alinear a la derecha
                        .offset(y: -80) // Subirlo a la esquina
                    
                    // Título
                    Text(event.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .padding(.bottom, 10)
                        .padding(.leading, 10)
                }
                .padding(.trailing, 10)
            }
            
            // --- 2. CUERPO DE LA TARJETA ---
            VStack(alignment: .leading, spacing: 12) {
                
                // Fecha y Hora
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.gray)
                    Text(event.eventDate.dateValue(), style: .date)
                    
                    Image(systemName: "clock")
                        .foregroundColor(.gray)
                        .padding(.leading, 10)
                    Text(event.eventDate.dateValue(), style: .time)
                }
                .font(.subheadline)
                .foregroundColor(.primary)
                
                // Ubicación
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.gray)
                    Text(event.location)
                        .lineLimit(1)
                }
                .font(.subheadline)
                .foregroundColor(.primary)
                
                // Barra de Progreso de Jugadores
                HStack {
                    Image(systemName: "person.2")
                        .foregroundColor(.gray)
                    Text("\(event.currentPlayers)/\(event.maxPlayers)")
                        .font(.caption)
                        .fontWeight(.bold)
                    
                    // Barra visual
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.gray.opacity(0.2))
                            Capsule().fill(Color.purple)
                                .frame(width: geo.size.width * progress)
                        }
                    }
                    .frame(height: 6)
                }
                
                // Organizador y Precio
                HStack {
                    Text(event.hostName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let fee = event.entryFee, event.isPaidEvent {
                        Text("$\(String(format: "%.0f", fee))")
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray6))
                            .cornerRadius(5)
                    } else {
                        Text("Gratis")
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }
                
                // --- 3. BOTÓN VER DETALLES ---
                Text("Ver Detalles")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.purple) // Tu color 'Brand'
                    .cornerRadius(10)
            }
            .padding(15)
        }
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal) // Margen lateral en la lista
    }
}
