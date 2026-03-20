// lib/utils/constants.dart
// App Constants


class Constants {
  // App Info
  static const String appName = 'Virtual Try-On';
  static const String appVersion = '1.0.0';

  // Asset Paths
  static const String logoPath = 'assets/images/logo.png';
  static const String placeholderImage = 'assets/images/placeholder.png';
  static const String emptyCartImage = 'assets/images/empty_cart.png';

  // String Constants
  static const String emptyCart = 'Your cart is empty';
  static const String noResults = 'No results found';
  static const String tryOnMessage = 'Take a photo to try on dresses';
  static const String loading = 'Loading...';
  static const String error = 'Something went wrong';
  static const String networkError = 'No internet connection';
  static const String serverError = 'Server error. Please try again later.';
  static const String success = 'Success!';
  static const String paymentSuccess = 'Payment successful!';
  static const String paymentFailed = 'Payment failed. Please try again.';
  static const String orderPlaced = 'Order placed successfully!';

  // Button Labels
  static const String addToCart = 'Add to Cart';
  static const String buyNow = 'Buy Now';
  static const String checkout = 'Checkout';
  static const String placeOrder = 'Place Order';
  static const String viewCart = 'View Cart';
  static const String continueShopping = 'Continue Shopping';
  static const String retry = 'Retry';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String save = 'Save';
  static const String apply = 'Apply';
  static const String clear = 'Clear';
  static const String search = 'Search';
  static const String filter = 'Filter';
  static const String sort = 'Sort';

  // Navigation Labels
  static const String home = 'Home';
  static const String tryOn = 'Try On';
  static const String cart = 'Cart';
  static const String profile = 'Profile';
  static const String orders = 'Orders';
  static const String settings = 'Settings';

  // Category Names
  static const String allCategories = 'All';
  static const String eveningWear = 'Evening Wear';
  static const String casualWear = 'Casual Wear';
  static const String partyWear = 'Party Wear';
  static const String beachWear = 'Beach Wear';
  static const String summerWear = 'Summer Wear';
  static const String winterWear = 'Winter Wear';
  static const String formalWear = 'Formal Wear';

  // Size Labels
  static const String sizeXS = 'XS';
  static const String sizeS = 'S';
  static const String sizeM = 'M';
  static const String sizeL = 'L';
  static const String sizeXL = 'XL';
  static const String sizeXXL = 'XXL';

  // Payment Methods
  static const String stripe = 'Stripe';
  static const String card = 'Card';
  static const String upi = 'UPI';
  static const String cod = 'Cash on Delivery';

  // Payment Status
  static const String pending = 'Pending';
  static const String completed = 'Completed';
  static const String failed = 'Failed';
  static const String canceled = 'Canceled';

  // Validation Messages
  static const String emailRequired = 'Email is required';
  static const String emailInvalid = 'Please enter a valid email';
  static const String nameRequired = 'Name is required';
  static const String phoneRequired = 'Phone number is required';
  static const String phoneInvalid = 'Please enter a valid phone number';
  static const String addressRequired = 'Address is required';
  static const String pincodeRequired = 'Pincode is required';
  static const String pincodeInvalid = 'Please enter a valid pincode';
  static const String passwordRequired = 'Password is required';
  static const String passwordTooShort = 'Password must be at least 6 characters';
  static const String passwordMismatch = 'Passwords do not match';

  // Time Constants
  static const int splashDuration = 5; // seconds
  static const int searchDebounce = 500; // milliseconds
  static const int requestTimeout = 30; // seconds
  static const int tryOnTimeout = 120; // seconds

  // Limits
  static const int maxCartItems = 20;
  static const int maxCartQuantity = 10;
  static const int maxTryOnDresses = 5;
  static const int maxImageSizeMB = 5;
  static const int maxReviewLength = 500;
  static const int minReviewLength = 10;

  // Price Constants
  static const double minPrice = 0;
  static const double maxPrice = 10000;
  static const double minOrderAmount = 100;
  static const double freeShippingThreshold = 1000;
  static const double shippingCharge = 50;

  // Grid/List Constants
  static const int gridCrossAxisCount = 2;
  static const double gridAspectRatio = 0.7;
  static const double gridSpacing = 16;

  // Animation Durations
  static const Duration shortDuration = Duration(milliseconds: 200);
  static const Duration mediumDuration = Duration(milliseconds: 300);
  static const Duration longDuration = Duration(milliseconds: 500);

  // Border Radius
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;

  // Icon Sizes
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXL = 48.0;

  // Font Sizes
  static const double fontSizeXS = 10.0;
  static const double fontSizeS = 12.0;
  static const double fontSizeM = 14.0;
  static const double fontSizeL = 16.0;
  static const double fontSizeXL = 18.0;
  static const double fontSizeXXL = 20.0;

  // Elevation
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;

  // RegEx Patterns
  static const String emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String phonePattern = r'^[6-9]\d{9}$';
  static const String pincodePattern = r'^[1-9][0-9]{5}$';

  // API Error Messages
  static const String apiError = 'Failed to connect to server';
  static const String timeoutError = 'Request timed out';
  static const String unauthorizedError = 'Unauthorized access';
  static const String notFoundError = 'Resource not found';
  static const String validationError = 'Invalid input';

  // Shared Preferences Keys
  static const String keyAuthToken = 'auth_token';
  static const String keyUser = 'user';
  static const String keyCart = 'cart';
  static const String keyTheme = 'theme_mode';
  static const String keyFirstLaunch = 'first_launch';
  static const String keyRecentSearches = 'recent_searches';
  static const String keyFavorites = 'favorites';

  // Date Formats
  static const String dateFormat = 'dd MMM yyyy';
  static const String dateTimeFormat = 'dd MMM yyyy, hh:mm a';
  static const String timeFormat = 'hh:mm a';

  // URLs (for production)
  static const String privacyPolicyUrl = 'https://virtualtryon.com/privacy';
  static const String termsUrl = 'https://virtualtryon.com/terms';
  static const String supportEmail = 'support@virtualtryon.com';
  static const String supportPhone = '+91 6371891213';

  // Social Media
  static const String facebookUrl = 'https://facebook.com/virtualtryon';
  static const String instagramUrl = 'https://instagram.com/virtualtryon';
  static const String twitterUrl = 'https://twitter.com/virtualtryon';

  // Stripe Test Card
  static const String testCardNumber = '4242 4242 4242 4242';
  static const String testCardExpiry = '12/34';
  static const String testCardCVC = '123';
}