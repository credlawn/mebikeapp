import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/partner_model.dart';
import '../../providers/partner_provider.dart';
import '../../theme/colors.dart';
import '../../theme/app_snackbars.dart';
import 'billing_screen.dart';

class PartnerSearchScreen extends ConsumerStatefulWidget {
  const PartnerSearchScreen({super.key});

  @override
  ConsumerState<PartnerSearchScreen> createState() => _PartnerSearchScreenState();
}

class _PartnerSearchScreenState extends ConsumerState<PartnerSearchScreen> {
  final _searchCtrl = TextEditingController();
  List<Partner> _allPartners = [];
  List<Partner> _filtered = [];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = [];
      } else {
        _filtered = _allPartners.where((p) =>
          p.partnerName.toLowerCase().contains(q) ||
          p.partnerCode.toLowerCase().contains(q) ||
          p.mobileNo.contains(q)
        ).toList();
      }
    });
  }

  void _selectPartner(Partner p) {
    if (p.partnerStatus == 'inactive') {
      AppSnackBars.showError(context, "Can't Bill. Dealer is Inactive");
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => BillingScreen(
          invoiceType: 'partner',
          partner: p,
        ),
      ),
    );
  }

  Widget _buildPartnerCard(Partner p, int index) {
    final addressParts = p.billingAddress;
    final isActive = p.partnerStatus == 'active';
    final statusColor = isActive ? AppColors.success : AppColors.error;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => _selectPartner(p),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            p.partnerName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (p.partnerCode.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            p.partnerCode,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (addressParts.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        addressParts,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final partnersAsync = ref.watch(allPartnersProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Select Dealer'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
              decoration: InputDecoration(
                hintText: 'Search by name or code...',
                hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.5)),
                prefixIcon: Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted.withValues(alpha: 0.5)),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              ),
            ),
          ),
          Expanded(
            child: partnersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const SizedBox(),
              data: (partners) {
                _allPartners = partners;
                if (_searchCtrl.text.isEmpty) {
                  final recent = List<Partner>.from(_allPartners)
                    ..sort((a, b) => b.updated.compareTo(a.updated));
                  final active = recent.where((p) => p.partnerStatus == 'active').toList();
                  final display = active.take(10).toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
                        child: Text(
                          'Recent dealers',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted.withValues(alpha: 0.8),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 4, bottom: 16),
                          itemCount: display.length,
                          itemBuilder: (_, i) => _buildPartnerCard(display[i], i),
                        ),
                      ),
                    ],
                  );
                }
                if (_filtered.isEmpty) {
                  return Center(
                    child: Text('No dealers found', style: TextStyle(color: AppColors.textMuted)),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) => _buildPartnerCard(_filtered[i], i),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
