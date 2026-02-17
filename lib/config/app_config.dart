// lib/config/app_config.dart
// Configuration for different environments

class AppConfig {
  // API Configuration
  static const String nodeJsBaseUrl = 'http://168.231.121.11:3001';
  static const String djangoBaseUrl = 'http://168.231.121.11:8000';
  
  // Google OAuth Configuration
  static const String googleClientId = 
      '744378730034-akb66ls3013tntsn9of6faa10k4a6e3i.apps.googleusercontent.com';
  
  // API Keys
  static const String appName = 'PBS FinSight';
  static const String appVersion = '1.0.0';
  
  // Features
  static const bool enableGoogleAuth = true;
  static const bool enableBiometricAuth = true;
  
  // Environment specific configurations
  static const bool isProduction = false;
  static const bool isDebugMode = true;
}

class EnvironmentConfig {
  static const Map<String, dynamic> development = {
    'nodeJsUrl': 'http://168.231.121.11:3001',
    'djangoUrl': 'http://168.231.121.11:8000',
    'googleClientId': '744378730034-akb66ls3013tntsn9of6faa10k4a6e3i.apps.googleusercontent.com',
    'env': 'development',
  };
  
  static const Map<String, dynamic> production = {
    'nodeJsUrl': 'https://api.pbsfinsight.com',
    'djangoUrl': 'https://backend.pbsfinsight.com',
    'googleClientId': 'YOUR_PRODUCTION_CLIENT_ID',
    'env': 'production',
  };
  
  static const Map<String, dynamic> staging = {
    'nodeJsUrl': 'https://staging-api.pbsfinsight.com',
    'djangoUrl': 'https://staging-backend.pbsfinsight.com',
    'googleClientId': 'YOUR_STAGING_CLIENT_ID',
    'env': 'staging',
  };
}
