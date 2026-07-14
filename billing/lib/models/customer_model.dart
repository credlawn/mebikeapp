class Customer {
  final String id;
  final String collectionId;
  final String collectionName;
  final String customerType;
  final String mobileNo;
  final String email;
  final String customerName;
  final String businessName;
  final String keyPersonName;
  final String careOf;
  final String gstNo;
  final String panNo;
  final String stateCode;
  final String address;
  final String city;
  final String district;
  final String state;
  final String pincode;
  final String status;
  final String customerId;
  final DateTime created;
  final DateTime updated;

  Customer({
    required this.id,
    required this.collectionId,
    required this.collectionName,
    required this.customerType,
    required this.mobileNo,
    required this.email,
    required this.customerName,
    required this.businessName,
    required this.keyPersonName,
    required this.careOf,
    required this.gstNo,
    required this.panNo,
    required this.stateCode,
    required this.address,
    required this.city,
    required this.district,
    required this.state,
    required this.pincode,
    required this.status,
    required this.customerId,
    required this.created,
    required this.updated,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] ?? '',
      collectionId: json['collectionId'] ?? '',
      collectionName: json['collectionName'] ?? '',
      customerType: json['customer_type'] ?? '',
      mobileNo: json['mobile_no'] ?? '',
      email: json['email'] ?? '',
      customerName: json['customer_name'] ?? '',
      businessName: json['business_name'] ?? '',
      keyPersonName: json['key_person_name'] ?? '',
      careOf: json['care_of'] ?? '',
      gstNo: json['gst_no'] ?? '',
      panNo: json['pan_no'] ?? '',
      stateCode: json['state_code']?.toString() ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      district: json['district'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      status: json['status'] ?? 'active',
      customerId: json['customer_id'] ?? '',
      created: DateTime.parse(json['created']),
      updated: DateTime.parse(json['updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_type': customerType,
      'mobile_no': mobileNo,
      'email': email,
      'customer_name': customerName,
      'business_name': businessName,
      'key_person_name': keyPersonName,
      'care_of': careOf,
      'gst_no': gstNo,
      'pan_no': panNo,
      'state_code': stateCode,
      'address': address,
      'city': city,
      'district': district,
      'state': state,
      'pincode': pincode,
      'status': status,
      'customer_id': customerId,
    };
  }
}
