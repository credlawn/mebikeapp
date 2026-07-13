import 'dart:convert';

class InvoiceItem {
  String itemType;
  String? itemId;
  String itemCode;
  String itemName;
  String hsnCode;
  int gstSlab;
  double quantity;
  double unitPrice;
  double discountPercent;
  double taxableValue;
  double cgstRate;
  double sgstRate;
  double igstRate;
  double cgstAmount;
  double sgstAmount;
  double igstAmount;
  double total;
  bool isGstInclusive;

  InvoiceItem({
    required this.itemType,
    this.itemId,
    required this.itemCode,
    required this.itemName,
    required this.hsnCode,
    required this.gstSlab,
    this.quantity = 1,
    required this.unitPrice,
    this.discountPercent = 0,
    this.taxableValue = 0,
    this.cgstRate = 0,
    this.sgstRate = 0,
    this.igstRate = 0,
    this.cgstAmount = 0,
    this.sgstAmount = 0,
    this.igstAmount = 0,
    this.total = 0,
    this.isGstInclusive = false,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      itemType: json['item_type'] ?? '',
      itemId: json['item_id'],
      itemCode: json['item_code'] ?? '',
      itemName: json['item_name'] ?? '',
      hsnCode: json['hsn_code'] ?? '',
      gstSlab: json['gst_slab'] ?? 0,
      quantity: (json['quantity'] ?? 1).toDouble(),
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      discountPercent: (json['discount_percent'] ?? 0).toDouble(),
      taxableValue: (json['taxable_value'] ?? 0).toDouble(),
      cgstRate: (json['cgst_rate'] ?? 0).toDouble(),
      sgstRate: (json['sgst_rate'] ?? 0).toDouble(),
      igstRate: (json['igst_rate'] ?? 0).toDouble(),
      cgstAmount: (json['cgst_amount'] ?? 0).toDouble(),
      sgstAmount: (json['sgst_amount'] ?? 0).toDouble(),
      igstAmount: (json['igst_amount'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      isGstInclusive: json['is_gst_inclusive'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'item_type': itemType,
    'item_id': itemId,
    'item_code': itemCode,
    'item_name': itemName,
    'hsn_code': hsnCode,
    'gst_slab': gstSlab,
    'quantity': quantity,
    'unit_price': unitPrice,
    'discount_percent': discountPercent,
    'taxable_value': taxableValue,
    'cgst_rate': cgstRate,
    'sgst_rate': sgstRate,
    'igst_rate': igstRate,
    'cgst_amount': cgstAmount,
    'sgst_amount': sgstAmount,
    'igst_amount': igstAmount,
    'total': total,
    'is_gst_inclusive': isGstInclusive,
  };
}

class Invoice {
  final String id;
  final String collectionId;
  final String collectionName;
  final String invoiceNo;
  final String invoiceType;
  final DateTime invoiceDate;
  final DateTime? dueDate;
  final String? partnerId;
  final String? customerId;
  final String partyName;
  final String partyMobile;
  final String partyGst;
  final String partyStateCode;
  final String partyAddress;
  final String partyCity;
  final String partyDistrict;
  final String partyState;
  final String partyPincode;
  final List<InvoiceItem> items;
  final double subtotal;
  final double discount;
  final double taxable;
  final double cgstTotal;
  final double sgstTotal;
  final double igstTotal;
  final double roundOff;
  final double grandTotal;
  final String paymentMode;
  final String paymentStatus;
  final double paidAmount;
  final double balanceAmount;
  final String status;
  final String notes;
  final DateTime created;
  final DateTime updated;

  Invoice({
    required this.id,
    required this.collectionId,
    required this.collectionName,
    required this.invoiceNo,
    required this.invoiceType,
    required this.invoiceDate,
    this.dueDate,
    this.partnerId,
    this.customerId,
    this.partyName = '',
    this.partyMobile = '',
    this.partyGst = '',
    this.partyStateCode = '',
    this.partyAddress = '',
    this.partyCity = '',
    this.partyDistrict = '',
    this.partyState = '',
    this.partyPincode = '',
    required this.items,
    this.subtotal = 0,
    this.discount = 0,
    this.taxable = 0,
    this.cgstTotal = 0,
    this.sgstTotal = 0,
    this.igstTotal = 0,
    this.roundOff = 0,
    this.grandTotal = 0,
    this.paymentMode = '',
    this.paymentStatus = 'unpaid',
    this.paidAmount = 0,
    this.balanceAmount = 0,
    this.status = 'draft',
    this.notes = '',
    required this.created,
    required this.updated,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'];
    List<InvoiceItem> itemsList = [];
    if (itemsRaw != null) {
      if (itemsRaw is String && itemsRaw.isNotEmpty) {
        final parsed = jsonDecode(itemsRaw);
        if (parsed is List) {
          itemsList = parsed.map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>)).toList();
        }
      } else if (itemsRaw is List) {
        itemsList = itemsRaw.map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>)).toList();
      }
    }

    return Invoice(
      id: json['id'] ?? '',
      collectionId: json['collectionId'] ?? '',
      collectionName: json['collectionName'] ?? '',
      invoiceNo: json['invoice_no'] ?? '',
      invoiceType: json['invoice_type'] ?? '',
      invoiceDate: json['invoice_date'] != null
          ? DateTime.parse(json['invoice_date'].toString())
          : DateTime.now(),
      dueDate: json['due_date'] != null && json['due_date'].toString().isNotEmpty
          ? DateTime.parse(json['due_date'].toString())
          : null,
      partnerId: json['partner_id'],
      customerId: json['customer_id'],
      partyName: json['party_name'] ?? '',
      partyMobile: json['party_mobile'] ?? '',
      partyGst: json['party_gst'] ?? '',
      partyStateCode: json['party_state_code']?.toString() ?? '',
      partyAddress: json['party_address'] ?? '',
      partyCity: json['party_city'] ?? '',
      partyDistrict: json['party_district'] ?? '',
      partyState: json['party_state'] ?? '',
      partyPincode: json['party_pincode'] ?? '',
      items: itemsList,
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      taxable: (json['taxable'] ?? 0).toDouble(),
      cgstTotal: (json['cgst_total'] ?? 0).toDouble(),
      sgstTotal: (json['sgst_total'] ?? 0).toDouble(),
      igstTotal: (json['igst_total'] ?? 0).toDouble(),
      roundOff: (json['round_off'] ?? 0).toDouble(),
      grandTotal: (json['grand_total'] ?? 0).toDouble(),
      paymentMode: json['payment_mode'] ?? '',
      paymentStatus: json['payment_status'] ?? 'unpaid',
      paidAmount: (json['paid_amount'] ?? 0).toDouble(),
      balanceAmount: (json['balance_amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'draft',
      notes: json['notes'] ?? '',
      created: DateTime.parse(json['created']),
      updated: DateTime.parse(json['updated']),
    );
  }

  Map<String, dynamic> toJson() => {
    'invoice_no': invoiceNo,
    'invoice_type': invoiceType,
    'invoice_date': invoiceDate.toIso8601String(),
    'due_date': dueDate?.toIso8601String() ?? '',
    'partner_id': partnerId,
    'customer_id': customerId,
    'party_name': partyName,
    'party_mobile': partyMobile,
    'party_gst': partyGst,
    'party_state_code': partyStateCode,
    'party_address': partyAddress,
    'party_city': partyCity,
    'party_district': partyDistrict,
    'party_state': partyState,
    'party_pincode': partyPincode,
    'items': items.map((e) => e.toJson()).toList(),
    'subtotal': subtotal,
    'discount': discount,
    'taxable': taxable,
    'cgst_total': cgstTotal,
    'sgst_total': sgstTotal,
    'igst_total': igstTotal,
    'round_off': roundOff,
    'grand_total': grandTotal,
    'payment_mode': paymentMode,
    'payment_status': paymentStatus,
    'paid_amount': paidAmount,
    'balance_amount': balanceAmount,
    'status': status,
    'notes': notes,
  };
}
