# Google Maps Flutter App

A Flutter-based application that integrates Google Maps to provide location-based features. This app is designed to help users view maps, explore locations, and access navigation capabilities with ease.

## ✨ Key Features

- **Interactive Google Map**: View maps with various display types (normal, satellite, terrain).
- **Location Markers**: Place markers on the map to mark important locations.
- **User Location**: Display user’s current location with real-time updates.
- **Customizable Map Styles**: Switch between map types and customize the map interface.
- **Directions and Navigation**: Get route directions from a starting point to a destination.
- **Search Functionality**: Search for locations using place names or addresses.
- **Geolocation**: Fetch the user's current location and show it on the map.

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK**: [Install Flutter](https://flutter.dev/docs/get-started/install) if you haven't already.
- **Google Cloud Project**: Create a Google Cloud Project and enable the Maps SDK for Android and iOS.

### Installation

1. **Clone the repository**:

    ```bash
    git clone https://github.com/yourusername/google_maps_flutter_app.git
    cd google_maps_flutter_app
    ```

2. **Install dependencies**:

    ```bash
    flutter pub get
    ```

### Configuration

1. **Google API Key**: Obtain an API Key from [Google Cloud Console](https://console.cloud.google.com/).
2. **Set Up Android**:
   - In `android/app/src/main/AndroidManifest.xml`, add your API key in the `<meta-data>` tag within the `<application>` section:
     ```xml
     <meta-data
         android:name="com.google.android.geo.API_KEY"
         android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
     ```
3. **Set Up iOS**:
   - In `ios/Runner/AppDelegate.swift`, add your API key in `GMSServices.provideAPIKey`:
     ```swift
     GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
     ```

## 📱 Usage

To run the app on an emulator or a physical device:

```bash
flutter run
```

## 📂 Core Screens and Functionalities

- **Map Screen**: The main screen showing the interactive map with zoom, tilt, and rotation controls.
- **Marker and Location Management**: Drop, update, or delete markers. View and center the map on the user's current location.
- **Search and Navigation**: Search for locations, view details, and get navigation directions.
- **Settings**: Customize map display settings and manage permissions.

## 📦 Dependencies

This project uses the following core packages:

- **google_maps_flutter**: Integrates Google Maps into the app.
- **geolocator**: Fetches and updates the user's current location.
- **provider**: State management for efficient app performance.
- **flutter_polyline_points**: Draws routes and directions between markers.

## 📌 Roadmap

- **Offline Maps**: Download maps for offline use.
- **Location Sharing**: Share real-time location with others.
- **Traffic Layer**: Display traffic information on the map.

## ⚖️ License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## 📧 Support

For any issues, questions, or feature requests, please contact [arpit.vekariya123@gmail.com].
