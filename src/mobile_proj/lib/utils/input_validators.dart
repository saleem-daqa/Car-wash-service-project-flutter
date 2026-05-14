class InputValidators {
  static final RegExp _emailRegex = RegExp(
    r'^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$',
    caseSensitive: false,
  );
  static final RegExp _hasLetter = RegExp(r'[A-Za-z]');
  static final RegExp _hasDigit = RegExp(r'\d');
  static final RegExp _phoneCharacters = RegExp(r'^[0-9+\-\s()]+$');

  const InputValidators._();

  static String? requiredText(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $label';
    }
    return null;
  }

  static String? fullName(String? value) {
    final required = requiredText(value, 'your full name');
    if (required != null) return required;
    if (value!.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  static String? email(String? value) {
    final required = requiredText(value, 'your email');
    if (required != null) return required;
    if (!_emailRegex.hasMatch(value!.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? phone(String? value) {
    final required = requiredText(value, 'your phone number');
    if (required != null) return required;
    final trimmed = value!.trim();
    if (!_phoneCharacters.hasMatch(trimmed)) {
      return 'Enter a valid phone number';
    }
    final digitsOnly = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length < 8) {
      return 'Phone number must be at least 8 digits';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!_hasLetter.hasMatch(value) || !_hasDigit.hasMatch(value)) {
      return 'Password must include letters and numbers';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? vehicleBrand(String? value) {
    final required = requiredText(value, 'the vehicle brand');
    if (required != null) return required;
    final trimmed = value!.trim();
    if (trimmed.length < 2 || trimmed.length > 50) {
      return 'Brand must be between 2 and 50 characters';
    }
    return null;
  }

  static String? vehicleModel(String? value) {
    final required = requiredText(value, 'the vehicle model');
    if (required != null) return required;
    if (value!.trim().length > 50) {
      return 'Model must be 50 characters or fewer';
    }
    return null;
  }

  static String? vehiclePlate(String? value) {
    final required = requiredText(value, 'the plate number');
    if (required != null) return required;
    final trimmed = value!.trim();
    if (trimmed.length < 3 || trimmed.length > 15) {
      return 'Plate number must be between 3 and 15 characters';
    }
    return null;
  }
}
