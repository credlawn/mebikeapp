class Company {
  final String id;
  final String collectionId;
  final String collectionName;
  final String businessName;
  final String legalName;
  final String address;
  final String landmark;
  final String city;
  final String district;
  final String state;
  final String pincode;
  final String panNo;
  final String gstNo;
  final String stateCode;
  final String gstFilingType;
  final DateTime? gstRegistrationDate;
  final String bankName;
  final String ifscCode;
  final String accountNo;
  final String branch;
  final String logo;
  final String contactPerson;
  final String mobileNo;
  final String email;
  final DateTime created;
  final DateTime updated;

  Company({
    required this.id,
    required this.collectionId,
    required this.collectionName,
    required this.businessName,
    required this.legalName,
    required this.address,
    required this.landmark,
    required this.city,
    required this.district,
    required this.state,
    required this.pincode,
    required this.panNo,
    required this.gstNo,
    required this.stateCode,
    required this.gstFilingType,
    this.gstRegistrationDate,
    required this.bankName,
    required this.ifscCode,
    required this.accountNo,
    required this.branch,
    required this.logo,
    required this.contactPerson,
    required this.mobileNo,
    required this.email,
    required this.created,
    required this.updated,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] ?? '',
      collectionId: json['collectionId'] ?? '',
      collectionName: json['collectionName'] ?? '',
      businessName: json['business_name'] ?? '',
      legalName: json['legal_name'] ?? '',
      address: json['address'] ?? '',
      landmark: json['landmark'] ?? '',
      city: json['city'] ?? '',
      district: json['district'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      panNo: json['pan_no'] ?? '',
      gstNo: json['gst_no'] ?? '',
      stateCode: json['state_code']?.toString() ?? '',
      gstFilingType: json['gst_filing_type'] ?? '',
      gstRegistrationDate: json['gst_registration_date'] != null && json['gst_registration_date'].toString().isNotEmpty
          ? DateTime.parse(json['gst_registration_date'].toString())
          : null,
      bankName: json['bank_name'] ?? '',
      ifscCode: json['ifsc_code'] ?? '',
      accountNo: json['account_no'] ?? '',
      branch: json['branch'] ?? '',
      logo: json['logo'] ?? '',
      contactPerson: json['contact_person'] ?? '',
      mobileNo: json['mobile_no'] ?? '',
      email: json['email'] ?? '',
      created: DateTime.parse(json['created']),
      updated: DateTime.parse(json['updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'business_name': businessName,
      'legal_name': legalName,
      'address': address,
      'landmark': landmark,
      'city': city,
      'district': district,
      'state': state,
      'pincode': pincode,
      'pan_no': panNo,
      'gst_no': gstNo,
      'state_code': stateCode,
      'gst_filing_type': gstFilingType,
      'gst_registration_date': gstRegistrationDate?.toIso8601String(),
      'bank_name': bankName,
      'ifsc_code': ifscCode,
      'account_no': accountNo,
      'branch': branch,
      'logo': logo,
      'contact_person': contactPerson,
      'mobile_no': mobileNo,
      'email': email,
    };
  }
}
