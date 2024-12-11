import Foundation
import CoreLocation

class WeatherService {
    private let apiKey = "YOUR_WEATHER_API_KEY" // Replace with actual API key
    private let baseURL = "https://api.openweathermap.org/data/2.5"
    
    func fetchWeather(for location: CLLocation) async throws -> WeatherData {
        let urlString = "\(baseURL)/onecall?lat=\(location.coordinate.latitude)&lon=\(location.coordinate.longitude)&appid=\(apiKey)&units=imperial"
        
        guard let url = URL(string: urlString) else {
            throw WeatherError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw WeatherError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        
        do {
            let weatherResponse = try decoder.decode(WeatherResponse.self, from: data)
            return createWeatherData(from: weatherResponse)
        } catch {
            throw WeatherError.invalidData
        }
    }
    
    private func createWeatherData(from response: WeatherResponse) -> WeatherData {
        return WeatherData(
            location: response.timezone,
            date: Date(),
            temperature: response.current.temp,
            feelsLike: response.current.feels_like,
            condition: response.current.weather.first?.main ?? "Unknown",
            hourlyForecast: response.hourly.prefix(24).map { hourly in
                HourlyForecast(
                    time: Date(timeIntervalSince1970: TimeInterval(hourly.dt)),
                    temperature: hourly.temp,
                    condition: hourly.weather.first?.main ?? "Unknown"
                )
            },
            dailyForecast: response.daily.prefix(7).map { daily in
                DailyForecast(
                    date: Date(timeIntervalSince1970: TimeInterval(daily.dt)),
                    highTemperature: daily.temp.max,
                    lowTemperature: daily.temp.min,
                    condition: daily.weather.first?.main ?? "Unknown"
                )
            },
            details: WeatherDetails(
                humidity: response.current.humidity,
                windSpeed: response.current.wind_speed,
                pressure: response.current.pressure,
                visibility: response.current.visibility / 1000, // Convert to km
                uvIndex: response.current.uvi
            )
        )
    }
}

enum WeatherError: Error {
    case invalidURL
    case invalidResponse
    case invalidData
}

// MARK: - Response Models

struct WeatherResponse: Codable {
    let lat: Double
    let lon: Double
    let timezone: String
    let current: Current
    let hourly: [Current]
    let daily: [Daily]
}

struct Current: Codable {
    let dt: Int
    let temp: Double
    let feels_like: Double
    let pressure: Double
    let humidity: Double
    let uvi: Double
    let visibility: Double
    let wind_speed: Double
    let weather: [Weather]
}

struct Weather: Codable {
    let main: String
    let description: String
    let icon: String
}

struct Daily: Codable {
    let dt: Int
    let temp: Temperature
    let weather: [Weather]
}

struct Temperature: Codable {
    let min: Double
    let max: Double
}

// MARK: - Domain Models

struct WeatherData {
    let location: String
    let date: Date
    let temperature: Double
    let feelsLike: Double
    let condition: String
    let hourlyForecast: [HourlyForecast]
    let dailyForecast: [DailyForecast]
    let details: WeatherDetails
}

struct HourlyForecast {
    let time: Date
    let temperature: Double
    let condition: String
}

struct DailyForecast {
    let date: Date
    let highTemperature: Double
    let lowTemperature: Double
    let condition: String
}

struct WeatherDetails {
    let humidity: Double
    let windSpeed: Double
    let pressure: Double
    let visibility: Double
    let uvIndex: Double
}

// MARK: - View Models

struct CurrentWeatherViewModel {
    let location: String
    let date: String
    let temperature: String
    let condition: String
    let feelsLike: String
}

struct HourlyForecastItem: Identifiable {
    let id: UUID
    let time: String
    let temperature: String
    let condition: String
}

struct DailyForecastItem: Identifiable {
    let id: UUID
    let day: String
    let high: String
    let low: String
    let condition: String
}
