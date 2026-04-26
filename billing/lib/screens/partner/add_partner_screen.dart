import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/partner_provider.dart';
import '../../pb_service.dart';
import '../../theme/app_snackbars.dart';
import '../../theme/colors.dart';
import '../../theme/buttons.dart';
import '../../theme/typography.dart';
import '../../theme/pickers.dart';

class AddPartnerScreen extends ConsumerStatefulWidget {
  const AddPartnerScreen({super.key});

  @override
  ConsumerState<AddPartnerScreen> createState() => _AddPartnerScreenState();
}

class _AddPartnerScreenState extends ConsumerState<AddPartnerScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isLoading = false;

  // Controllers - Basic & Contact
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _personController = TextEditingController();
  
  // Controllers - Billing
  final _billingAddressController = TextEditingController();
  final _billingLandmarkController = TextEditingController();
  final _billingCityController = TextEditingController();
  final _billingStateController = TextEditingController();
  final _billingPincodeController = TextEditingController();
  
  // Controllers - Shipping
  bool _hasDifferentShipping = false;
  final _shippingBusinessController = TextEditingController();
  final _shippingAddressController = TextEditingController();
  final _shippingLandmarkController = TextEditingController();
  final _shippingCityController = TextEditingController();
  final _shippingStateController = TextEditingController();
  final _shippingPincodeController = TextEditingController();

  // Controllers - Finance
  final _panController = TextEditingController();
  final _gstController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankAcController = TextEditingController();
  final _bankIfscController = TextEditingController();
  
  String _partnerType = 'dealer';
  String _entityType = 'proprietor';
  String _bankAcType = 'saving';
  String _gstFrequency = 'monthly';
  DateTime _onboardingDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _generateNextCode();
  }

  Future<void> _generateNextCode() async {
    final repo = ref.read(partnerRepositoryProvider);
    final nextCode = await repo.getNextPartnerCode();
    setState(() {
      _codeController.text = nextCode;
    });
  }

  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  Future<void> _handleSave() async {
    setState(() => _isLoading = true);
    try {
      final body = {
        'partner_name': _nameController.text.trim(),
        'partner_code': _codeController.text.trim(),
        'partner_type': _partnerType,
        'entity_type': _entityType,
        'key_person_name': _personController.text.trim(),
        'mobile_no': _mobileController.text.trim(),
        'email': _emailController.text.trim(),
        
        'billing_address': _billingAddressController.text.trim(),
        'billing_landmark': _billingLandmarkController.text.trim(),
        'billing_city': _billingCityController.text.trim(),
        'billing_state': _billingStateController.text.trim(),
        'billing_pincode': _billingPincodeController.text.trim(),
        
        'has_different_shipping_address': _hasDifferentShipping,
        'shipping_business_name': _shippingBusinessController.text.trim(),
        'shipping_address': _shippingAddressController.text.trim(),
        'shipping_landmark': _shippingLandmarkController.text.trim(),
        'shipping_city': _shippingCityController.text.trim(),
        'shipping_state': _shippingStateController.text.trim(),
        'shipping_pincode': _shippingPincodeController.text.trim(),
        
        'pan_no': _panController.text.trim(),
        'gst_no': _gstController.text.trim(),
        'gst_filing_frequency': _gstFrequency,
        
        'bank_name': _bankNameController.text.trim(),
        'bank_ac_no': _bankAcController.text.trim(),
        'bank_ifsc_code': _bankIfscController.text.trim(),
        'bank_ac_type': _bankAcType,
        
        'partner_onboarding_date': _onboardingDate.toIso8601String(),
        'partner_active': true,
      };

      await PbService().pb.collection('partner').create(body: body);
      
      if (mounted) {
        AppSnackBars.showSuccess(context, 'Partner successfully onboarded!');
        ref.invalidate(allPartnersProvider);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) AppSnackBars.showError(context, 'Failed to save: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Partner Onboarding'),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Form(
                key: _formKey,
                child: _buildStepContent(),
              ),
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader('Business Profile', 'Core identification details'),
            const SizedBox(height: 24),
            _buildDatePicker(),
            const SizedBox(height: 16),
            _buildField('Partner Code (Auto)', _codeController, Icons.badge_outlined, null, readOnly: true),
            const SizedBox(height: 16),
            _buildField('Partner Name *', _nameController, Icons.storefront_outlined, 'Required'),
            const SizedBox(height: 16),
            _buildField('Email Address *', _emailController, Icons.mail_outline_rounded, 'Required', keyboardType: TextInputType.emailAddress), // Email moved here
            const SizedBox(height: 16),
            AppPickerField(
              label: 'Partner Type',
              value: _toTitleCase(_partnerType),
              icon: Icons.tune_outlined,
              onTap: () async {
                final result = await AppPickers.showSelectionSheet<String>(
                  context: context,
                  title: 'Select Partner Type',
                  items: ['dealer', 'subdealer'],
                  labelBuilder: _toTitleCase,
                  selectedValue: _partnerType,
                );
                if (result != null) setState(() => _partnerType = result);
              },
            ),
            const SizedBox(height: 16),
            AppPickerField(
              label: 'Entity Type',
              value: _toTitleCase(_entityType),
              icon: Icons.category_outlined,
              onTap: () async {
                final result = await AppPickers.showSelectionSheet<String>(
                  context: context,
                  title: 'Select Entity Type',
                  items: ['proprietor', 'partnership', 'company'],
                  labelBuilder: _toTitleCase,
                  selectedValue: _entityType,
                );
                if (result != null) setState(() => _entityType = result);
              },
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader('Contact Details', 'Person responsible for communication'),
            const SizedBox(height: 24),
            _buildField('Key Person Name *', _personController, Icons.person_outline_rounded, 'Required'),
            const SizedBox(height: 16),
            _buildField('Mobile Number *', _mobileController, Icons.phone_android_outlined, 'Required', keyboardType: TextInputType.phone),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader('Billing Address', 'Registered location for invoices'),
            const SizedBox(height: 24),
            _buildField('Street Address *', _billingAddressController, Icons.location_on_outlined, 'Required', maxLines: 2),
            const SizedBox(height: 16),
            _buildField('Landmark', _billingLandmarkController, Icons.near_me_outlined, null),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildField('City *', _billingCityController, Icons.apartment_outlined, 'Required')),
                const SizedBox(width: 12),
                Expanded(child: _buildField('Pincode *', _billingPincodeController, Icons.pin_drop_outlined, 'Required', keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 16),
            _buildField('State *', _billingStateController, Icons.map_outlined, 'Required'),
            const SizedBox(height: 32),
            SwitchListTile(
              title: Text('Different Shipping Address?', style: AppTypography.h3),
              value: _hasDifferentShipping,
              onChanged: (v) => setState(() => _hasDifferentShipping = v),
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
            if (_hasDifferentShipping) ...[
              const SizedBox(height: 16),
              _buildStepHeader('Shipping Address', 'Delivery location'),
              const SizedBox(height: 16),
              _buildField('Business Name', _shippingBusinessController, Icons.business_outlined, null),
              const SizedBox(height: 16),
              _buildField('Street Address', _shippingAddressController, Icons.local_shipping_outlined, null, maxLines: 2),
              const SizedBox(height: 16),
              _buildField('Landmark', _shippingLandmarkController, Icons.near_me_outlined, null),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildField('City', _shippingCityController, Icons.apartment_outlined, null)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildField('Pincode', _shippingPincodeController, Icons.pin_drop_outlined, null, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 16),
              _buildField('State', _shippingStateController, Icons.map_outlined, null),
            ],
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader('Finance & Banking', 'Tax compliance and bank details'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildField('GST No', _gstController, Icons.receipt_outlined, null)),
                const SizedBox(width: 12),
                Expanded(
                  child: AppPickerField(
                    label: 'Filing',
                    value: _toTitleCase(_gstFrequency),
                    icon: Icons.event_repeat_outlined,
                    onTap: () async {
                      final result = await AppPickers.showSelectionSheet<String>(
                        context: context,
                        title: 'GST Filing Frequency',
                        items: ['monthly', 'quarterly'],
                        labelBuilder: _toTitleCase,
                        selectedValue: _gstFrequency,
                      );
                      if (result != null) setState(() => _gstFrequency = result);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildField('PAN No', _panController, Icons.credit_card_outlined, null),
            const SizedBox(height: 24),
            _buildField('Bank Name', _bankNameController, Icons.account_balance_outlined, null),
            const SizedBox(height: 16),
            _buildField('Account Number', _bankAcController, Icons.format_list_numbered_rtl_outlined, null),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildField('IFSC Code', _bankIfscController, Icons.code_rounded, null)),
                const SizedBox(width: 12),
                Expanded(
                  child: AppPickerField(
                    label: 'A/c Type',
                    value: _toTitleCase(_bankAcType),
                    icon: Icons.account_box_outlined,
                    onTap: () async {
                      final result = await AppPickers.showSelectionSheet<String>(
                        context: context,
                        title: 'Select Account Type',
                        items: ['saving', 'current'],
                        labelBuilder: _toTitleCase,
                        selectedValue: _bankAcType,
                      );
                      if (result != null) setState(() => _bankAcType = result);
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // --- UI Helpers ---

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : Colors.transparent,
                    border: Border.all(color: isActive ? AppColors.primary : Colors.grey.shade300),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.grey.shade400,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (index < 3)
                  Expanded(
                    child: Container(
                      height: 1.5,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color: isActive ? AppColors.primary : Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: AppButtons.outline(
                text: 'PREVIOUS',
                onPressed: () => setState(() => _currentStep--),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: AppButtons.primary(
              text: _currentStep == 3 ? 'ONBOARD PARTNER' : 'CONTINUE',
              isLoading: _isLoading,
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  if (_currentStep < 3) {
                    setState(() => _currentStep++);
                  } else {
                    _handleSave();
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader(String title, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.h2),
        const SizedBox(height: 4),
        Text(sub, style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, String? errorMsg, {TextInputType keyboardType = TextInputType.text, int maxLines = 1, bool readOnly = false}) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: AppTypography.input.copyWith(
        color: readOnly ? AppColors.textSecondary : AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTypography.bodySmall,
        prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
        filled: true,
        fillColor: readOnly ? Colors.grey.shade50 : AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: errorMsg != null ? (v) => v!.isEmpty ? errorMsg : null : null,
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _onboardingDate,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (picked != null) setState(() => _onboardingDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_note_outlined, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Onboarding Date *', style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text(DateFormat('dd MMMM yyyy').format(_onboardingDate), style: AppTypography.bodyMedium),
              ],
            ),
            const Spacer(),
            const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _personController.dispose();
    _billingAddressController.dispose();
    _billingLandmarkController.dispose();
    _billingCityController.dispose();
    _billingStateController.dispose();
    _billingPincodeController.dispose();
    _shippingBusinessController.dispose();
    _shippingAddressController.dispose();
    _shippingLandmarkController.dispose();
    _shippingCityController.dispose();
    _shippingStateController.dispose();
    _shippingPincodeController.dispose();
    _panController.dispose();
    _gstController.dispose();
    _bankNameController.dispose();
    _bankAcController.dispose();
    _bankIfscController.dispose();
    super.dispose();
  }
}
