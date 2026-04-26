import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/partner_model.dart';
import '../../providers/partner_provider.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import 'add_partner_screen.dart';

class PartnerListScreen extends ConsumerWidget {
  const PartnerListScreen({super.key});

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
              _PartnerList(partners: activePartners, isActive: true),
              _PartnerList(partners: inactivePartners, isActive: false),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddPartnerScreen()),
            );
          },
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add_rounded, color: Colors.white),
        ),
      ),
    );
  }
}

class _PartnerList extends StatelessWidget {
  final List<Partner> partners;
  final bool isActive;

  const _PartnerList({required this.partners, required this.isActive});

  @override
  Widget build(BuildContext context) {
    if (partners.isEmpty) {
      return Center(
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
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: partners.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final partner = partners[index];
        return _PartnerTile(partner: partner);
      },
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
                      partner.partnerName.substring(0, 1).toUpperCase(),
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
