class Partner {
  final String id;
  final String collectionId;
  final String collectionName;
  final String partnerName;
  final String partnerCode;
  final String entityType;
  final String keyPersonName;
  final String mobileNo;
  final String email;
  final String partnerType; // dealer, subdealer
  
  // Billing Address
  final String billingAddress;
  final String billingLandmark;
  final String billingCity;
  final String billingState;
  final String billingPincode;
  
  // Shipping Address
  final bool hasDifferentShippingAddress;
  final String shippingBusinessName;
  final String shippingAddress;
  final String shippingLandmark;
  final String shippingCity;
  final String shippingState;
  final String shippingPincode;

  // Tax Info
  final String panNo;
  final String gstNo;
  final String gstFilingFrequency; // monthly, quarterly

  // Bank Info
  final String bankName;
  final String bankAcNo;
  final String bankIfscCode;
  final String bankAcType; // saving, current

  final bool partnerActive;
  final DateTime created;
  final DateTime updated;
  final DateTime? onboardingDate;
  final DateTime? offboardingDate;

  Partner({
    required this.id,
    required this.collectionId,
    required this.collectionName,
    required this.partnerName,
    required this.partnerCode,
    required this.entityType,
    required this.keyPersonName,
    required this.mobileNo,
    required this.email,
    required this.partnerType,
    required this.billingAddress,
    required this.billingLandmark,
    required this.billingCity,
    required this.billingState,
    required this.billingPincode,
    required this.hasDifferentShippingAddress,
    required this.shippingBusinessName,
    required this.shippingAddress,
    required this.shippingLandmark,
    required this.shippingCity,
    required this.shippingState,
    required this.shippingPincode,
    required this.panNo,
    required this.gstNo,
    required this.gstFilingFrequency,
    required this.bankName,
    required this.bankAcNo,
    required this.bankIfscCode,
    required this.bankAcType,
    required this.partnerActive,
    required this.created,
    required this.updated,
    this.onboardingDate,
    this.offboardingDate,
  });

  factory Partner.fromJson(Map<String, dynamic> json) {
    return Partner(
      id: json['id'] ?? '',
      collectionId: json['collectionId'] ?? '',
      collectionName: json['collectionName'] ?? '',
      partnerName: json['partner_name'] ?? '',
      partnerCode: json['partner_code'] ?? '',
      entityType: json['entity_type'] ?? '',
      keyPersonName: json['key_person_name'] ?? '',
      mobileNo: json['mobile_no'] ?? '',
      email: json['email'] ?? '',
      partnerType: json['partner_type'] ?? '',
      
      billingAddress: json['billing_address'] ?? '',
      billingLandmark: json['billing_landmark'] ?? '',
      billingCity: json['billing_city'] ?? '',
      billingState: json['billing_state'] ?? '',
      billingPincode: json['billing_pincode'] ?? '',
      
      hasDifferentShippingAddress: json['has_different_shipping_address'] ?? false,
      shippingBusinessName: json['shipping_business_name'] ?? '',
      shippingAddress: json['shipping_address'] ?? '',
      shippingLandmark: json['shipping_landmark'] ?? '',
      shippingCity: json['shipping_city'] ?? '',
      shippingState: json['shipping_state'] ?? '',
      shippingPincode: json['shipping_pincode'] ?? '',
      
      panNo: json['pan_no'] ?? '',
      gstNo: json['gst_no'] ?? '',
      gstFilingFrequency: json['gst_filing_frequency'] ?? 'monthly',
      
      bankName: json['bank_name'] ?? '',
      bankAcNo: json['bank_ac_no'] ?? '',
      bankIfscCode: json['bank_ifsc_code'] ?? '',
      bankAcType: json['bank_ac_type'] ?? 'saving',
      
      partnerActive: json['partner_active'] ?? false,
      created: DateTime.parse(json['created']),
      updated: DateTime.parse(json['updated']),
      onboardingDate: json['partner_onboarding_date'] != null && json['partner_onboarding_date'].toString().isNotEmpty
          ? DateTime.parse(json['partner_onboarding_date'])
          : null,
      offboardingDate: json['partner_offboarding_date'] != null && json['partner_offboarding_date'].toString().isNotEmpty
          ? DateTime.parse(json['partner_offboarding_date'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'partner_name': partnerName,
      'partner_code': partnerCode,
      'entity_type': entityType,
      'key_person_name': keyPersonName,
      'mobile_no': mobileNo,
      'email': email,
      'partner_type': partnerType,
      'billing_address': billingAddress,
      'billing_landmark': billingLandmark,
      'billing_city': billingCity,
      'billing_state': billingState,
      'billing_pincode': billingPincode,
      'has_different_shipping_address': hasDifferentShippingAddress,
      'shipping_business_name': shippingBusinessName,
      'shipping_address': shippingAddress,
      'shipping_landmark': shippingLandmark,
      'shipping_city': shippingCity,
      'shipping_state': shippingState,
      'shipping_pincode': shippingPincode,
      'pan_no': panNo,
      'gst_no': gstNo,
      'gst_filing_frequency': gstFilingFrequency,
      'bank_name': bankName,
      'bank_ac_no': bankAcNo,
      'bank_ifsc_code': bankIfscCode,
      'bank_ac_type': bankAcType,
      'partner_active': partnerActive,
      'partner_onboarding_date': onboardingDate?.toIso8601String(),
      'partner_offboarding_date': offboardingDate?.toIso8601String(),
    };
  }
}
