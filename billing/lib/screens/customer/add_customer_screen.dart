import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../providers/customer_provider.dart';
import '../../pb_service.dart';
import '../../config.dart';
import '../../theme/app_snackbars.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';

class AddCustomerScreen extends ConsumerStatefulWidget {
  final String? customerId;
  final bool isEditing;

  const AddCustomerScreen({super.key, this.customerId, this.isEditing = false});

  @override
  ConsumerState<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends ConsumerState<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSaving = false;

  final _mobileCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _businessNameCtrl = TextEditingController();
  final _keyPersonCtrl = TextEditingController();
  final _careOfCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();

  final _gstCtrl = TextEditingController();
  final _panCtrl = TextEditingController();

  String _customerType = 'normal';
  String _stateCode = '';
  bool _isMismatchDialogShowing = false;
  bool _isFetchingPincode = false;
  bool _isFetchingGst = false;
  List<String> _stateSuggestions = [];
  final _stateFocusNode = FocusNode();

  String? _existingId;

  @override
  void initState() {
    super.initState();
    if (widget.customerId != null) {
      _loadCustomer(widget.customerId!);
    }
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

  Future<void> _loadCustomer(String id) async {
    setState(() => _isLoading = true);
    try {
      final record = await PbService().pb.collection('customer').getOne(id);
      final data = record.toJson();
      _existingId = id;
      _customerType = data['customer_type'] ?? 'normal';
      _mobileCtrl.text = data['mobile_no'] ?? '';
      _emailCtrl.text = data['email'] ?? '';
      _nameCtrl.text = data['customer_name'] ?? '';
      _businessNameCtrl.text = data['business_name'] ?? '';
      _keyPersonCtrl.text = data['key_person_name'] ?? '';
      _careOfCtrl.text = data['care_of'] ?? '';
      _gstCtrl.text = data['gst_no'] ?? '';
      _panCtrl.text = data['pan_no'] ?? '';
      _stateCode = data['state_code']?.toString() ?? '';
      _addressCtrl.text = data['address'] ?? '';
      _cityCtrl.text = data['city'] ?? '';
      _districtCtrl.text = data['district'] ?? '';
      _stateCtrl.text = data['state'] ?? '';
      _pincodeCtrl.text = data['pincode'] ?? '';
      setState(() {});
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
        'customer_type': _customerType,
        'mobile_no': _mobileCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'customer_name': _nameCtrl.text.trim(),
        'business_name': _businessNameCtrl.text.trim(),
        'key_person_name': _keyPersonCtrl.text.trim(),
        'care_of': _careOfCtrl.text.trim(),
        'gst_no': _gstCtrl.text.trim(),
        'pan_no': _panCtrl.text.trim(),
        'state_code': _stateCode,
        'address': _addressCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'district': _districtCtrl.text.trim(),
        'state': _stateCtrl.text.trim(),
        'pincode': _pincodeCtrl.text.trim(),
        'status': 'active',
      };

      final repo = ref.read(customerRepositoryProvider);
      if (_existingId != null) {
        await repo.updateCustomer(_existingId!, body);
      } else {
        await repo.createCustomer(body);
      }
      ref.invalidate(allCustomersProvider);
      if (mounted) {
        AppSnackBars.showSuccess(context, widget.isEditing ? 'Customer updated' : 'Customer created');
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) AppSnackBars.showError(context, 'Save failed. Try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _fetchPincodeDetails() async {
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

  void _verifyGst() async {
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

      setState(() {
        _gstCtrl.text = gstData['gstin'] ?? gst;
        _panCtrl.text = gstData['pan'] ?? '';
        _stateCode = gstData['state_code'] ?? '';

        if (_customerType == 'gst_individual') {
          _careOfCtrl.text = gstData['trade_name'] ?? '';
        }

        _addressCtrl.text = gstData['address'] ?? '';
        _stateCtrl.text = gstData['state'] ?? '';
        _districtCtrl.text = gstData['district'] ?? '';
        _pincodeCtrl.text = pincode ?? '';
      });
      if (pincode != null && pincode.length == 6) {
        _fetchPincodeDetails();
      }
      if (mounted) AppSnackBars.showSuccess(context, 'GST verified');
    } catch (_) {
      if (mounted) AppSnackBars.showError(context, 'Cannot reach server');
    } finally {
      if (mounted) setState(() => _isFetchingGst = false);
    }
  }

  @override
  void dispose() {
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    _businessNameCtrl.dispose();
    _keyPersonCtrl.dispose();
    _careOfCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    _gstCtrl.dispose();
    _panCtrl.removeListener(_onPanChanged);
    _panCtrl.dispose();
    _stateFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Customer' : 'New Customer'),
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
                    _buildSectionHeader('Customer Type', 'Select the type of customer'),
                    const SizedBox(height: 16),
                    _buildCustomerTypeChips(),
                    const SizedBox(height: 24),
                    Container(height: 1, color: AppColors.border),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Contact Information', 'Mobile number is required'),
                    const SizedBox(height: 24),

                    if (_customerType == 'normal' || _customerType == 'gst_individual') ...[
                      _buildField('Customer Name *', _nameCtrl, Icons.person_outline_rounded, 'Required', textCapitalization: TextCapitalization.words),
                      const SizedBox(height: 16),
                    ],

                    TextFormField(
                      controller: _mobileCtrl,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      style: AppTypography.input,
                      decoration: InputDecoration(
                        labelText: 'Mobile Number *',
                        labelStyle: AppTypography.bodySmall,
                        prefixIcon: const Icon(Icons.phone_android_outlined, size: 18, color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (v.length != 10) return 'Enter a valid 10-digit mobile number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildField('Email (optional)', _emailCtrl, Icons.mail_outline_rounded, null, keyboardType: TextInputType.emailAddress),

                    if (_customerType != 'normal') ...[
                      const SizedBox(height: 32),
                      Container(height: 1, color: AppColors.border),
                      const SizedBox(height: 24),
                      _buildSectionHeader('GST Details', 'Verify GST to auto-fill details'),
                      const SizedBox(height: 24),
                      _buildField('GST No', _gstCtrl, Icons.receipt_outlined, null, formatters: [
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
                      if (_customerType == 'gst_individual') ...[
                        const SizedBox(height: 16),
                        _buildField('C/O (Trade Name)', _careOfCtrl, Icons.badge_outlined, null, textCapitalization: TextCapitalization.words),
                      ],
                    ],

                    const SizedBox(height: 32),
                    Container(height: 1, color: AppColors.border),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Address', 'Pincode auto-fetches city/district/state'),
                    const SizedBox(height: 24),
                    _buildField('Street Address *', _addressCtrl, Icons.location_on_outlined, 'Required', maxLines: 2, textCapitalization: TextCapitalization.words),
                    const SizedBox(height: 16),
                    _buildPincodeField(),
                    const SizedBox(height: 16),
                    _buildField('City *', _cityCtrl, Icons.apartment_outlined, 'Required', textCapitalization: TextCapitalization.words),
                    const SizedBox(height: 16),
                    _buildField('District *', _districtCtrl, Icons.map_outlined, 'Required', textCapitalization: TextCapitalization.words),
                    const SizedBox(height: 16),
                    _buildStateField('State *', isRequired: true),
                    if (_stateCode.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          'State Code: $_stateCode',
                          style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                    if (_panCtrl.text.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          'PAN: ${_panCtrl.text}',
                          style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ),
                    ],

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
                            : Text('Save Customer', style: AppTypography.button.copyWith(color: Colors.white, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCustomerTypeChips() {
    return Row(
      children: [
        _typeChip('normal', 'Non GST', Icons.person_outlined),
        const SizedBox(width: 8),
        _typeChip('gst_individual', 'GST', Icons.receipt_outlined),
      ],
    );
  }

  Widget _typeChip(String type, String label, IconData icon) {
    final selected = _customerType == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _customerType = type),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.5 : 1),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: selected ? AppColors.primary : AppColors.textMuted),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 10,
                  color: selected ? AppColors.primary : AppColors.textMuted,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
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
        labelText: 'Pincode',
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
    );
  }

  Widget _buildStateField(String label, {bool isRequired = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: _stateCtrl,
          focusNode: _stateFocusNode,
          textCapitalization: TextCapitalization.words,
          style: AppTypography.input,
          validator: isRequired ? (v) => v!.isEmpty ? 'Required' : null : null,
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
