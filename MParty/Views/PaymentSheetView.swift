//
//  PaymentSheetView.swift
//  MParty
//
//  Created by Carlos Castaneda on 16/11/25.
//

import SwiftUI

struct PaymentSheetView: View {
    
    // Título del concepto (ej. "Inscripción a Torneo" o "Creación de Torneo")
    let title: String
    let subtitle: String
    let amount: Double
    var onPaymentSuccess: () -> Void
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var paymentService = PaymentService()
    
    @State private var cardNumber = ""
    @State private var expiry = ""
    @State private var cvc = ""
    @State private var cardHolderName = "USUARIO MPARTY"
    
    // Detectar tipo de tarjeta
    var cardType: (name: String, color1: Color, color2: Color) {
        if cardNumber.hasPrefix("4") {
            return ("VISA", Color.blue, Color.purple)
        } else if cardNumber.hasPrefix("5") {
            return ("MASTERCARD", Color.orange, Color.red)
        }
        return ("TARJETA", Color.gray, Color.black)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    
                    // --- 1. TARJETA VISUAL ---
                    VStack {
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [cardType.color1, cardType.color2],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(height: 220)
                                .shadow(color: cardType.color1.opacity(0.5), radius: 20, x: 0, y: 10)
                            
                            // Brillo
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 200, height: 200)
                                .offset(x: 150, y: -50)
                            
                            VStack(alignment: .leading, spacing: 0) {
                                HStack {
                                    Image(systemName: "wave.3.right")
                                        .font(.system(size: 40))
                                        .foregroundColor(.white.opacity(0.8))
                                    Spacer()
                                    if cardNumber.hasPrefix("4") {
                                        Text("VISA").font(.title).fontWeight(.bold).italic().foregroundColor(.white)
                                    } else if cardNumber.hasPrefix("5") {
                                        HStack(spacing: -5) {
                                            Circle().fill(Color.red).frame(width: 30)
                                            Circle().fill(Color.orange).frame(width: 30)
                                        }
                                    } else {
                                        Image(systemName: "creditcard.fill").font(.title).foregroundColor(.white)
                                    }
                                }
                                .padding(.bottom, 40)
                                
                                Text(cardNumber.isEmpty ? "0000 0000 0000 0000" : formatCreditCard(cardNumber))
                                    .font(.system(size: 26, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.white)
                                    .shadow(radius: 2)
                                    .minimumScaleFactor(0.5)
                                
                                Spacer()
                                
                                HStack(alignment: .bottom) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("TITULAR").font(.caption2).fontWeight(.bold).foregroundColor(.white.opacity(0.6))
                                        Text(cardHolderName).font(.headline).fontWeight(.bold).foregroundColor(.white)
                                    }
                                    Spacer()
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("EXPIRA").font(.caption2).fontWeight(.bold).foregroundColor(.white.opacity(0.6))
                                        Text(expiry.isEmpty ? "MM/YY" : formatExpiryDate(expiry)).font(.headline).fontWeight(.bold).foregroundColor(.white)
                                    }
                                }
                            }
                            .padding(25)
                        }
                        .frame(height: 220)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    // --- 2. FORMULARIO ---
                    VStack(spacing: 20) {
                        CustomTextField(title: "Número de Tarjeta", icon: "creditcard.fill", text: $cardNumber, limit: 16)
                        HStack(spacing: 15) {
                            CustomTextField(title: "MM/YY", icon: "calendar", text: $expiry, limit: 4)
                            CustomTextField(title: "CVC", icon: "lock.fill", text: $cvc, limit: 3)
                        }
                    }
                    .padding(.horizontal)
                    
                    // --- 3. RESUMEN DE PAGO ---
                    VStack(spacing: 10) {
                        HStack {
                            Text("Concepto").foregroundColor(.secondary)
                            Spacer()
                            Text(title).fontWeight(.medium)
                        }
                        if !subtitle.isEmpty {
                            HStack {
                                Text("Detalle").foregroundColor(.secondary)
                                Spacer()
                                Text(subtitle).fontWeight(.medium).foregroundColor(.gray)
                            }
                        }
                        Divider()
                        HStack {
                            Text("Total a Pagar").font(.headline)
                            Spacer()
                            Text("$\(String(format: "%.2f", amount))").font(.title3).fontWeight(.bold).foregroundColor(.primary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // --- 4. BOTÓN PAGAR ---
                    Button {
                        Task {
                            let success = await paymentService.processPayment(amount: amount, cardLast4: String(cardNumber.suffix(4)))
                            if success {
                                onPaymentSuccess()
                                dismiss()
                            }
                        }
                    } label: {
                        HStack {
                            if paymentService.isProcessing {
                                ProgressView().padding(.trailing, 5)
                            } else {
                                Image(systemName: "lock.fill")
                            }
                            Text("Pagar $\(String(format: "%.2f", amount))")
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isValid ? Color.green : Color.gray)
                        .cornerRadius(15)
                        .shadow(color: isValid ? Color.green.opacity(0.4) : Color.clear, radius: 10, x: 0, y: 5)
                    }
                    .disabled(!isValid || paymentService.isProcessing)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Pago Seguro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }
    
    var isValid: Bool {
        return cardNumber.count == 16 && expiry.count == 4 && cvc.count == 3
    }
    
    func formatCreditCard(_ number: String) -> String {
        var formatted = ""
        for (index, char) in number.enumerated() {
            if index > 0 && index % 4 == 0 { formatted += " " }
            formatted.append(char)
        }
        return formatted
    }
    
    func formatExpiryDate(_ date: String) -> String {
        var formatted = ""
        for (index, char) in date.enumerated() {
            if index == 2 { formatted += "/" }
            formatted.append(char)
        }
        return formatted
    }
}
//PaymentSheetView.swift ---

struct CustomTextField: View {
    let title: String
    let icon: String
    @Binding var text: String
    let limit: Int
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 20)
            
            TextField(title, text: $text)
                .keyboardType(.numberPad)
                // Usamos fuente monospaced para que los números se alineen bien
                .font(.system(size: 18, weight: .medium, design: .monospaced))
                .onChange(of: text) { newValue in
                    // Filtra solo números
                    let filtered = newValue.filter { "0123456789".contains($0) }
                    // Corta si pasa el límite
                    if filtered.count > limit {
                        text = String(filtered.prefix(limit))
                    } else {
                        text = filtered
                    }
                }
            
            // Check verde si está completo
            if !text.isEmpty {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(text.count == limit ? .green : .gray)
                    .font(.caption)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        // Borde sutil
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}
