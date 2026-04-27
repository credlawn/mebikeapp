import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/partner_model.dart';
import '../../providers/partner_provider.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/app_snackbars.dart';
import '../../services/draft_manager.dart';
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
    final draftPartners = ref.watch(draftPartnersProvider);
    final partnersAsync = ref.watch(allPartnersProvider);

    return DefaultTabController(
      length: 3,
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
            isScrollable: true,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: AppTypography.h3,
            tabs: [
              Tab(text: 'Active (${activePartners.length})'),
              Tab(text: 'Inactive (${inactivePartners.length})'),
              Tab(text: 'Drafts (${draftPartners.length})'),
            ],
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () => _handleRefresh(ref, context),
          color: AppColors.primary,
          backgroundColor: Colors.white,
          child: partnersAsync.when(
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
                _PartnerList(
                  partners: draftPartners, 
                  isActive: false, 
                  isDraft: true,
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
      ),
    );
  }
}

class _PartnerList extends StatelessWidget {
  final List<Partner> partners;
  final bool isActive;
  final bool isDraft;
  final RefreshCallback onRefresh;

  const _PartnerList({
    required this.partners, 
    required this.isActive, 
    this.isDraft = false,
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
                        isDraft ? Icons.edit_note_rounded : (isActive ? Icons.people_outline_rounded : Icons.person_off_outlined),
                        size: 64,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No ${isDraft ? 'draft' : (isActive ? 'active' : 'inactive')} partners found.',
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
                return _PartnerTile(partner: partner, isDraft: isDraft);
              },
            ),
    );
  }
}

class _PartnerTile extends StatelessWidget {
  final Partner partner;
  final bool isDraft;

  const _PartnerTile({required this.partner, this.isDraft = false});

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
          onTap: () async {
            if (isDraft) {
              // Pre-load into local cache for instant resume
              await DraftManager.saveLocalDraft(partner.toJson());
              if (context.mounted) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddPartnerScreen()),
                );
              }
            }
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
                    color: isDraft ? Colors.orange.shade50 : AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      partner.partnerName.isNotEmpty ? partner.partnerName.substring(0, 1).toUpperCase() : 'P',
                      style: AppTypography.h3.copyWith(color: isDraft ? Colors.orange : AppColors.primary),
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
                          if (!isDraft)
                            Text(
                              '#${partner.partnerCode}',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(4)),
                              child: const Text('DRAFT', style: TextStyle(color: Colors.orange, fontSize: 9, fontWeight: FontWeight.bold)),
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
