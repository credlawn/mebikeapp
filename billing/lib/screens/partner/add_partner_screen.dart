import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pocketbase/pocketbase.dart';
import '../../providers/partner_provider.dart';
import '../../pb_service.dart';
import '../../config.dart';
import '../../theme/app_snackbars.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/pickers.dart';
import '../../services/date_utils.dart';

class AddPartnerScreen extends ConsumerStatefulWidget {
  final String? draftId;
  final bool isEditing;

  const AddPartnerScreen({super.key, this.draftId, this.isEditing = false});

  @override
  ConsumerState<AddPartnerScreen> createState() => _AddPartnerScreenState();
}

enum _SyncState { syncing, synced, error }

class _AddPartnerScreenState extends ConsumerState<AddPartnerScreen> {
  static const _timeout = Duration(seconds: 15);

  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isLoading = false;
  String? _draftId;
  _SyncState? _syncState;

  // Controllers
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _personController = TextEditingController();
  final _billingAddressController = TextEditingController();
  final _billingBusinessController = TextEditingController();
  final _billingLandmarkController = TextEditingController();
  final _billingCityController = TextEditingController();
  final _billingDistrictController = TextEditingController();
  final _billingStateController = TextEditingController();
  final _billingPincodeController = TextEditingController();
  final _shippingBusinessController = TextEditingController();
  final _shippingAddressController = TextEditingController();
  final _shippingLandmarkController = TextEditingController();
  final _shippingCityController = TextEditingController();
  final _shippingDistrictController = TextEditingController();
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
  String _bankAcType = 'current';
  String _gstFilingType = '';
  String _stateCode = '';
  String _natureOfBusiness = '';
  DateTime? _gstRegistrationDate;
  DateTime _onboardingDate = DateTime.now();
  String _partnerCode = '';
  String _partnerStatus = 'draft';
  bool _isMismatchDialogShowing = false;
  String _bankBranch = '';
  String _bankCity = '';
  bool _isFetchingIfsc = false;
  List<String> _billingStateSuggestions = [];
  List<String> _shippingStateSuggestions = [];
  final _billingStateFocus = FocusNode();
  final _shippingStateFocus = FocusNode();
  bool _isFetchingBillingPincode = false;
  bool _isFetchingShippingPincode = false;
  bool _isFetchingGstBilling = false;
  final _gstBillingController = TextEditingController();
  @override
  void initState() {
    super.initState();
    if (widget.draftId != null) {
      _loadFromServer(widget.draftId!);
    }
    _gstController.addListener(_onGstChanged);
    _panController.addListener(_onPanChanged);
    _gstBillingController.addListener(() {
      if (_gstController.text != _gstBillingController.text) {
        _gstController.text = _gstBillingController.text;
      }
    });
  }

  String? _extractPanFromGst(String gst) {
    if (gst.length == 15) {
      final pan = gst.substring(2, 12);
      if (pan.length == 10) return pan;
    }
    return null;
  }

  Future<bool> _emailExists(String email) async {
    if (email.isEmpty) return false;
    final result = await PbService().pb.collection('partner').getList(
      filter: 'email = "$email" && partner_status != "draft"',
      perPage: 1,
    );
    if (result.items.isEmpty) return false;
    if (_draftId != null && result.items.first.id == _draftId) return false;
    return true;
  }

  void _onGstChanged() {
    final gst = _gstController.text;
    final pan = _panController.text;
    final extracted = _extractPanFromGst(gst);

    if (extracted == null) return;

    if (pan.isEmpty) {
      _panController.text = extracted;
    } else if (pan != extracted) {
      _maybeShowMismatchDialog(extracted);
    }
  }

