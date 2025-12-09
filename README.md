# 🚗 Emergency Towing Service App

A professional, industry-standard Flutter application for emergency towing services with real-time GPS location tracking, dynamic service discovery, and Firebase integration.

## 📱 Features

### 🎯 Core Functionality
- **Real-time GPS Location Detection** - Automatic live location with high accuracy
- **Dynamic Towing Service Discovery** - Find nearby towing services in real-time
- **Multi-Vehicle Support** - Motorcycle, Car, and Truck with different pricing tiers
- **Professional Service Details** - Complete service information with ratings and contact details
- **Firebase Integration** - Secure booking system with cloud storage
- **OpenStreetMap Integration** - Professional mapping with live location tracking
- **Issue-based Recommendations** - Content filtering pairs user problems with specialist mechanics

### 🚀 Advanced Features
- **Automatic Fare Calculation** - Real-time pricing based on distance and vehicle type
- **Live Location Tracking** - Continuous GPS monitoring with accuracy feedback
- **Service Recommendations** - AI-powered nearby service suggestions
- **Professional UI/UX** - Modern dark theme with intuitive navigation
- **Offline Capability** - Works without internet for basic functionality
- **Multi-language Support** - Ready for internationalization
- **Radius Filters** - Predefined distance dropdowns keep results hyper-local

## 🛠️ Technical Stack

### Frontend
- **Flutter 3.7.2+** - Cross-platform mobile development
- **Dart** - Programming language
- **Material Design 3** - Modern UI components

### Backend & Services
- **Firebase Firestore** - Real-time database
- **Firebase Auth** - User authentication
- **OpenStreetMap** - Mapping and geocoding services
- **Geolocator** - GPS location services
- **HTTP** - API communications

### Maps & Location
- **Flutter Map** - OpenStreetMap integration
- **LatLong2** - Geographic calculations
- **Nominatim API** - Reverse geocoding
- **OSRM** - Route optimization

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Core Flutter
  cupertino_icons: ^1.0.8
  
  # Firebase
  firebase_core: ^3.13.0
  cloud_firestore: ^5.4.4
  firebase_auth: ^5.5.3
  
  # Location & Maps
  geolocator: ^13.0.2
  flutter_map: ^7.0.2
  latlong2: ^0.9.1
  
  # Network & Data
  http: ^1.1.0
  
  # UI & Charts
  charts_flutter: ^0.12.0
  google_places_flutter: ^2.1.1
```

## 🚀 Installation

### Prerequisites
- Flutter SDK 3.7.2 or higher
- Dart SDK 3.0.0 or higher
- Android Studio / VS Code
- Firebase project setup
- Google Maps API key (optional)

### Setup Instructions

1. **Clone the Repository**
   ```bash
   git clone https://github.com/yourusername/flutter-towing-service-app.git
   cd flutter-towing-service-app
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration**
   - Create a Firebase project
   - Add Android/iOS apps to your Firebase project
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place files in respective directories

4. **Environment Setup**
   ```bash
   # Android
   cp android/app/google-services.json.example android/app/google-services.json
   
   # iOS
   cp ios/Runner/GoogleService-Info.plist.example ios/Runner/GoogleService-Info.plist
   ```

5. **Run the Application**
   ```bash
   flutter run
   ```

## 🏗️ Project Structure

```
lib/
├── core/
│   └── constants.dart              # App constants and configurations
├── database/
│   └── database_helper.dart        # Local database operations
├── models/
│   ├── mechanic_model.dart         # Mechanic data model
│   └── towing_service.dart         # Towing service data model
├── screens/
│   ├── auth_choice_screen.dart     # Authentication selection
│   ├── dashboard_page.dart         # Main dashboard
│   ├── login_page.dart            # User login
│   ├── signup_page.dart           # User registration
│   ├── TowingServiceScreen.dart   # Main towing service screen
│   └── mechanic_recommendation.dart # Service recommendations
├── service/
│   ├── database_service.dart      # Database operations
│   ├── geocoding_service.dart     # Location geocoding
│   ├── location_pricing_service.dart # Pricing calculations
│   ├── overpass_service.dart      # OpenStreetMap queries
│   └── towing_service_provider.dart # Service provider logic
├── widgets/
│   ├── aggressive_location_widget.dart # GPS location widget
│   ├── custom_button.dart         # Reusable button component
│   ├── location_accuracy_widget.dart # Location accuracy display
│   ├── location_search_widget.dart # Location search functionality
│   └── manual_location_widget.dart # Manual location input
└── main.dart                      # App entry point
```

## 🔧 Configuration

