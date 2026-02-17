/// Authentication Utilities
/// Helper functions for authentication operations

/// Validate email format
bool isValidEmail(String email) {
  final emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  return emailRegex.hasMatch(email);
}

/// Validate password strength
bool isValidPassword(String password) {
  // Minimum 6 characters
  // Can be enhanced with more complex rules
  return password.length >= 6;
}

/// Validate password strength with requirements
Map<String, bool> validatePasswordStrength(String password) {
  return {
    'minLength': password.length >= 8,
    'hasUppercase': password.contains(RegExp(r'[A-Z]')),
    'hasLowercase': password.contains(RegExp(r'[a-z]')),
    'hasNumbers': password.contains(RegExp(r'[0-9]')),
    'hasSpecialChar': password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
  };
}

/// Check if password is strong
bool isStrongPassword(String password) {
  final strength = validatePasswordStrength(password);
  return strength.values.every((element) => element);
}

/// Validate email and password
Map<String, String> validateCredentials(String email, String password) {
  final errors = <String, String>{};

  if (email.isEmpty) {
    errors['email'] = 'Email is required';
  } else if (!isValidEmail(email)) {
    errors['email'] = 'Invalid email format';
  }

  if (password.isEmpty) {
    errors['password'] = 'Password is required';
  } else if (!isValidPassword(password)) {
    errors['password'] = 'Password must be at least 6 characters';
  }

  return errors;
}

/// Generate auth header value
String generateAuthHeader(String token) {
  return 'Bearer $token';
}

/// Extract token from auth header
String? extractTokenFromHeader(String? authHeader) {
  if (authHeader == null) return null;
  if (!authHeader.startsWith('Bearer ')) return null;
  return authHeader.substring(7);
}

/// Check if token is likely expired
bool isTokenLikelyExpired(String token) {
  // In a real app, you'd decode the JWT and check expiration time
  // For now, just check basic format
  final parts = token.split('.');
  return parts.length != 3;
}
