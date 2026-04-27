import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/partner_provider.dart';
import '../../pb_service.dart';
import '../../theme/app_snackbars.dart';
import '../../theme/colors.dart';
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
  String? _draftId;

  // Controllers
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _personController = TextEditingController();
  final _billingAddressController = TextEditingController();
  final _billingLandmarkController = TextEditingController();
  final _billingCityController = TextEditingController();
  final _billingStateController = TextEditingController();
  final _billingPincodeController = TextEditingController();
  final _shippingBusinessController = TextEditingController();
  final _shippingAddressController = TextEditingController();
  final _shippingLandmarkController = TextEditingController();
  final _shippingCityController = TextEditingController();
  final _shippingStateController = TextEditingController();
  final _shippingPincodeController = TextEditingController();
  final _panController = TextEditingController();
  final _gstController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankAcController = TextEditingController();
  final _bankIfscController = TextEditingController();
  
  bool _hasDifferentShipping = false;
  String _partnerType = 'dealer';
  String _entityType = 'proprietor';
  String _bankAcType = 'saving';
  String _gstFrequency = 'monthly';
  DateTime _onboardingDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _checkAndResumeDraft();
  }

  Future<void> _checkAndResumeDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('pending_partner_onboarding_id');
    if (savedId != null) {
      _resumeJourney(savedId);
    }
  }

  Future<void> _resumeJourney(String id) async {
    setState(() => _isLoading = true);
    try {
      final record = await PbService().pb.collection('partner').getOne(id);
      setState(() {
        _draftId = id;
        _nameController.text = record.getStringValue('partner_name');
        _emailController.text = record.getStringValue('email');
        _mobileController.text = record.getStringValue('mobile_no');
        _personController.text = record.getStringValue('key_person_name');
        _billingAddressController.text = record.getStringValue('billing_address');
        _billingLandmarkController.text = record.getStringValue('billing_landmark');
        _billingCityController.text = record.getStringValue('billing_city');
        _billingStateController.text = record.getStringValue('billing_state');
        _billingPincodeController.text = record.getStringValue('billing_pincode');
        
        _hasDifferentShipping = record.getBoolValue('has_different_shipping_address');
        _shippingBusinessController.text = record.getStringValue('shipping_business_name');
        _shippingAddressController.text = record.getStringValue('shipping_address');
        _shippingLandmarkController.text = record.getStringValue('shipping_landmark');
        _shippingCityController.text = record.getStringValue('shipping_city');
        _shippingStateController.text = record.getStringValue('shipping_pincode');
        
        _panController.text = record.getStringValue('pan_no');
        _gstController.text = record.getStringValue('gst_no');
        _bankNameController.text = record.getStringValue('bank_name');
        _bankAcController.text = record.getStringValue('bank_ac_no');
        _bankIfscController.text = record.getStringValue('bank_ifsc_code');
        
        _partnerType = record.getStringValue('partner_type').isEmpty ? 'dealer' : record.getStringValue('partner_type');
        _entityType = record.getStringValue('entity_type').isEmpty ? 'proprietor' : record.getStringValue('entity_type');
        _bankAcType = record.getStringValue('bank_ac_type').isEmpty ? 'saving' : record.getStringValue('bank_ac_type');
        _gstFrequency = record.getStringValue('gst_filing_frequency').isEmpty ? 'monthly' : record.getStringValue('gst_filing_frequency');
        
        final dateStr = record.getStringValue('partner_onboarding_date');
        if (dateStr.isNotEmpty) _onboardingDate = DateTime.parse(dateStr);
      });
      if (mounted) AppSnackBars.showSuccess(context, 'Resuming journey');
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      prefs.remove('pending_partner_onboarding_id');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleClear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pending_partner_onboarding_id');
    
    setState(() {
      _draftId = null;
      _currentStep = 0;
      _nameController.clear();
      _emailController.clear();
      _mobileController.clear();
      _personController.clear();
      _billingAddressController.clear();
      _billingLandmarkController.clear();
      _billingCityController.clear();
      _billingStateController.clear();
      _billingPincodeController.clear();
      _shippingBusinessController.clear();
      _shippingAddressController.clear();
      _shippingLandmarkController.clear();
      _shippingCityController.clear();
      _shippingStateController.clear();
      _shippingPincodeController.clear();
      _panController.clear();
      _gstController.clear();
      _bankNameController.clear();
      _bankAcController.clear();
      _bankIfscController.clear();
      _onboardingDate = DateTime.now();
    });
    
    if (mounted) AppSnackBars.showSuccess(context, 'Form cleared. You can start a new journey.');
  }

  Future<void> _handleSaveData({bool isFinal = false}) async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(partnerRepositoryProvider);
      String partnerCode = '';
      if (isFinal) {
        partnerCode = await repo.getNextPartnerCode();
      }

      final body = {
        'partner_name': _nameController.text.trim(),
        'partner_code': partnerCode,
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
        'partner_active': isFinal,
      };

      if (_draftId == null) {
        final record = await PbService().pb.collection('partner').create(body: body);
        _draftId = record.id;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pending_partner_onboarding_id', _draftId!);
      } else {
        await PbService().pb.collection('partner').update(_draftId!, body: body);
      }

      if (isFinal) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('pending_partner_onboarding_id');
        if (mounted) {
          AppSnackBars.showSuccess(context, 'Onboarded: $partnerCode');
          ref.invalidate(allPartnersProvider);
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) AppSnackBars.showSuccess(context, 'Draft saved');
        ref.invalidate(allPartnersProvider);
      }
    } catch (e) {
      if (mounted) AppSnackBars.showError(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
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
            child: _isLoading && _currentStep == 0 && _draftId != null
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                    child: Form(key: _formKey, child: _buildStepContent()),
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
            _buildField('Partner Name *', _nameController, Icons.storefront_outlined, 'Required'),
            const SizedBox(height: 16),
            _buildField('Email Address *', _emailController, Icons.mail_outline_rounded, 'Required', keyboardType: TextInputType.emailAddress),
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

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // CLEAR BUTTON
            Expanded(
              child: _CompactButton(
                text: 'CLEAR',
                onPressed: _handleClear,
                color: Colors.redAccent,
                isOutline: true,
              ),
            ),
            const SizedBox(width: 8),
            
            // SAVE DATA BUTTON
            Expanded(
              child: _CompactButton(
                text: 'SAVE DATA',
                onPressed: () => _handleSaveData(isFinal: false),
                color: AppColors.primary,
                isOutline: true,
                isLoading: _isLoading,
              ),
            ),
            const SizedBox(width: 8),

            // CONTINUE / FINISH BUTTON
            Expanded(
              child: _CompactButton(
                text: _currentStep == 3 ? 'FINISH' : 'CONTINUE',
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    if (_currentStep < 3) {
                      setState(() => _currentStep++);
                    } else {
                      _handleSaveData(isFinal: true);
                    }
                  }
                },
                color: AppColors.primary,
                isOutline: false,
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
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

  Widget _buildField(String label, TextEditingController controller, IconData icon, String? errorMsg, {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: AppTypography.input,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTypography.bodySmall,
        prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.background,
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
                    child: Text('${index + 1}', style: TextStyle(color: isActive ? Colors.white : Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ),
                if (index < 3) Expanded(child: Container(height: 1.5, margin: const EdgeInsets.symmetric(horizontal: 4), color: isActive ? AppColors.primary : Colors.grey.shade300)),
              ],
            ),
          );
        }),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
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

class _CompactButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;
  final bool isOutline;
  final bool isLoading;

  const _CompactButton({
    required this.text,
    required this.onPressed,
    required this.color,
    this.isOutline = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: isOutline
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                side: BorderSide(color: color, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                foregroundColor: color,
              ),
              child: isLoading
                  ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: color))
                  : Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.white)),
            ),
    );
  }
}