  void _onPanChanged() {
    final pan = _panController.text;
    if (pan.length != 10) return;
    final gst = _gstController.text;
    final extracted = _extractPanFromGst(gst);
    if (extracted != null && pan != extracted) {
      _maybeShowMismatchDialog(extracted);
    }
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
                    _panController.text = correctPan;
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

  Future<void> _loadFromServer(String id) async {
    setState(() => _isLoading = true);
    try {
      final record = await PbService().pb.collection('partner').getOne(id).timeout(_timeout);
      _populateForm(record.toJson());
      _draftId = id;
    } catch (e) {
      if (mounted) AppSnackBars.showError(context, 'Cannot reach server');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _populateForm(Map<String, dynamic> data) {
    setState(() {
      _nameController.text = data['legal_name'] ?? '';
      _emailController.text = data['email'] ?? '';
      _mobileController.text = data['mobile_no'] ?? '';
      _personController.text = data['key_person_name'] ?? '';
      _billingBusinessController.text = data['partner_name'] ?? '';
      _billingAddressController.text = data['billing_address'] ?? '';
      _billingLandmarkController.text = data['billing_landmark'] ?? '';
      _billingCityController.text = data['billing_city'] ?? '';
      _billingDistrictController.text = data['billing_district'] ?? '';
      _billingStateController.text = data['billing_state'] ?? '';
      _billingPincodeController.text = data['billing_pincode'] ?? '';
      
      _hasDifferentShipping = data['has_different_shipping_address'] ?? false;
      _shippingBusinessController.text = data['shipping_business_name'] ?? '';
      _shippingAddressController.text = data['shipping_address'] ?? '';
      _shippingLandmarkController.text = data['shipping_landmark'] ?? '';
      _shippingCityController.text = data['shipping_city'] ?? '';
      _shippingDistrictController.text = data['shipping_district'] ?? '';
      _shippingStateController.text = data['shipping_state'] ?? '';
      
      _panController.text = data['pan_no'] ?? '';
      _gstController.text = data['gst_no'] ?? '';
      _gstBillingController.text = data['gst_no'] ?? '';
      _bankNameController.text = data['bank_name'] ?? '';
      _bankAcController.text = data['bank_ac_no'] ?? '';
      _bankIfscController.text = data['bank_ifsc_code'] ?? '';
      _bankBranch = data['bank_branch'] ?? '';
      _bankCity = data['bank_city'] ?? '';
      
      _partnerCode = data['partner_code']?.toString() ?? '';
      _partnerStatus = data['partner_status']?.toString() ?? 'active';
      _partnerType = data['partner_type']?.toString().isEmpty ?? true ? 'dealer' : data['partner_type'];
      _entityType = data['entity_type']?.toString().isEmpty ?? true ? 'proprietor' : data['entity_type'];
      _gstFilingType = data['gst_filing_type']?.toString() ?? '';
      _stateCode = data['state_code']?.toString() ?? '';
      _natureOfBusiness = data['nature_of_business']?.toString() ?? '';
      if (data['gst_registration_date'] != null) {
        _gstRegistrationDate = DateTime.parse(data['gst_registration_date'].toString());
      }
      _bankAcType = data['bank_ac_type']?.toString().isEmpty ?? true ? 'saving' : data['bank_ac_type'];
      
      if (data['partner_onboarding_date'] != null) {
        _onboardingDate = DateTime.parse(data['partner_onboarding_date']);
      }
    });
  }

  Future<String?> _showFinishConfirmDialog() {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.flag_outlined,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 20),
            Text('Finalize Partner', style: AppTypography.h2.copyWith(fontSize: 18)),
            const SizedBox(height: 12),
            Text(
              'A partner code will be generated and the partner will be moved out of drafts. Choose the initial status:',
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
                  onPressed: () => Navigator.of(ctx).pop('inactive'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textMuted,
                    side: BorderSide(color: AppColors.textMuted.withValues(alpha: 0.4), width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Keep Inactive', style: AppTypography.button.copyWith(color: AppColors.textMuted)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop('active'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Make Active', style: AppTypography.button.copyWith(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _buildBody({String partnerCode = '', String status = 'draft'}) {
    final effectiveCode = _partnerCode.isNotEmpty ? _partnerCode : partnerCode;
    final effectiveStatus = _partnerCode.isNotEmpty ? _partnerStatus : status;
    return {
      'name': _billingBusinessController.text.trim(),
      'partner_name': _billingBusinessController.text.trim(),
      'legal_name': _nameController.text.trim(),
      'partner_code': effectiveCode,
      'partner_type': _partnerType,
      'entity_type': _entityType,
      'key_person_name': _personController.text.trim(),
      'mobile_no': _mobileController.text.trim(),
      'email': _emailController.text.trim(),
      'billing_address': _billingAddressController.text.trim(),
      'billing_landmark': _billingLandmarkController.text.trim(),
      'billing_city': _billingCityController.text.trim(),
      'billing_district': _billingDistrictController.text.trim(),
      'billing_state': _billingStateController.text.trim(),
      'billing_pincode': _billingPincodeController.text.trim(),
      'has_different_shipping_address': _hasDifferentShipping,
      'shipping_business_name': _shippingBusinessController.text.trim(),
      'shipping_address': _shippingAddressController.text.trim(),
      'shipping_landmark': _shippingLandmarkController.text.trim(),
      'shipping_city': _shippingCityController.text.trim(),
      'shipping_district': _shippingDistrictController.text.trim(),
      'shipping_state': _shippingStateController.text.trim(),
      'shipping_pincode': _shippingPincodeController.text.trim(),
      'pan_no': _panController.text.trim(),
      'gst_no': _gstController.text.trim(),
      'gst_filing_type': _gstFilingType,
      'state_code': _stateCode,
      'nature_of_business': _natureOfBusiness,
      'gst_registration_date': _gstRegistrationDate?.toIso8601String() ?? '',
      'bank_ifsc_code': _bankIfscController.text.trim(),
      'bank_name': _bankIfscController.text.trim().isEmpty ? '' : _bankNameController.text.trim(),
      'bank_ac_no': _bankIfscController.text.trim().isEmpty ? '' : _bankAcController.text.trim(),
      'bank_ac_type': _bankIfscController.text.trim().isEmpty ? '' : _bankAcType,
      'bank_branch': _bankIfscController.text.trim().isEmpty ? '' : _bankBranch,
      'bank_city': _bankIfscController.text.trim().isEmpty ? '' : _bankCity,
      'partner_onboarding_date': AppDateUtils.toServerDate(_onboardingDate).toIso8601String(),
      'partner_status': effectiveStatus,
    };
  }

  void _resetSyncState() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _syncState = null);
    });
  }

  Future<void> _handleSaveData({required bool isFinal, bool advanceStep = false, String status = 'draft'}) async {
    setState(() {
      _isLoading = true;
      _syncState = _SyncState.syncing;
    });

    final email = _emailController.text.trim();
    if (email.isNotEmpty) {
      try {
        final exists = await _emailExists(email);
        if (exists) {
          if (mounted) {
            AppSnackBars.showError(context, 'Email already registered. Please use a different email.');
            setState(() { _isLoading = false; _syncState = null; });
          }
          return;
        }
      } catch (_) {
        if (mounted) {
          AppSnackBars.showError(context, 'Cannot verify email. Please try again.');
          setState(() { _isLoading = false; _syncState = null; });
        }
        return;
      }
    }

    if (isFinal) {
      final gst = _gstController.text;
      final pan = _panController.text;
      final extracted = _extractPanFromGst(gst);
      if (extracted != null && pan.isNotEmpty && pan != extracted) {
        if (mounted) {
          AppSnackBars.showError(context, 'PAN & GST number mismatch. Please correct or clear the PAN field.');
          setState(() { _isLoading = false; _syncState = null; });
        }
        return;
      }
    }

    try {
      final repo = ref.read(partnerRepositoryProvider);
      String partnerCode = '';

      if (isFinal && !widget.isEditing) {
        partnerCode = await repo.getNextPartnerCode().timeout(_timeout);
      }

      final body = _buildBody(partnerCode: partnerCode, status: isFinal ? status : 'draft');

      if (_draftId == null) {
        final email = _emailController.text.trim();
        if (email.isNotEmpty) {
          final existing = await PbService().pb.collection('partner').getList(
            filter: 'email = "$email" && partner_status = "draft"',
            perPage: 1,
          );
          if (existing.items.isNotEmpty) {
            _draftId = existing.items.first.id;
          }
        }
      }

      if (_draftId == null) {
        final record = await PbService().pb.collection('partner').create(body: body).timeout(_timeout);
        _draftId = record.id;
      } else {
        await PbService().pb.collection('partner').update(_draftId!, body: body).timeout(_timeout);
      }

      if (isFinal) {
        if (mounted) {
          AppSnackBars.showSuccess(context, widget.isEditing ? 'Changes Applied' : 'Partner Onboarded: $partnerCode');
          Navigator.of(context).pop();
        }
        WidgetsBinding.instance.addPostFrameCallback((_) => ref.invalidate(allPartnersProvider));
      } else {
        if (mounted) {
          setState(() {
            _syncState = _SyncState.synced;
            if (advanceStep) _currentStep++;
          });
          _resetSyncState();
        }
      }
    } on ClientException catch (e) {
      if (mounted) {
        if (e.statusCode == 404) {
          _draftId = null;
          setState(() => _syncState = _SyncState.error);
          _resetSyncState();
        } else {
          setState(() => _syncState = _SyncState.error);
          _resetSyncState();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _syncState = _SyncState.error);
        _resetSyncState();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchPincodeDetails(TextEditingController pincodeCtrl, TextEditingController cityCtrl, TextEditingController districtCtrl, TextEditingController stateCtrl) async {
    final pincode = pincodeCtrl.text.trim();
    if (pincode.length != 6) {
      if (mounted) AppSnackBars.showError(context, 'Enter a valid 6-digit pincode');
      return;
    }
    setState(() {});
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

      if (cityCtrl.text.isEmpty && block.isNotEmpty) cityCtrl.text = block;
      if (districtCtrl.text.isEmpty && district.isNotEmpty) districtCtrl.text = district;
      if (stateCtrl.text.isEmpty && state.isNotEmpty) stateCtrl.text = state;
      setState(() {});
    } catch (_) {
      if (mounted) AppSnackBars.showError(context, 'Cannot reach server');
    } finally {
      if (mounted) setState(() {});
    }
  }

  Widget _buildPincodeField(String label, TextEditingController controller, IconData icon, String? errorMsg,
      {required bool isFetching, required VoidCallback onSearch}) {
    return _buildField(label, controller, icon, errorMsg, keyboardType: TextInputType.number, suffix: isFetching
        ? const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(width: 6, height: 6, child: CircularProgressIndicator(strokeWidth: 1, color: AppColors.primary)),
          )
        : SizedBox(
            width: 36,
            height: 24,
            child: IconButton(
              icon: const Icon(Icons.search_rounded, size: 20),
              onPressed: onSearch,
              padding: EdgeInsets.zero,
            ),
          ));
  }

  Future<void> _fetchBankDetails() async {
    final ifsc = _bankIfscController.text.trim();
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
      _bankNameController.text = data['BANK'] ?? '';
      _bankBranch = data['BRANCH'] ?? '';
      _bankCity = data['CITY'] ?? '';
      setState(() {});
    } catch (_) {
      if (mounted) AppSnackBars.showError(context, 'Cannot reach server');
    } finally {
      if (mounted) setState(() => _isFetchingIfsc = false);
    }
  }

  Future<String?> _verifyGstAndFill(String gst) async {
    if (gst.length != 15) {
      AppSnackBars.showError(context, 'Enter a valid 15-digit GST number');
      return null;
    }
    try {
      final res = await http
          .get(
            Uri.parse('${AppConfig.gstApiUrl}/$gst'),
            headers: {'X-API-Key': AppConfig.gstApiKey},
          )
          .timeout(const Duration(seconds: 10));
      if (!mounted) return null;
      if (res.statusCode != 200) {
        final errData = res.body.isNotEmpty ? jsonDecode(res.body) as Map<String, dynamic> : {};
        final errMsg = errData['error'] as String? ?? 'GST verification failed';
        AppSnackBars.showError(context, errMsg);
        return null;
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['success'] != true) {
        AppSnackBars.showError(context, 'GST verification failed');
        return null;
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
        _gstController.text = gstData['gstin'] ?? gst;
        _gstBillingController.text = gstData['gstin'] ?? gst;
        _panController.text = gstData['pan'] ?? '';
        _nameController.text = gstData['legal_name'] ?? '';
        _entityType = gstData['constitution'] ?? '';
        _gstFilingType = gstData['taxpayer_type'] ?? '';
        _stateCode = gstData['state_code'] ?? '';
        final nob = gstData['nature_of_business'];
        _natureOfBusiness = nob is List ? nob.join(', ') : nob?.toString() ?? '';
        _gstRegistrationDate = regDate;
        _billingBusinessController.text = gstData['trade_name'] ?? '';
        _billingAddressController.text = gstData['address'] ?? '';
        _billingStateController.text = gstData['state'] ?? '';
        _billingDistrictController.text = gstData['district'] ?? '';
        _billingPincodeController.text = pincode ?? '';
      });
      if (pincode != null && pincode.length == 6) {
        _fetchPincodeDetails(_billingPincodeController, _billingCityController, _billingDistrictController, _billingStateController);
      }
      if (mounted) AppSnackBars.showSuccess(context, 'GST verified: ${gstData['legal_name']}');
      return gstData['legal_name'] as String?;
    } catch (_) {
      if (mounted) AppSnackBars.showError(context, 'Cannot reach server');
      return null;
    }
  }

  Widget _buildSyncIndicator() {
    switch (_syncState) {
      case _SyncState.syncing:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
        );
      case _SyncState.synced:
        return const Icon(Icons.cloud_done_outlined, size: 22, color: Colors.green);
      case _SyncState.error:
        return const Icon(Icons.cloud_off_outlined, size: 22, color: AppColors.error);
      default:
        return const Icon(Icons.cloud_queue_rounded, size: 22, color: AppColors.textMuted);
    }
  }

  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  String _toProperCase(String text) {
    return text.split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Partner' : 'Partner Onboarding'),
        elevation: 0,
        actions: [
          GestureDetector(
            onTap: _isLoading ? null : () => _handleSaveData(isFinal: false),
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _buildSyncIndicator(),
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: _isLoading && _currentStep == 0
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
            _buildStepHeader('Business Profile', 'Partner identification and contact'),
            const SizedBox(height: 24),
            _buildDatePicker(),
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
            _buildField('Email Address *', _emailController, Icons.mail_outline_rounded, 'Required', keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            _buildField('Key Person Name *', _personController, Icons.person_outline_rounded, 'Required', textCapitalization: TextCapitalization.words),
            const SizedBox(height: 16),
            TextFormField(
              controller: _mobileController,
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
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader('Billing Address', 'Registered location for invoices'),
            const SizedBox(height: 24),
            _buildField('GST No (auto-fill address)', _gstBillingController, Icons.receipt_outlined, null, suffix: _isFetchingGstBilling
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 6, height: 6, child: CircularProgressIndicator(strokeWidth: 1, color: AppColors.primary)),
                  )
                : SizedBox(
                    width: 36,
                    height: 24,
                    child: IconButton(
                      icon: const Icon(Icons.search_rounded, size: 20),
                      onPressed: () async {
                        setState(() => _isFetchingGstBilling = true);
                        await _verifyGstAndFill(_gstBillingController.text.trim());
                        if (mounted) setState(() => _isFetchingGstBilling = false);
                      },
                      padding: EdgeInsets.zero,
                    ),
                  ), formatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
              TextInputFormatter.withFunction((o, n) => n.copyWith(text: n.text.toUpperCase())),
              LengthLimitingTextInputFormatter(15),
            ]),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              readOnly: true,
              style: AppTypography.input.copyWith(color: AppColors.textSecondary),
              decoration: InputDecoration(
                labelText: 'Legal Name',
                labelStyle: AppTypography.bodySmall,
                prefixIcon: const Icon(Icons.badge_outlined, size: 18, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.category_outlined, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Entity Type', style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textMuted)),
                      const SizedBox(height: 2),
                      Text(_toTitleCase(_entityType), style: AppTypography.bodyMedium),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildField('Partner Name', _billingBusinessController, Icons.business_outlined, null, textCapitalization: TextCapitalization.words),
            const SizedBox(height: 16),
            _buildField('Street Address *', _billingAddressController, Icons.location_on_outlined, 'Required', maxLines: 2, textCapitalization: TextCapitalization.words),
            const SizedBox(height: 16),
            _buildField('Landmark', _billingLandmarkController, Icons.near_me_outlined, null, textCapitalization: TextCapitalization.words),
            const SizedBox(height: 16),
            _buildPincodeField('Pincode *', _billingPincodeController, Icons.pin_drop_outlined, 'Required',
                isFetching: _isFetchingBillingPincode,
                onSearch: () {
                  setState(() => _isFetchingBillingPincode = true);
                  _fetchPincodeDetails(_billingPincodeController, _billingCityController, _billingDistrictController, _billingStateController).then((_) {
                    if (mounted) setState(() => _isFetchingBillingPincode = false);
                  });
                }),
            const SizedBox(height: 16),
            _buildField('City *', _billingCityController, Icons.apartment_outlined, 'Required', textCapitalization: TextCapitalization.words),
            const SizedBox(height: 16),
            _buildField('District *', _billingDistrictController, Icons.map_outlined, 'Required', textCapitalization: TextCapitalization.words),
            const SizedBox(height: 16),
            _buildStateField('State *', _billingStateController, Icons.map_outlined, 'Required', suggestions: _billingStateSuggestions, onSuggest: (v) => setState(() => _billingStateSuggestions = v), focusNode: _billingStateFocus),
            const SizedBox(height: 32),
            SwitchListTile(
              title: Text('Different Shipping Address?', style: AppTypography.h3),
              value: _hasDifferentShipping,
              onChanged: (v) => setState(() => _hasDifferentShipping = v),
              activeThumbColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
            if (_hasDifferentShipping) ...[
              const SizedBox(height: 16),
              _buildStepHeader('Shipping Address', 'Delivery location'),
              const SizedBox(height: 16),
              _buildField('Business Name', _shippingBusinessController, Icons.business_outlined, null, textCapitalization: TextCapitalization.words),
              const SizedBox(height: 16),
              _buildField('Street Address', _shippingAddressController, Icons.local_shipping_outlined, null, maxLines: 2, textCapitalization: TextCapitalization.words),
              const SizedBox(height: 16),
              _buildField('Landmark', _shippingLandmarkController, Icons.near_me_outlined, null, textCapitalization: TextCapitalization.words),
              const SizedBox(height: 16),
              _buildPincodeField('Pincode', _shippingPincodeController, Icons.pin_drop_outlined, null,
                  isFetching: _isFetchingShippingPincode,
                  onSearch: () {
                    setState(() => _isFetchingShippingPincode = true);
                    _fetchPincodeDetails(_shippingPincodeController, _shippingCityController, _shippingDistrictController, _shippingStateController).then((_) {
                      if (mounted) setState(() => _isFetchingShippingPincode = false);
                    });
                  }),
              const SizedBox(height: 16),
              _buildField('City', _shippingCityController, Icons.apartment_outlined, null, textCapitalization: TextCapitalization.words),
              const SizedBox(height: 16),
              _buildField('District', _shippingDistrictController, Icons.map_outlined, null, textCapitalization: TextCapitalization.words),
              const SizedBox(height: 16),
              _buildStateField('State', _shippingStateController, Icons.map_outlined, null, suggestions: _shippingStateSuggestions, onSuggest: (v) => setState(() => _shippingStateSuggestions = v), focusNode: _shippingStateFocus),
            ],
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader('Bank Details', 'Bank account information'),
            const SizedBox(height: 24),
            _buildField('Account Number', _bankAcController, Icons.format_list_numbered_rtl_outlined, null),
            const SizedBox(height: 16),
            _buildField('IFSC Code', _bankIfscController, Icons.code_rounded, null, formatters: [
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
            if (_bankBranch.isNotEmpty) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  '${_bankNameController.text}, ${_toProperCase(_bankBranch)}, ${_toProperCase(_bankCity)}',
                  style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textSecondary),
                ),
              ),
            ],
            const SizedBox(height: 16),
            _buildField('Bank Name', _bankNameController, Icons.account_balance_outlined, null),
            const SizedBox(height: 32),
            Container(height: 1, color: AppColors.border),
            const SizedBox(height: 24),
            _buildStepHeader('GST Information', 'Tax compliance details (auto-filled)'),
            const SizedBox(height: 24),
            TextFormField(
              controller: _gstController,
              readOnly: true,
              style: AppTypography.input.copyWith(color: AppColors.textSecondary),
              decoration: InputDecoration(
                labelText: 'GST No',
                labelStyle: AppTypography.bodySmall,
                prefixIcon: const Icon(Icons.receipt_outlined, size: 18, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _panController,
              readOnly: true,
              style: AppTypography.input.copyWith(color: AppColors.textSecondary),
              decoration: InputDecoration(
                labelText: 'PAN No',
                labelStyle: AppTypography.bodySmall,
                prefixIcon: const Icon(Icons.credit_card_outlined, size: 18, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
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
                      Text(_gstFilingType.isNotEmpty ? _gstFilingType : '—', style: AppTypography.bodyMedium),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
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
                      Text(_stateCode.isNotEmpty ? _stateCode : '—', style: AppTypography.bodyMedium),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.work_outline, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nature of Business', style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textMuted)),
                        const SizedBox(height: 2),
                        Text(_natureOfBusiness.isNotEmpty ? _natureOfBusiness : '—', style: AppTypography.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
                      Text(
                        _gstRegistrationDate != null
                            ? DateFormat('dd MMM yyyy').format(_gstRegistrationDate!)
                            : '—',
                        style: AppTypography.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: _CompactButton(
                text: 'BACK',
                onPressed: _currentStep > 0 ? () => setState(() => _currentStep--) : null,
                color: AppColors.textMuted,
                isOutline: true,
              ),
            ),
            const SizedBox(width: 96),
            Expanded(
              child: _CompactButton(
                text: _currentStep == 2 ? (widget.isEditing ? 'SAVE' : 'FINISH') : 'CONTINUE',
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    if (_currentStep < 2) {
                      _handleSaveData(isFinal: false, advanceStep: true);
                    } else if (widget.isEditing) {
                      _handleSaveData(isFinal: true);
                    } else {
                      final chosenStatus = await _showFinishConfirmDialog();
                      if (chosenStatus != null && mounted) {
                        _handleSaveData(isFinal: true, status: chosenStatus);
                      }
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

  Widget _buildStateField(String label, TextEditingController controller, IconData icon, String? errorMsg,
      {required List<String> suggestions, required void Function(List<String>) onSuggest, required FocusNode focusNode}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          textCapitalization: TextCapitalization.words,
          style: AppTypography.input,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: AppTypography.bodySmall,
            prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      controller.clear();
                      onSuggest([]);
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
              onSuggest([]);
            } else {
              final input = v.toLowerCase();
              onSuggest(_indianStates.where((s) => s.toLowerCase().contains(input)).toList());
            }
          },
        ),
        if (suggestions.isNotEmpty)
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
              itemCount: suggestions.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 16),
              itemBuilder: (_, i) {
                final option = suggestions[i];
                return ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: Text(option, style: AppTypography.bodyMedium.copyWith(fontSize: 13)),
                  onTap: () {
                    controller.text = option;
                    controller.selection = TextSelection.collapsed(offset: option.length);
                    onSuggest([]);
                    focusNode.unfocus();
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, String? errorMsg, {TextInputType keyboardType = TextInputType.text, int maxLines = 1, List<TextInputFormatter>? formatters, Widget? suffix, TextCapitalization textCapitalization = TextCapitalization.none}) {
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

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final picked = await AppPickers.showScrollableDatePicker(
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
            const Icon(Icons.expand_more_rounded, size: 20, color: AppColors.textMuted),
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
        children: List.generate(3, (index) {
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
                if (index < 2) Expanded(child: Container(height: 1.5, margin: const EdgeInsets.symmetric(horizontal: 4), color: isActive ? AppColors.primary : Colors.grey.shade300)),
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
    _billingBusinessController.dispose();
    _billingLandmarkController.dispose();
    _billingCityController.dispose();
    _billingDistrictController.dispose();
    _billingStateController.dispose();
    _billingPincodeController.dispose();
    _shippingBusinessController.dispose();
    _shippingAddressController.dispose();
    _shippingLandmarkController.dispose();
    _shippingCityController.dispose();
    _shippingDistrictController.dispose();
    _shippingStateController.dispose();
    _shippingPincodeController.dispose();
    _billingStateFocus.dispose();
    _shippingStateFocus.dispose();
    _gstController.removeListener(_onGstChanged);
    _panController.removeListener(_onPanChanged);
    _gstBillingController.dispose();
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
  final VoidCallback? onPressed;
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
              onPressed: (isLoading || onPressed == null) ? null : onPressed,
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
              onPressed: (isLoading || onPressed == null) ? null : onPressed,
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
