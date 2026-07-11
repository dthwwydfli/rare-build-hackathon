String friendlyAuthError(Object error) {
  final message = error.toString().toLowerCase();
  if (message.contains('user-not-found') ||
      message.contains('wrong-password') ||
      message.contains('invalid-credential') ||
      message.contains('invalid login')) {
    return 'Invalid email or password. Please try again.';
  }
  if (message.contains('email-already-in-use')) {
    return 'An account with this email already exists.';
  }
  if (message.contains('weak-password')) {
    return 'Password is too weak. Use at least 6 characters.';
  }
  if (message.contains('invalid-email')) {
    return 'Please enter a valid email address.';
  }
  if (message.contains('network')) {
    return 'Network error. Check your connection and try again.';
  }
  if (message.contains('cancelled')) {
    return 'Sign-in was cancelled.';
  }
  if (message.contains('too-many-requests')) {
    return 'Too many attempts. Please wait and try again.';
  }
  return 'Something went wrong. Please try again.';
}

bool isValidEmail(String email) {
  return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
}
