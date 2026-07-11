class AppConfig {
  static const String pocketbaseUrl = String.fromEnvironment(
    'POCKETBASE_URL',
    defaultValue: 'http://192.168.29.184:8090',
  );

  static const String ifscApiUrl = 'https://ifsc.razorpay.com';
  static const String pincodeApiUrl = 'https://api.postalpincode.in';
  static const String gstApiUrl = 'https://gstverify.co.in/api/v1/verify';
  static const String gstApiKey = 'gstv_615cc1024e41331271e64ca5f79b1781bca7c0a9086c6ce4';
}
