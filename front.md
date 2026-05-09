# Project Summary: Kidcare Frontend

## Overview
**Kidcare Frontend** is a mobile and web application built using the **Flutter** framework. It is designed for a pediatric clinic, providing features for user authentication, registration, and potentially more healthcare-related services.

## Technology Stack
- **Framework**: [Flutter](https://flutter.dev/) (Multi-platform support: Android, iOS, Web, Windows, Linux, macOS)
- **State Management**: [GetX](https://pub.dev/packages/get) (used for navigation, state, and dependency injection)
- **Networking**: [http](https://pub.dev/packages/http) (for REST API communication)
- **Local Storage**: [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) (for secure token and sensitive data management)

## Project Structure
The project follows a structured architecture to separate concerns:

- **`lib/`**: Core source code directory.
  - **`controllers/`**: Contains business logic and state handling using GetX.
  - **`views/`**: UI screens and layouts.
  - **`widgets/`**: Reusable UI components (e.g., [custom_text_field.dart](file:///c:/Users/LOQ/Desktop/New%20folder/Kidcare-frontend/lib/widgets/custom_text_field.dart)).
  - **`core/`**: Shared utilities and infrastructure.
    - **`apis/`**: Low-level network request logic.
    - **`repos/`**: Repositories acting as an abstraction layer between APIs and Controllers.
    - **`helper/`**: Utility services like [secure_storage_service.dart](file:///c:/Users/LOQ/Desktop/New%20folder/Kidcare-frontend/lib/core/helper/secure_storage_service.dart).
  - **`models/`**: Data models for API requests and responses.
- **`assets/`**: Images and static resources.

## Key Features & Flows
1.  **Splash & Onboarding**: An animated splash screen ([main_advanced.dart](file:///c:/Users/LOQ/Desktop/New%20folder/Kidcare-frontend/lib/views/main_advanced.dart)) that introduces the clinic.
2.  **Authentication**:
    - **Login**: Phone and password-based login ([login_view.dart](file:///c:/Users/LOQ/Desktop/New%20folder/Kidcare-frontend/lib/views/login_view.dart)).
    - **Registration**: New user sign-up flow ([sign_up_view.dart](file:///c:/Users/LOQ/Desktop/New%20folder/Kidcare-frontend/lib/views/sign_up_view.dart)).
    - **OTP Verification**: Secure verification via One-Time Password ([verify_otp_view.dart](file:///c:/Users/LOQ/Desktop/New%20folder/Kidcare-frontend/lib/views/verify_otp_view.dart)).
3.  **Secure Token Management**: Uses secure storage to maintain user sessions safely.

## Configuration
- **API Base URL**: Configured in [constants.dart](file:///c:/Users/LOQ/Desktop/New%20folder/Kidcare-frontend/lib/core/constants.dart) as `http://192.168.164.8:8000/api`.
- **Dependencies**: Managed via [pubspec.yaml](file:///c:/Users/LOQ/Desktop/New%20folder/Kidcare-frontend/pubspec.yaml).

## How to Run
1.  Ensure Flutter SDK is installed.
2.  Run `flutter pub get` to install dependencies.
3.  Run the app using `flutter run`.
