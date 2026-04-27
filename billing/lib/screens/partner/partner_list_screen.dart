import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/partner_model.dart';
import '../../providers/partner_provider.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/app_snackbars.dart';
import 'add_partner_screen.dart';

class PartnerListScreen extends ConsumerWidget {
  const PartnerListScreen({super.key});

  Future<void> _handleRefresh(WidgetRef ref, BuildContext context) async {
    try {
      await ref.refresh(allPartnersProvider.future).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw 'Sync timeout. Check your connection.',
      );
      if (context.mounted) AppSnackBars.showSuccess(context, 'Partners list updated');
    } catch (e) {
      if (context.mounted) AppSnackBars.showError(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePartners = ref.watch(activePartnersProvider);
    final inactivePartners = ref.watch(inactivePartnersProvider);
    final partnersAsync = ref.watch(allPartnersProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Our Partners'),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddPartnerScreen()),
                );
              },
              icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
              tooltip: 'Add Partner',
            ),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: AppTypography.h3,
            tabs: [
              Tab(text: 'Active (${activePartners.length})'),
              Tab(text: 'Inactive (${inactivePartners.length})'),
            ],
          ),
        ),
        body: partnersAsync.when(
          data: (_) => TabBarView(
            children: [
              _PartnerList(
                partners: activePartners, 
                isActive: true, 
                onRefresh: () => _handleRefresh(ref, context),
              ),
              _PartnerList(
                partners: inactivePartners, 
                isActive: false, 
                onRefresh: () => _handleRefresh(ref, context),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => RefreshIndicator(
            onRefresh: () => _handleRefresh(ref, context),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Center(child: Text('Error: $err\nPull to retry')),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PartnerList extends StatelessWidget {
  final List<Partner> partners;
  final bool isActive;
  final RefreshCallback onRefresh;

  const _PartnerList({
    required this.partners, 
    required this.isActive, 
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      backgroundColor: Colors.white,
      child: partners.isEmpty
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isActive ? Icons.people_outline_rounded : Icons.person_off_outlined,
                        size: 64,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No ${isActive ? 'active' : 'inactive'} partners found.',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 8),
                      Text('Pull to refresh', style: AppTypography.bodySmall),
                    ],
                  ),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: partners.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final partner = partners[index];
                return _PartnerTile(partner: partner);
              },
            ),
    );
  }
}

class _PartnerTile extends StatelessWidget {
  final Partner partner;

  const _PartnerTile({required this.partner});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Future: Partner Details Screen
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Avatar/Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      partner.partnerName.isNotEmpty ? partner.partnerName.substring(0, 1).toUpperCase() : 'P',
                      style: AppTypography.h3.copyWith(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              partner.partnerName,
                              style: AppTypography.h3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '#${partner.partnerCode}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.business_center_outlined, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            partner.partnerType.toUpperCase(),
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            partner.onboardingDate != null 
                                ? dateFormat.format(partner.onboardingDate!)
                                : 'N/A',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
