class AppConfig {
  static const String pocketbaseUrl = String.fromEnvironment(
    'POCKETBASE_URL',
    defaultValue: 'http://192.168.29.184:8090',
  );

  static const String ifscApiUrl = 'https://ifsc.razorpay.com';
  static const String pincodeApiUrl = 'https://api.postalpincode.in';
  static const String gstApiUrl = '';
  static const String gstApiKey = '';
}
