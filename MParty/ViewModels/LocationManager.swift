//
//  LocationManage.swift
//  MParty
//
//  Created by Carlos Castaneda on 10/11/25.
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    private let locationManager = CLLocationManager()
    
    @Published var location: CLLocation?
    @Published var country: String?
    @Published var address: String? // Dirección completa (Calle, Ciudad, País)
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocation() {
        isLoading = true
        errorMessage = nil
        
        // Pedir permiso si no lo tiene
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if locationManager.authorizationStatus == .denied {
            errorMessage = "Permiso de ubicación denegado. Habilítalo en Configuración."
            isLoading = false
        } else {
            locationManager.requestLocation()
        }
    }
    
    // --- Delegado: Se llama cuando se actualiza la ubicación ---
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.location = location
        
        // Geocoding Inverso (Convertir coordenadas a dirección)
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = "Error obteniendo dirección: \(error.localizedDescription)"
                return
            }
            
            if let placemark = placemarks?.first {
                // Obtener País
                self.country = placemark.country
                
                // Construir Dirección Completa (Ej: "Calle 123, San Salvador, El Salvador")
                var addressString = ""
                if let street = placemark.thoroughfare { addressString += street + ", " }
                if let city = placemark.locality { addressString += city + ", " }
                if let country = placemark.country { addressString += country }
                
                self.address = addressString
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("DEBUG: Error de ubicación: \(error.localizedDescription)")
        self.isLoading = false
        self.errorMessage = "No se pudo obtener la ubicación."
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // Si el usuario da permiso, intentamos pedir la ubicación de nuevo
        if manager.authorizationStatus == .authorizedWhenInUse {
            manager.requestLocation()
        }
    }
}
