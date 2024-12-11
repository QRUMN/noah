import SwiftUI
import MapKit

struct WeatherMapView: View {
    @StateObject private var viewModel = WeatherMapViewModel()
    
    var body: some View {
        NavigationView {
            Map(coordinateRegion: $viewModel.region,
                showsUserLocation: true,
                userTrackingMode: .constant(.follow),
                annotationItems: viewModel.weatherAnnotations) { annotation in
                MapAnnotation(coordinate: annotation.coordinate) {
                    WeatherAnnotationView(annotation: annotation)
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("Weather Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { viewModel.mapType = .standard }) {
                            Label("Standard", systemImage: "map")
                        }
                        Button(action: { viewModel.mapType = .satellite }) {
                            Label("Satellite", systemImage: "globe")
                        }
                        Button(action: { viewModel.mapType = .hybrid }) {
                            Label("Hybrid", systemImage: "map.fill")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
}

struct WeatherAnnotationView: View {
    let annotation: WeatherAnnotation
    
    var body: some View {
        VStack {
            Text(annotation.temperature)
                .font(.system(size: 14, weight: .bold))
            
            Image(systemName: annotation.weatherIcon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
            
            Image(systemName: "triangle.fill")
                .font(.system(size: 12))
                .foregroundColor(.blue)
                .offset(y: -5)
        }
        .padding(8)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

class WeatherMapViewModel: ObservableObject {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    @Published var mapType: MKMapType = .standard
    @Published var weatherAnnotations: [WeatherAnnotation] = []
    
    init() {
        // Add sample weather annotations
        weatherAnnotations = [
            WeatherAnnotation(
                coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                temperature: "72°",
                weatherIcon: "sun.max.fill"
            ),
            WeatherAnnotation(
                coordinate: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4294),
                temperature: "68°",
                weatherIcon: "cloud.fill"
            )
        ]
    }
}

struct WeatherAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let temperature: String
    let weatherIcon: String
}

struct WeatherMapView_Previews: PreviewProvider {
    static var previews: some View {
        WeatherMapView()
    }
}
