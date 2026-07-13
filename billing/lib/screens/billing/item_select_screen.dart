import 'package:flutter/material.dart';
import '../../pb_service.dart';
import '../../theme/colors.dart';

class ItemSelectScreen extends StatefulWidget {
  final String itemType;
  const ItemSelectScreen({super.key, required this.itemType});

  @override
  State<ItemSelectScreen> createState() => _ItemSelectScreenState();
}

class _ItemSelectScreenState extends State<ItemSelectScreen> {
  final _searchCtrl = TextEditingController();
  List<dynamic> _allRecords = [];
  List<dynamic> _filtered = [];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _loadItems();
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    try {
      final records = await PbService().pb.collection(widget.itemType).getFullList(
        filter: 'status = "active"',
        sort: 'name',
      );
      if (mounted) {
        setState(() => _allRecords = records);
      }
    } catch (_) {}
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = [];
      } else {
        _filtered = _allRecords.where((r) {
          final name = r.getStringValue('full_name').isNotEmpty
              ? r.getStringValue('full_name')
              : r.getStringValue('name');
          return name.toLowerCase().contains(q);
        }).toList();
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    final label = widget.itemType[0].toUpperCase() + widget.itemType.substring(1);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Select $label'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search $label...',
                prefixIcon: Icon(Icons.search_rounded, size: 20, color: Colors.grey),
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
            child: _allRecords.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : (_searchCtrl.text.isNotEmpty && _filtered.isEmpty
                    ? Center(child: Text('No $label found', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _searchCtrl.text.isEmpty ? _allRecords.length : _filtered.length,
                        itemBuilder: (_, i) {
                          final r = _searchCtrl.text.isEmpty ? _allRecords[i] : _filtered[i];
                          final name = r.getStringValue('full_name').isNotEmpty
                              ? r.getStringValue('full_name')
                              : r.getStringValue('name');
                          final code = r.getStringValue('item_code');
                          final price = r.getDoubleValue('selling_price');
                          final hsn = r.getStringValue('hsn_code');
                          final gstSlab = r.getDoubleValue('gst_slab').toInt();

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: InkWell(
                              onTap: () => Navigator.of(context).pop(r),
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
                                        color: const Color(0xFF059669).withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${i + 1}',
                                          style: TextStyle(
                                            color: const Color(0xFF059669),
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
                                          Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              if (code.isNotEmpty)
                                                Text(code, style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                              if (code.isNotEmpty) const SizedBox(width: 12),
                                              Text('\u20B9 ${price.toStringAsFixed(2)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                                            ],
                                          ),
                                          if (hsn.isNotEmpty || gstSlab > 0) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              '${hsn.isNotEmpty ? "HSN: $hsn" : ""}${hsn.isNotEmpty && gstSlab > 0 ? " • " : ""}${gstSlab > 0 ? "GST: $gstSlab%" : ""}',
                                              style: TextStyle(fontSize: 10, color: AppColors.textMuted.withValues(alpha: 0.6)),
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
                        },
                      )),
          ),
        ],
      ),
    );
  }
}
