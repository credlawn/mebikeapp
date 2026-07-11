import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/partner_model.dart';
import '../../providers/partner_provider.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/app_snackbars.dart';
import 'add_partner_screen.dart';
import 'partner_detail_screen.dart';

class PartnerListScreen extends ConsumerStatefulWidget {
  const PartnerListScreen({super.key});

  @override
  ConsumerState<PartnerListScreen> createState() => _PartnerListScreenState();
}

class _PartnerListScreenState extends ConsumerState<PartnerListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabColors = [
    AppColors.primary,
    AppColors.error,
    AppColors.warning,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tabController.addListener(() {
        if (!_tabController.indexIsChanging && mounted) setState(() {});
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh(WidgetRef ref, BuildContext context) async {
    try {
      await ref
          .refresh(allPartnersProvider.future)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw 'Sync timeout. Check your connection.',
          );
      if (context.mounted) {
        AppSnackBars.showSuccess(context, 'Partners list updated');
      }
    } catch (e) {
      if (context.mounted) AppSnackBars.showError(context, e.toString());
    }
  }


  @override
  Widget build(BuildContext context) {
    final activePartners = ref.watch(activePartnersProvider);
    final inactivePartners = ref.watch(inactivePartnersProvider);
    final draftPartners = ref.watch(draftPartnersProvider);
    final partnersAsync = ref.watch(allPartnersProvider);
    final tabColor = _tabColors[_tabController.index];

    return Scaffold(
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
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.primary,
            ),
            tooltip: 'Add Partner',
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: tabColor,
          labelColor: tabColor,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: AppTypography.h3,
          tabs: [
            Tab(text: 'Active (${activePartners.length})'),
            Tab(text: 'Inactive (${inactivePartners.length})'),
            Tab(text: 'Drafts (${draftPartners.length})'),
          ],
        ),
      ),
      body: partnersAsync.when(
          data: (_) => IndexedStack(
            index: _tabController.index,
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
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.8),
          child: partners.isEmpty
              ? SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isDraft
                              ? Icons.edit_note_rounded
                              : (isActive
                                    ? Icons.people_outline_rounded
                                    : Icons.person_off_outlined),
                          size: 64,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No ${isDraft ? 'draft' : (isActive ? 'active' : 'inactive')} partners found.',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Pull to refresh', style: AppTypography.bodySmall),
                      ],
                    ),
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: partners.asMap().entries.map((entry) {
                      final index = entry.key;
                      final partner = entry.value;
                      return Column(
                        children: [
                          if (index > 0) const Divider(height: 1, color: AppColors.border),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                if (isDraft) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => AddPartnerScreen(draftId: partner.id),
                                    ),
                                  );
                                } else {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => PartnerDetailScreen(partnerId: partner.id),
                                    ),
                                  );
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 28,
                                      child: Text(
                                        '${index + 1}.',
                                        style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                                      ),
                                    ),
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
                                                  partner.partnerCode,
                                                  style: AppTypography.bodySmall.copyWith(
                                                    color: AppColors.primary,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                )
                                              else
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.orange.shade100,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Text(
                                                    'DRAFT',
                                                    style: TextStyle(
                                                      color: Colors.orange,
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(
                                                _toTitleCase(partner.partnerType),
                                                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                              ),
                                              const SizedBox(width: 8),
                                              Text('|', style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  '${partner.billingDistrict.isNotEmpty ? _toTitleCase(partner.billingDistrict) : '—'}, ${partner.billingState.isNotEmpty ? partner.billingState : '—'}',
                                                  style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
        ),
      ),
    );
  }
}

String _toTitleCase(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1).toLowerCase();
}


