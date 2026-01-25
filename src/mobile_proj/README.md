# Car Wash Service Booking App

A comprehensive Flutter mobile application for managing car wash service bookings with multi-role support for customers, employees, and managers.

## 📱 Overview

This application provides a complete solution for car wash service management, allowing customers to book services, employees to manage job assignments, and managers to oversee operations. The app features location-based service delivery, multiple payment options, a points-based reward system, and real-time job tracking.

## ✨ Features

### Customer Features
- **Vehicle Management**: Add, edit, and delete vehicles with plate number and model validation
- **Service Booking**: Book car wash services (Basic, Deluxe, Premium) with date and time selection
- **Location Services**: Provide service location via GPS or manual address input
- **Payment Options**: Pay using Cash, Visa Card, or Wallet balance
- **Points & Rewards**: Earn points for completed services (Basic: 1pt, Deluxe: 2pts, Premium: 3pts)
- **Wallet System**: Convert points to NIS (5 points = 1 ₪) and use wallet balance for payments
- **Booking History**: View current and past bookings with status tracking
- **Rating & Feedback**: Rate completed services and provide feedback

### Employee Features
- **Job Management**: View assigned jobs with customer details and service information
- **Location Navigation**: Access job locations with "Open in Maps" functionality
- **Job Status Updates**: Start jobs and mark them as completed
- **Payment Method Visibility**: See how customers are paying (Cash/Visa/Wallet)
- **Real-time Updates**: View job status changes in real-time

### Manager Features
- **Dashboard**: Overview of operations and team management
- **Service Management**: Manage available wash services
- **Team Management**: Create and manage employee accounts
- **Account Management**: Change password and logout functionality

## 🛠️ Technologies Used

- **Flutter**: Cross-platform mobile development framework
- **Dart**: Programming language
- **Geolocator**: Location services and GPS functionality
- **URL Launcher**: Opening maps and external applications
- **Lottie**: Animations and visual effects
- **State Management**: Service-based architecture for data management

## 📋 Prerequisites

- Flutter SDK (3.10.4 or higher)
- Dart SDK
- Android Studio / Xcode (for mobile development)
- Android device/emulator or iOS simulator

## 🚀 Getting Started

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd MobileProject/src/mobile_proj
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the application:
```bash
flutter run
```

### Test Accounts

For testing purposes, the following accounts are available:

- **Manager**: 
  - Email: `manager@test.com`
  - Password: `manager123`

- **Customer**: 
  - Email: `customer@test.com`
  - Password: `customer123`

- **Employee**: 
  - Email: `employee@test.com`
  - Password: `employee123`

## 📁 Project Structure

```
lib/
├── models/          # Data models (Job, Booking, Vehicle, WashService)
├── screens/         # UI screens for different features
├── services/        # Business logic services (JobService, BookingService, WalletService)
├── widgets/         # Reusable UI components
└── theme/           # App theme configuration
```

## 🎯 Key Features Explained

### Points System
- Customers earn fixed points per service type
- Points can be converted to NIS at a rate of 5 points = 1 ₪
- Points are automatically added to wallet when employee marks job as completed

### Location Services
- GPS-based location detection
- Manual address input as fallback
- Integration with Google Maps for navigation
- Location data passed to employees for service delivery

### Payment Flow
1. Customer selects service and vehicle
2. Chooses date, time, and location
3. Selects payment method (Cash/Visa/Wallet)
4. Booking is created and assigned to employee
5. Employee completes service and marks as finished
6. Points are automatically added to customer wallet

### Booking Status Flow
- **Pending** → **Confirmed** → **Assigned** → **In Progress** → **Completed**

## 📱 Screenshots

*Add screenshots of your app here*

## 🔧 Configuration

### Android
- Location permissions are configured in `AndroidManifest.xml`
- Minimum SDK version: Check `build.gradle.kts`

### iOS
- Location usage descriptions in `Info.plist`
- Minimum iOS version: Check `Podfile`

## 🐛 Known Issues

- Location permissions require app rebuild (not just hot reload)
- Maps functionality requires Google Maps or default maps app installed

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👥 Authors

- Your Name - *Initial work*

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- All contributors and testers

---

**Note**: This is a development project. For production use, implement proper authentication, database integration, and security measures.
