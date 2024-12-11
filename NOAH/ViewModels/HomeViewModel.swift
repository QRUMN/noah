import SwiftUI
import CoreLocation

class HomeViewModel: ObservableObject {
    @Published var currentWeather: CurrentWeatherViewModel
    @Published var hourlyForecast: [HourlyForecastItem]
    @Published var dailyForecast: [DailyForecastItem]
    @Published var weatherDetails: WeatherDetails
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showCheckIn = false
    @Published var showCrisisResources = false
    
    private let locationManager = CLLocationManager()
    private let weatherService = WeatherService()
    
    init() {
        // Initialize with placeholder data
        self.currentWeather = CurrentWeatherViewModel(
            location: "Loading...",
            date: "...",
            temperature: "--°",
            condition: "Loading",
            feelsLike: "--°"
        )
        self.hourlyForecast = []
        self.dailyForecast = []
        self.weatherDetails = WeatherDetails(
            humidity: 0,
            windSpeed: 0,
            pressure: 0,
            visibility: 0,
            uvIndex: 0
        )
        
        setupLocationManager()
        Task {
            await refreshWeather()
        }
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    @MainActor
    func refreshWeather() async {
        isLoading = true
        
        guard let location = locationManager.location else {
            locationManager.requestLocation()
            isLoading = false
            return
        }
        
        do {
            let weather = try await weatherService.fetchWeather(for: location)
            updateWeatherData(with: weather)
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    private func updateWeatherData(with weather: WeatherData) {
        self.currentWeather = CurrentWeatherViewModel(
            location: weather.location,
            date: formatDate(weather.date),
            temperature: formatTemperature(weather.temperature),
            condition: weather.condition,
            feelsLike: formatTemperature(weather.feelsLike)
        )
        
        self.hourlyForecast = weather.hourlyForecast.map { forecast in
            HourlyForecastItem(
                id: UUID(),
                time: formatTime(forecast.time),
                temperature: formatTemperature(forecast.temperature),
                condition: forecast.condition
            )
        }
        
        self.dailyForecast = weather.dailyForecast.map { forecast in
            DailyForecastItem(
                id: UUID(),
                day: formatDay(forecast.date),
                high: formatTemperature(forecast.highTemperature),
                low: formatTemperature(forecast.lowTemperature),
                condition: forecast.condition
            )
        }
        
        self.weatherDetails = weather.details
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        return formatter.string(from: date)
    }
    
    private func formatDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
    
    private func formatTemperature(_ temperature: Double) -> String {
        return String(format: "%.0f°", temperature)
    }
}

extension HomeViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task {
            await refreshWeather()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.error = error
    }
}
