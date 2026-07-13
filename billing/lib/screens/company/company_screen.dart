import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../providers/company_provider.dart';
import '../../config.dart';
import '../../theme/app_snackbars.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';

class CompanyScreen extends ConsumerStatefulWidget {
  const CompanyScreen({super.key});

  @override
  ConsumerState<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends ConsumerState<CompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _existingId;

  final _businessNameCtrl = TextEditingController();
  final _legalNameCtrl = TextEditingController();
  final _contactPersonCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _landmarkCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _accountNoCtrl = TextEditingController();
  final _branchCtrl = TextEditingController();

  String _stateCode = '';
  String _gstFilingType = '';
  DateTime? _gstRegistrationDate;
  bool _isMismatchDialogShowing = false;
  bool _isFetchingPincode = false;
  bool _isFetchingIfsc = false;
  bool _isFetchingGst = false;
  List<String> _stateSuggestions = [];
  final _stateFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadCompany();
    _panCtrl.addListener(_onPanChanged);
  }

  void _onPanChanged() {
    final pan = _panCtrl.text;
    if (pan.length != 10) return;
    final gst = _gstCtrl.text;
    final extracted = _extractPanFromGst(gst);
    if (extracted != null && pan != extracted) {
      _maybeShowMismatchDialog(extracted);
    }
  }

  String? _extractPanFromGst(String gst) {
    if (gst.length == 15) {
      final pan = gst.substring(2, 12);
      if (pan.length == 10) return pan;
    }
    return null;
  }

  void _maybeShowMismatchDialog(String correctPan) {
    if (_isMismatchDialogShowing || !mounted) return;
    _isMismatchDialogShowing = true;
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
            ),
            const SizedBox(height: 20),
            Text('Mismatch in PAN & GST', style: AppTypography.h2.copyWith(fontSize: 18)),
            const SizedBox(height: 12),
            Text(
              'The PAN number does not match the PAN extracted from the GST number.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _isMismatchDialogShowing = false;
                    Navigator.of(ctx).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Edit Manually', style: AppTypography.button.copyWith(color: AppColors.primary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _isMismatchDialogShowing = false;
                    _panCtrl.text = correctPan;
                    Navigator.of(ctx).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Auto Correct', style: AppTypography.button.copyWith(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    ).then((_) {
      _isMismatchDialogShowing = false;
    });
  }

  Future<void> _loadCompany() async {
    setState(() => _isLoading = true);
    try {
      final company = await ref.read(companyRepositoryProvider).getCompany();
      if (company != null) {
        _existingId = company.id;
        _businessNameCtrl.text = company.businessName;
        _legalNameCtrl.text = company.legalName;
        _contactPersonCtrl.text = company.contactPerson;
        _mobileCtrl.text = company.mobileNo;
        _emailCtrl.text = company.email;
        _addressCtrl.text = company.address;
        _landmarkCtrl.text = company.landmark;
        _cityCtrl.text = company.city;
        _districtCtrl.text = company.district;
        _stateCtrl.text = company.state;
        _pincodeCtrl.text = company.pincode;
        _panCtrl.text = company.panNo;
        _gstCtrl.text = company.gstNo;
        _stateCode = company.stateCode;
        _gstFilingType = company.gstFilingType;
        _gstRegistrationDate = company.gstRegistrationDate;
        _bankNameCtrl.text = company.bankName;
        _ifscCtrl.text = company.ifscCode;
        _accountNoCtrl.text = company.accountNo;
        _branchCtrl.text = company.branch;
      }
    } catch (_) {
      if (mounted) AppSnackBars.showError(context, 'Cannot reach server');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final body = {
        'business_name': _businessNameCtrl.text.trim(),
        'legal_name': _legalNameCtrl.text.trim(),
        'contact_person': _contactPersonCtrl.text.trim(),
        'mobile_no': _mobileCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'landmark': _landmarkCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'district': _districtCtrl.text.trim(),
        'state': _stateCtrl.text.trim(),
        'pincode': _pincodeCtrl.text.trim(),
        'pan_no': _panCtrl.text.trim(),
        'gst_no': _gstCtrl.text.trim(),
        'state_code': _stateCode,
        'gst_filing_type': _gstFilingType,
        'gst_registration_date': _gstRegistrationDate?.toIso8601String() ?? '',
        'bank_name': _bankNameCtrl.text.trim(),
        'ifsc_code': _ifscCtrl.text.trim(),
        'account_no': _accountNoCtrl.text.trim(),
        'branch': _branchCtrl.text.trim(),
      };

      await ref.read(companyRepositoryProvider).saveCompany(body, existingId: _existingId);
      ref.invalidate(companyProvider);
      if (mounted) {
        AppSnackBars.showSuccess(context, 'Company details saved');
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) AppSnackBars.showError(context, 'Save failed. Try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _fetchPincodeDetails() async {
    final pincode = _pincodeCtrl.text.trim();
    if (pincode.length != 6) {
      if (mounted) AppSnackBars.showError(context, 'Enter a valid 6-digit pincode');
      return;
    }
    setState(() => _isFetchingPincode = true);
    try {
      final res = await http.get(Uri.parse('${AppConfig.pincodeApiUrl}/pincode/$pincode')).timeout(const Duration(seconds: 10));
      if (!mounted) return;
      final data = (jsonDecode(res.body) as List).first as Map<String, dynamic>;
      if (data['Status'] != 'Success') {
        if (mounted) AppSnackBars.showError(context, 'Pincode not found');
        return;
      }
      final offices = data['PostOffice'] as List;
      if (offices.isEmpty) return;
      final first = offices.first as Map<String, dynamic>;
      final block = first['Block'] as String? ?? '';
      final district = first['District'] as String? ?? '';
      final state = first['State'] as String? ?? '';

      if (_cityCtrl.text.isEmpty && block.isNotEmpty) _cityCtrl.text = block;
      if (_districtCtrl.text.isEmpty && district.isNotEmpty) _districtCtrl.text = district;
      if (_stateCtrl.text.isEmpty && state.isNotEmpty) _stateCtrl.text = state;
      setState(() {});
    } catch (_) {
      if (mounted) AppSnackBars.showError(context, 'Cannot reach server');
    } finally {
      if (mounted) setState(() => _isFetchingPincode = false);
    }
  }

  Future<void> _fetchBankDetails() async {
    final ifsc = _ifscCtrl.text.trim();
    if (ifsc.length < 8) {
      if (mounted) AppSnackBars.showError(context, 'Enter a valid IFSC code');
      return;
    }
    setState(() => _isFetchingIfsc = true);
    try {
      final res = await http.get(Uri.parse('${AppConfig.ifscApiUrl}/$ifsc')).timeout(const Duration(seconds: 10));
      if (res.statusCode == 404) {
        if (mounted) AppSnackBars.showError(context, 'IFSC code not found');
        return;
      }
      if (!mounted) return;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      _bankNameCtrl.text = data['BANK'] ?? '';
      _branchCtrl.text = data['BRANCH'] ?? '';
      setState(() {});
    } catch (_) {
      if (mounted) AppSnackBars.showError(context, 'Cannot reach server');
    } finally {
      if (mounted) setState(() => _isFetchingIfsc = false);
    }
  }

  Future<void> _verifyGst() async {
    final gst = _gstCtrl.text.trim();
    if (gst.length != 15) {
      AppSnackBars.showError(context, 'Enter a valid 15-digit GST number');
      return;
    }
    setState(() => _isFetchingGst = true);
    try {
      final res = await http
          .get(
            Uri.parse('${AppConfig.gstApiUrl}/$gst'),
            headers: {'X-API-Key': AppConfig.gstApiKey},
          )
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (res.statusCode != 200) {
        final errData = res.body.isNotEmpty ? jsonDecode(res.body) as Map<String, dynamic> : {};
        final errMsg = errData['error'] as String? ?? 'GST verification failed';
        AppSnackBars.showError(context, errMsg);
        return;
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['success'] != true) {
        AppSnackBars.showError(context, 'GST verification failed');
        return;
      }
      final gstData = data['data'] as Map<String, dynamic>;
      final pincode = gstData['pincode'] as String?;
      DateTime? regDate;
      final dateStr = gstData['registration_date'] as String?;
      if (dateStr != null) {
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          try {
            final d = int.parse(parts[0]);
            final m = int.parse(parts[1]);
            final y = int.parse(parts[2]);
            regDate = DateTime.utc(y, m, d, 12);
          } catch (_) {}
        }
      }
      setState(() {
        _gstCtrl.text = gstData['gstin'] ?? gst;
        _panCtrl.text = gstData['pan'] ?? '';
        _legalNameCtrl.text = gstData['legal_name'] ?? '';
        _gstFilingType = gstData['taxpayer_type'] ?? '';
        _stateCode = gstData['state_code'] ?? '';
        _gstRegistrationDate = regDate;
        _businessNameCtrl.text = gstData['trade_name']?.toString().isNotEmpty == true
            ? gstData['trade_name']
            : (gstData['business_name'] ?? gstData['legal_name'] ?? '');
        _addressCtrl.text = gstData['address'] ?? '';
        _stateCtrl.text = gstData['state'] ?? '';
        _districtCtrl.text = gstData['district'] ?? '';
        _pincodeCtrl.text = pincode ?? '';
      });
      if (pincode != null && pincode.length == 6) {
        _fetchPincodeDetails();
      }
      if (mounted) AppSnackBars.showSuccess(context, 'GST verified: ${gstData['legal_name']}');
    } catch (_) {
      if (mounted) AppSnackBars.showError(context, 'Cannot reach server');
    } finally {
      if (mounted) setState(() => _isFetchingGst = false);
    }
  }

  String _toProperCase(String text) {
    return text.split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _legalNameCtrl.dispose();
    _contactPersonCtrl.dispose();
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _landmarkCtrl.dispose();
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    _panCtrl.removeListener(_onPanChanged);
    _panCtrl.dispose();
    _gstCtrl.dispose();
    _bankNameCtrl.dispose();
    _ifscCtrl.dispose();
    _accountNoCtrl.dispose();
    _branchCtrl.dispose();
    _stateFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Company Profile'),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _handleSave,
            child: _isSaving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                : Text('Save', style: AppTypography.button.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Business Information', 'Basic company details'),
                    const SizedBox(height: 24),
                    _buildField('Business Name *', _businessNameCtrl, Icons.business_outlined, 'Required', textCapitalization: TextCapitalization.words),
                    const SizedBox(height: 16),
                    _buildField('Legal Name', _legalNameCtrl, Icons.badge_outlined, null, textCapitalization: TextCapitalization.words),
                    const SizedBox(height: 16),
                    _buildField('Contact Person', _contactPersonCtrl, Icons.person_outline_rounded, null, textCapitalization: TextCapitalization.words),
                    const SizedBox(height: 16),
                    _buildField('Mobile Number', _mobileCtrl, Icons.phone_android_outlined, null, keyboardType: TextInputType.phone, formatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ]),
                    const SizedBox(height: 16),
                    _buildField('Email', _emailCtrl, Icons.mail_outline_rounded, null, keyboardType: TextInputType.emailAddress),

                    const SizedBox(height: 32),
                    Container(height: 1, color: AppColors.border),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Registered Address', 'Company location for invoices'),
                    const SizedBox(height: 24),
                    _buildField('GST No (auto-fill address)', _gstCtrl, Icons.receipt_outlined, null, formatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                      TextInputFormatter.withFunction((o, n) => n.copyWith(text: n.text.toUpperCase())),
                      LengthLimitingTextInputFormatter(15),
                    ], suffix: _isFetchingGst
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(width: 6, height: 6, child: CircularProgressIndicator(strokeWidth: 1, color: AppColors.primary)),
                          )
                        : SizedBox(
                            width: 36,
                            height: 24,
                            child: IconButton(
                              icon: const Icon(Icons.search_rounded, size: 20),
                              onPressed: _verifyGst,
                              padding: EdgeInsets.zero,
                            ),
                          )),
                    if (_legalNameCtrl.text.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          'Legal: ${_legalNameCtrl.text}',
                          style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildField('Street Address *', _addressCtrl, Icons.location_on_outlined, 'Required', maxLines: 2, textCapitalization: TextCapitalization.words),
                    const SizedBox(height: 16),
                    _buildField('Landmark', _landmarkCtrl, Icons.near_me_outlined, null, textCapitalization: TextCapitalization.words),
                    const SizedBox(height: 16),
                    _buildPincodeField(),
                    const SizedBox(height: 16),
                    _buildField('City *', _cityCtrl, Icons.apartment_outlined, 'Required', textCapitalization: TextCapitalization.words),
                    const SizedBox(height: 16),
                    _buildField('District *', _districtCtrl, Icons.map_outlined, 'Required', textCapitalization: TextCapitalization.words),
                    const SizedBox(height: 16),
                    _buildStateField('State *', 'Required'),

                    const SizedBox(height: 32),
                    Container(height: 1, color: AppColors.border),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Tax Information', 'PAN, GST, and compliance'),
                    const SizedBox(height: 24),
                    if (_panCtrl.text.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.credit_card_outlined, size: 18, color: AppColors.textSecondary),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('PAN No', style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textMuted)),
                                const SizedBox(height: 2),
                                Text(_panCtrl.text, style: AppTypography.bodyMedium),
                              ],
                            ),
                          ],
                        ),
                      )
                    else
                      _buildField('PAN No', _panCtrl, Icons.credit_card_outlined, null, formatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                        TextInputFormatter.withFunction((o, n) => n.copyWith(text: n.text.toUpperCase())),
                        LengthLimitingTextInputFormatter(10),
                      ]),
                    const SizedBox(height: 16),
                    if (_gstFilingType.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.description_outlined, size: 18, color: AppColors.textSecondary),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('GST Filing Type', style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textMuted)),
                                const SizedBox(height: 2),
                                Text(_gstFilingType, style: AppTypography.bodyMedium),
                              ],
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    if (_stateCode.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.pin_outlined, size: 18, color: AppColors.textSecondary),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('State Code', style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textMuted)),
                                const SizedBox(height: 2),
                                Text(_stateCode, style: AppTypography.bodyMedium),
                              ],
                            ),
                          ],
                        ),
                      ),
                    if (_gstRegistrationDate != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textSecondary),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('GST Registration Date', style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textMuted)),
                                const SizedBox(height: 2),
                                Text(DateFormat('dd MMM yyyy').format(_gstRegistrationDate!), style: AppTypography.bodyMedium),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                    Container(height: 1, color: AppColors.border),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Bank Details', 'Account information for payments'),
                    const SizedBox(height: 24),
                    _buildField('Account Number', _accountNoCtrl, Icons.format_list_numbered_rtl_outlined, null),
                    const SizedBox(height: 16),
                    _buildField('IFSC Code', _ifscCtrl, Icons.code_rounded, null, formatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                      TextInputFormatter.withFunction((o, n) => n.copyWith(text: n.text.toUpperCase())),
                      LengthLimitingTextInputFormatter(11),
                    ], suffix: _isFetchingIfsc
                        ? const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: SizedBox(width: 6, height: 6, child: CircularProgressIndicator(strokeWidth: 1, color: AppColors.primary)),
                          )
                        : SizedBox(
                            width: 36,
                            height: 24,
                            child: IconButton(
                              icon: const Icon(Icons.search_rounded, size: 20),
                              onPressed: _fetchBankDetails,
                              padding: EdgeInsets.zero,
                            ),
                          )),
                    if (_branchCtrl.text.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          '${_bankNameCtrl.text}, ${_toProperCase(_branchCtrl.text)}',
                          style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildField('Bank Name', _bankNameCtrl, Icons.account_balance_outlined, null),
                    const SizedBox(height: 16),
                    _buildField('Branch', _branchCtrl, Icons.business_outlined, null, textCapitalization: TextCapitalization.words),

                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text('Save Company Details', style: AppTypography.button.copyWith(color: Colors.white, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, String? errorMsg,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1, List<TextInputFormatter>? formatters, Widget? suffix, TextCapitalization textCapitalization = TextCapitalization.none}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      inputFormatters: formatters,
      style: AppTypography.input,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTypography.bodySmall,
        prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
        suffix: suffix,
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: errorMsg != null ? (v) => v!.isEmpty ? errorMsg : null : null,
    );
  }

  Widget _buildPincodeField() {
    return TextFormField(
      controller: _pincodeCtrl,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
      style: AppTypography.input,
      decoration: InputDecoration(
        labelText: 'Pincode *',
        labelStyle: AppTypography.bodySmall,
        prefixIcon: const Icon(Icons.pin_drop_outlined, size: 18, color: AppColors.textSecondary),
        suffix: _isFetchingPincode
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(width: 6, height: 6, child: CircularProgressIndicator(strokeWidth: 1, color: AppColors.primary)),
              )
            : SizedBox(
                width: 36,
                height: 24,
                child: IconButton(
                  icon: const Icon(Icons.search_rounded, size: 20),
                  onPressed: _fetchPincodeDetails,
                  padding: EdgeInsets.zero,
                ),
              ),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Required';
        if (v.length != 6) return 'Enter a valid 6-digit pincode';
        return null;
      },
    );
  }

  Widget _buildStateField(String label, String? errorMsg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: _stateCtrl,
          focusNode: _stateFocusNode,
          textCapitalization: TextCapitalization.words,
          style: AppTypography.input,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: AppTypography.bodySmall,
            prefixIcon: const Icon(Icons.map_outlined, size: 18, color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: _stateCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      _stateCtrl.clear();
                      setState(() => _stateSuggestions = []);
                    },
                  )
                : null,
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return errorMsg;
            if (!_indianStates.contains(v.trim())) return 'Select a valid state from the list';
            return null;
          },
          onChanged: (v) {
            if (v.isEmpty) {
              setState(() => _stateSuggestions = []);
            } else {
              final input = v.toLowerCase();
              setState(() => _stateSuggestions = _indianStates.where((s) => s.toLowerCase().contains(input)).toList());
            }
          },
        ),
        if (_stateSuggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 180),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: _stateSuggestions.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 16),
              itemBuilder: (_, i) {
                final option = _stateSuggestions[i];
                return ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: Text(option, style: AppTypography.bodyMedium.copyWith(fontSize: 13)),
                  onTap: () {
                    _stateCtrl.text = option;
                    _stateCtrl.selection = TextSelection.collapsed(offset: option.length);
                    setState(() => _stateSuggestions = []);
                    _stateFocusNode.unfocus();
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.h2),
        const SizedBox(height: 4),
        Text(sub, style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
      ],
    );
  }

  static const _indianStates = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand',
    'Karnataka', 'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur',
    'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha', 'Punjab',
    'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana', 'Tripura',
    'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
    'Andaman and Nicobar Islands', 'Chandigarh', 'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi', 'Jammu and Kashmir', 'Ladakh', 'Lakshadweep', 'Puducherry',
  ];
}
