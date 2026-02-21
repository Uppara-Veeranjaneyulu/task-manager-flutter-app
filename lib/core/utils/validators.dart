class AppValidators {
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return "Password required";
    }
    if (value.length < 8) {
      return "Min. 8 characters required";
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return "Must include a capital letter";
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return "Must include a symbol";
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return "Email required";
    }
    if (!value.contains("@")) {
      return "Enter a valid email";
    }
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return "Name required";
    }
    return null;
  }
}
