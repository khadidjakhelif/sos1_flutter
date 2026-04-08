# SOS1 - Emergency Voice Assistant

A Flutter-based voice-controlled emergency assistant app inspired by Siri and Alexa, designed specifically for emergency situations. The app provides hands-free, accessible emergency assistance through voice commands.

## Features

- **Voice Recognition**: Hands-free emergency command detection
- **Emergency Detection**: Automatically identifies medical, police, and fire emergencies
- **Text-to-Speech**: Provides audio feedback and confirmations
- **Quick Commands**: One-tap buttons for SAMU, Police, and Fire services
- **Dark Theme**: Easy on the eyes during stressful situations
- **Animated UI**: Smooth animations and visual feedback

## Architecture

This app follows the **Stacked/MVC architecture** pattern:

```
lib/
├── app/
│   ├── app.dart              # Stacked app configuration
│   ├── app.locator.dart      # Dependency injection setup
│   └── app.router.dart       # Navigation routing
├── services/
│   ├── speech_recognition_service.dart  # Speech-to-text
│   └── text_to_speech_service.dart      # Text-to-speech
├── ui/
│   ├── views/
│   │   └── voice_assistant/
│   │       ├── voice_assistant_view.dart      # View (UI)
│   │       └── voice_assistant_viewmodel.dart # ViewModel (Logic)
│   └── widgets/
│       ├── mic_button.dart           # Animated microphone button
│       ├── quick_command_button.dart # Emergency service buttons
│       └── example_command_text.dart # Example text display
├── utils/
│   ├── app_colors.dart       # Color constants
│   ├── app_strings.dart      # String constants
│   └── app_theme.dart        # Theme configuration
└── main.dart                 # App entry point
```

## Getting Started

### Prerequisites

- Flutter SDK 3.0.0 or higher
- Dart SDK 3.0.0 or higher
- Android Studio / Xcode (for emulators)
- Physical device with microphone (recommended for testing)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd sos1
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Platform-Specific Setup

#### Android

The app requires the following permissions (already configured in `AndroidManifest.xml`):
- `RECORD_AUDIO` - For speech recognition
- `CALL_PHONE` - For emergency calls
- `ACCESS_FINE_LOCATION` - For location sharing
- `FOREGROUND_SERVICE` - For background listening

#### iOS

The app requires the following permissions (already configured in `Info.plist`):
- `NSMicrophoneUsageDescription` - Microphone access
- `NSSpeechRecognitionUsageDescription` - Speech recognition
- `NSLocationWhenInUseUsageDescription` - Location access

## Usage

### Voice Commands

Simply tap the microphone button and speak naturally. The app recognizes emergency keywords:

**Medical Emergency:**
- "J'ai besoin d'une ambulance"
- "Urgence médicale"
- "Crise cardiaque"
- "Personne inconsciente"

**Police Emergency:**
- "Appelez la police"
- "Vol en cours"
- "Agression"

**Fire Emergency:**
- "Au feu!"
- "Appelez les pompiers"
- "Incendie"

### Quick Commands

Tap any of the three buttons at the bottom for immediate emergency assistance:
- **SAMU** (15) - Medical emergency
- **Police** (17) - Security emergency  
- **Pompiers** (18) - Fire emergency

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| stacked | ^3.4.0 | State management & architecture |
| stacked_services | ^1.5.0 | Navigation & dialogs |
| speech_to_text | ^6.6.0 | Voice recognition |
| flutter_tts | ^3.8.5 | Text-to-speech |
| flutter_screenutil | ^5.9.0 | Responsive UI |
| google_fonts | ^6.1.0 | Typography |
| flutter_animate | ^4.5.0 | Animations |
| permission_handler | ^11.3.0 | Runtime permissions |

## Customization

### Adding New Emergency Types

1. Update `EmergencyType` enum in `speech_recognition_service.dart`
2. Add detection keywords in `detectEmergency()` method
3. Add UI handling in `voice_assistant_viewmodel.dart`

### Changing Emergency Numbers

Edit the `phoneNumber` getter in `EmergencyTypeExtension`:

```dart
String get phoneNumber {
  switch (this) {
    case EmergencyType.medical:
      return '15';  // Change to your local emergency number
    // ...
  }
}
```

## Testing

Run the test suite:
```bash
flutter test
```

## Building for Production

### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- UI design inspired by emergency assistance apps
- Built with Flutter and the Stacked architecture
- Icons from Material Design

## Safety Notice

⚠️ **Important**: This app is designed to assist in emergencies but does not replace official emergency services. Always call your local emergency number (15, 17, 18 in France/Algeria) directly in life-threatening situations.
