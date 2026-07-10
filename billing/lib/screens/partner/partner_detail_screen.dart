import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/partner_model.dart';
import '../../pb_service.dart';
import '../../providers/partner_provider.dart';
import '../../theme/app_snackbars.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import 'add_partner_screen.dart';

class PartnerDetailScreen extends ConsumerStatefulWidget {
  final String partnerId;

  const PartnerDetailScreen({super.key, required this.partnerId});

  @override
  ConsumerState<PartnerDetailScreen> createState() => _PartnerDetailScreenState();
}

class _PartnerDetailScreenState extends ConsumerState<PartnerDetailScreen> {
  Partner? _partner;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPartner();
  }

  Future<void> _loadPartner() async {
    setState(() => _isLoading = true);
    try {
      final record = await PbService().pb.collection('partner').getOne(widget.partnerId).timeout(const Duration(seconds: 15));
      _partner = Partner.fromJson(record.toJson());
    } catch (_) {
      if (mounted) AppSnackBars.showError(context, 'Cannot reach server');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleStatus() async {
    if (_partner == null) return;

    final newStatus = _partner!.partnerStatus == 'active' ? 'inactive' : 'active';
    final isMakingActive = newStatus == 'active';

    final confirmed = await _showStatusConfirmDialog(isMakingActive);
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await PbService().pb.collection('partner').update(
        widget.partnerId,
        body: {'partner_status': newStatus},
      ).timeout(const Duration(seconds: 15));

      if (mounted) {
        AppSnackBars.showSuccess(context, isMakingActive ? 'Partner activated' : 'Partner deactivated');
        Navigator.of(context).pop();
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => ref.invalidate(allPartnersProvider));
    } catch (_) {
      if (mounted) AppSnackBars.showError(context, 'Cannot reach server');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool?> _showStatusConfirmDialog(bool isMakingActive) {
    final icon = isMakingActive ? Icons.check_circle_outline : Icons.block_outlined;
    final title = isMakingActive ? 'Activate Partner?' : 'Deactivate Partner?';
    final message = isMakingActive
        ? 'This partner will become active and appear in the Active partners list.'
        : 'This partner will be moved to the Inactive list. They can be reactivated later.';
    final buttonText = isMakingActive ? 'Activate' : 'Deactivate';
    final buttonColor = isMakingActive ? AppColors.primary : AppColors.error;

    return showDialog<bool>(
      context: context,
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
                color: buttonColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: buttonColor, size: 28),
            ),
            const SizedBox(height: 20),
            Text(title, style: AppTypography.h2.copyWith(fontSize: 18)),
            const SizedBox(height: 12),
            Text(
              message,
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
                  onPressed: () => Navigator.of(ctx).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Cancel', style: AppTypography.button.copyWith(color: AppColors.primary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(buttonText, style: AppTypography.button.copyWith(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_partner?.partnerName ?? 'Partner Details'),
        elevation: 0,
        actions: [
          if (_partner != null)
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => AddPartnerScreen(draftId: widget.partnerId, isEditing: true)),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.textMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Edit',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_partner != null)
            GestureDetector(
              onTap: _isLoading ? null : _toggleStatus,
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _partner!.partnerStatus == 'active'
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _partner!.partnerStatus == 'active' ? AppColors.success : AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _partner!.partnerStatus == 'active' ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _partner!.partnerStatus == 'active' ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _partner == null
              ? const Center(child: Text('Partner not found'))
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildSection('Business Profile', [
                              _buildRow('Entity Type', _toTitleCase(_partner!.entityType)),
                              _buildRow('Partner Type', _toTitleCase(_partner!.partnerType)),
                              _buildRow('Partner Code', _partner!.partnerCode),
                              _buildRow('Partner Name', _partner!.partnerName),
                              _buildRow('Email', _partner!.email),
                              if (_partner!.onboardingDate != null)
                                _buildRow('Onboarding Date', DateFormat('dd MMM yyyy').format(_partner!.onboardingDate!)),
                            ]),
                            const SizedBox(height: 12),
                            _buildSection('Contact Details', [
                              _buildRow('Key Person', _partner!.keyPersonName),
                              _buildRow('Mobile', _partner!.mobileNo),
                            ]),
                            const SizedBox(height: 12),
                            _buildSection('Billing Address', [
                              _buildRow('Address', _partner!.billingAddress),
                              if (_partner!.billingLandmark.isNotEmpty) _buildRow('Landmark', _partner!.billingLandmark),
                              _buildRow('City', _partner!.billingCity),
                              if (_partner!.billingDistrict.isNotEmpty) _buildRow('District', _partner!.billingDistrict),
                              _buildRow('State', _partner!.billingState),
                              _buildRow('Pincode', _partner!.billingPincode),
                            ]),
                            if (_partner!.hasDifferentShippingAddress) ...[
                              const SizedBox(height: 12),
                              _buildSection('Shipping Address', [
                                if (_partner!.shippingBusinessName.isNotEmpty) _buildRow('Business Name', _partner!.shippingBusinessName),
                                _buildRow('Address', _partner!.shippingAddress),
                                if (_partner!.shippingLandmark.isNotEmpty) _buildRow('Landmark', _partner!.shippingLandmark),
                                _buildRow('City', _partner!.shippingCity),
                                if (_partner!.shippingDistrict.isNotEmpty) _buildRow('District', _partner!.shippingDistrict),
                                _buildRow('State', _partner!.shippingState),
                                _buildRow('Pincode', _partner!.shippingPincode),
                              ]),
                            ],
                            const SizedBox(height: 12),
                            _buildSection('Finance & Banking', [
                              if (_partner!.gstFilingFrequency.isNotEmpty) _buildRow('GST Filing', _toTitleCase(_partner!.gstFilingFrequency)),
                              if (_partner!.gstNo.isNotEmpty) _buildRow('GST No', _partner!.gstNo),
                              if (_partner!.panNo.isNotEmpty) _buildRow('PAN No', _partner!.panNo),
                              if (_partner!.bankAcType.isNotEmpty) _buildRow('Account Type', _toTitleCase(_partner!.bankAcType)),
                              if (_partner!.bankAcNo.isNotEmpty) _buildRow('Account No', _partner!.bankAcNo),
                              if (_partner!.bankIfscCode.isNotEmpty) _buildRow('IFSC Code', _partner!.bankIfscCode),
                              if (_partner!.bankName.isNotEmpty) _buildRow('Bank Name', _partner!.bankName),
                              _buildBranchRow(_partner!.bankBranch, _partner!.bankCity),
                            ]),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSection(String title, List<Widget> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.h3.copyWith(color: AppColors.primary, fontSize: 13)),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '—',
              style: AppTypography.bodyMedium.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchRow(String branch, String city) {
    final parts = <String>[];
    if (branch.isNotEmpty) parts.add(branch);
    if (city.isNotEmpty) parts.add(city);
    return parts.isEmpty ? const SizedBox.shrink() : _buildRow('Branch', parts.join(', '));
  }

  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}
