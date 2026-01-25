# API Setup Instructions

## Connection Issue Fixed! ✅

The Flutter app now uses `10.0.2.2` instead of `localhost` to connect from Android emulator.

## Setup Steps

### 1. Web Server Setup

You need a web server running (XAMPP, MAMP, or built-in PHP server):

**Option A: XAMPP (Windows/Mac/Linux)**
- Download from: https://www.apachefriends.org/
- Install and start Apache + MySQL
- Copy all files from `src/api/` to `C:\xampp\htdocs\api\` (Windows) or `/Applications/XAMPP/htdocs/api/` (Mac)

**Option B: MAMP (Mac)**
- Download from: https://www.mamp.info/
- Install and start servers
- Copy all files from `src/api/` to `/Applications/MAMP/htdocs/api/`

**Option C: Built-in PHP Server (for testing)**
```bash
cd /Users/saleemdaqa/Desktop/Mobile/MobileProject/src/api
php -S localhost:8000
```
Then update `api_config.dart` to use `http://10.0.2.2:8000` instead

### 2. Folder Structure

Copy **ALL** files from `src/api/` folder to your web server:

**For XAMPP:**
```
C:\xampp\htdocs\api\     (Windows)
/Applications/XAMPP/htdocs/api/  (Mac)
```

**For MAMP:**
```
/Applications/MAMP/htdocs/api/
```

The folder should contain all PHP files:
- `db.php`
- `register.php`
- `login.php`
- `create_vehicle.php`
- `update_vehicle.php`
- `get_all_vehicles.php`
- ... (all other PHP files)

### 3. Database Setup

1. Make sure MySQL is running
2. Import the SQL file:
   ```sql
   mysql -u root -p < MobilePRJ.sql
   ```
3. Update `config.php` with your database credentials if needed

### 4. Test the API

Open in browser:
- `http://localhost/api/login.php` (should show JSON error, not 404)
- If you see 404, check that files are in the correct folder
- If you see JSON, the API is working!

### 5. Flutter App Configuration

**IMPORTANT: You need to update the API URL based on your server!**

The app is currently configured for **MAMP** (port 8888). If you're using **XAMPP**, you need to change it:

**For XAMPP (Windows/Mac/Linux):**
1. Open `src/mobile_proj/lib/config/api_config.dart`
2. Change line 2 from:
   ```dart
   static const String baseUrl = 'http://10.0.2.2:8888/api';
   ```
   To:
   ```dart
   static const String baseUrl = 'http://10.0.2.2/api';  // XAMPP uses port 80 (default)
   ```
   Or if XAMPP uses port 8080:
   ```dart
   static const String baseUrl = 'http://10.0.2.2:8080/api';
   ```

**For MAMP (Mac):**
- Already configured: `http://10.0.2.2:8888/api`

**For Physical Device:**
- Use your computer's IP address: `http://192.168.1.100/api` (replace with your IP)
- Make sure phone and computer are on the same WiFi

**Folder Structure:**
- Copy all files from `src/api/` to `htdocs/api/` (or `htdocs/carwash/api/` if you prefer)
- Make sure the folder name matches what you put in `baseUrl`

## Troubleshooting

### "Connection refused" Error

1. **Check if web server is running**
   - XAMPP: Check Apache is started
   - MAMP: Check servers are running

2. **Check folder structure**
   - Files must be in `htdocs/api/` (or match the path in `api_config.dart`)
   - Make sure all PHP files are copied, not just some

3. **Check database connection**
   - Make sure MySQL is running
   - Verify credentials in `config.php`

4. **For Physical Device**
   - Find your computer's IP: `ipconfig` (Windows) or `ifconfig` (Mac/Linux)
   - Update `api_config.dart` with your IP
   - Make sure phone and computer are on same WiFi

### Test API Directly

Use Postman or browser to test:
```
POST http://localhost/api/register.php
Content-Type: application/x-www-form-urlencoded

Body: full_name=Test&email=test@test.com&phone=1234567890&password=123456
```

Or test in browser:
- `http://localhost/api/login.php` (should show JSON error about missing fields)

## Quick Setup Checklist for XAMPP

1. ✅ Install XAMPP and start Apache + MySQL
2. ✅ Copy all files from `src/api/` to `C:\xampp\htdocs\api\` (Windows) or `/Applications/XAMPP/htdocs/api/` (Mac)
3. ✅ Import `MobilePRJ.sql` into MySQL (create database `car_wash_db`)
4. ✅ Update `src/mobile_proj/lib/config/api_config.dart`:
   - Change `baseUrl` to `'http://10.0.2.2/api'` (for Android emulator)
   - Or `'http://localhost/api'` (for iOS simulator)
5. ✅ Test: Open `http://localhost/api/login.php` in browser (should show JSON error, not 404)

## Current Default Configuration

- **Base URL (MAMP)**: `http://10.0.2.2:8888/api`
- **Base URL (XAMPP)**: `http://10.0.2.2/api` (needs to be changed in code)
- **Database**: `car_wash_db`
- **All APIs**: Using centralized `db.php` with auto-detection (tries common XAMPP/MAMP configs)