### Firebase Setup
1. **Firestore Rules**
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if request.time < timestamp.date(2025, 12, 31);
       }
     }
   }
   ```

2. **Firebase Collections**
   - `towing_bookings` - User booking records
   - `towing_services` - Service provider data
   - `user_locations` - User location history

### Location Services
- **Android**: Add location permissions in `android/app/src/main/AndroidManifest.xml`
- **iOS**: Add location permissions in `ios/Runner/Info.plist`

## 📱 Usage

### For Users
1. **Launch App** - Automatic GPS location detection
2. **Select Vehicle Type** - Choose from Motorcycle, Car, or Truck
3. **View Services** - Browse nearby towing services
4. **Service Details** - Tap any service for complete information
5. **Book Service** - Direct booking with Firebase integration
6. **Track Location** - Live location updates on map

### For Service Providers
1. **Service Registration** - Add your towing service
2. **Location Updates** - Keep location data current
3. **Booking Management** - Handle incoming requests
4. **Pricing Updates** - Manage service rates

## 🎨 UI/UX Features

### Design System
- **Color Palette**: Professional dark theme with purple accents
- **Typography**: Material Design 3 typography scale
- **Icons**: Material Icons with custom towing-specific icons
- **Animations**: Smooth transitions and micro-interactions

### User Experience
- **Intuitive Navigation** - Clear information hierarchy
- **Accessibility** - Screen reader support and high contrast
- **Responsive Design** - Optimized for all screen sizes
- **Performance** - 60fps animations and smooth scrolling

## 🔒 Security & Privacy

### Data Protection
- **Encrypted Communications** - All API calls use HTTPS
- **Location Privacy** - User location data is anonymized
- **Firebase Security** - Proper authentication and authorization
- **GDPR Compliance** - User data handling best practices

### Permissions
- **Location Access** - Required for GPS functionality
- **Network Access** - For real-time data synchronization
- **Storage Access** - For offline capability

## 🚀 Performance Optimization

### Technical Optimizations
- **Lazy Loading** - Services loaded on demand
- **Image Caching** - Optimized image loading
- **Memory Management** - Efficient resource usage
- **Network Optimization** - Reduced API calls

### Monitoring
- **Crash Reporting** - Firebase Crashlytics integration
- **Performance Monitoring** - Real-time performance metrics
- **User Analytics** - Usage patterns and optimization

## 🧪 Testing

### Test Coverage
```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/

# Run widget tests
flutter test test/widget_test.dart
```

### Test Types
- **Unit Tests** - Individual component testing
- **Widget Tests** - UI component testing
- **Integration Tests** - End-to-end testing
- **Performance Tests** - App performance validation

## 📊 Analytics & Monitoring

### Firebase Analytics
- **User Engagement** - Track user interactions
- **Feature Usage** - Monitor feature adoption
- **Performance Metrics** - App performance monitoring
- **Crash Reports** - Automatic crash detection

### Custom Metrics
- **Location Accuracy** - GPS precision tracking
- **Service Discovery** - Nearby service success rates
- **Booking Completion** - Conversion funnel analysis

## 🌍 Internationalization

### Supported Languages
- **English** (Default)
- **Urdu** (Ready for implementation)
- **Arabic** (RTL support ready)

### Localization Features
- **Currency Support** - Multiple currency formats
- **Date/Time Formats** - Regional preferences
- **Address Formats** - Country-specific addressing

## 🚀 Deployment

### Android
```bash
# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release
```

### iOS
```bash
# Build iOS app
flutter build ios --release
```

### Web
```bash
# Build web app
flutter build web --release
```

## 📈 Roadmap

### Version 2.0
- [ ] **Push Notifications** - Real-time booking updates
- [ ] **Payment Integration** - In-app payment processing
- [ ] **Driver Tracking** - Live driver location tracking
- [ ] **Multi-language Support** - Full internationalization

### Version 2.1
- [ ] **AI Recommendations** - Machine learning service suggestions
- [ ] **Advanced Analytics** - Detailed usage analytics
- [ ] **Offline Mode** - Complete offline functionality
- [ ] **Voice Commands** - Hands-free operation

## 🤝 Contributing

### Development Guidelines
1. **Code Style** - Follow Dart/Flutter conventions
2. **Documentation** - Document all public APIs
3. **Testing** - Write tests for new features
4. **Performance** - Optimize for mobile performance

### Pull Request Process
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Team

- **Lead Developer** - [Your Name]
- **UI/UX Designer** - [Designer Name]
- **Backend Developer** - [Backend Developer Name]
- **QA Engineer** - [QA Engineer Name]

## 📞 Support

### Contact Information
- **Email**: support@towingapp.com
- **Phone**: +92 300 1234567
- **Website**: https://towingapp.com

### Documentation
- **API Documentation**: [API Docs](https://docs.towingapp.com)
- **User Guide**: [User Manual](https://guide.towingapp.com)
- **Developer Guide**: [Dev Docs](https://dev.towingapp.com)

## 🙏 Acknowledgments

- **OpenStreetMap** - For mapping services
- **Firebase** - For backend infrastructure
- **Flutter Team** - For the amazing framework
- **Community** - For contributions and feedback

---

**Made with ❤️ for emergency towing services**

*Professional, reliable, and always ready to help when you need it most.*