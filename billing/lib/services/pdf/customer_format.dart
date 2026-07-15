import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../config.dart';
import '../../models/invoice_model.dart';
import '../../models/company_model.dart';
import 'theme.dart';

class CustomerInvoiceFormat {
  static Future<Uint8List> generate(Invoice inv, Company company) async {
    await PdfTheme.loadFonts();

    Uint8List? logoBytes;
    if (company.logo.isNotEmpty) {
      try {
        final url = '${AppConfig.pocketbaseUrl}/api/files/${company.collectionId}/${company.id}/${company.logo}';
        final resp = await http.get(Uri.parse(url));
        if (resp.statusCode == 200) logoBytes = resp.bodyBytes;
      } catch (_) {}
    }

    final itemsBySlab = <int, List<InvoiceItem>>{};
    for (final item in inv.items) {
      itemsBySlab.putIfAbsent(item.gstSlab, () => []).add(item);
    }
    final sortedSlabs = itemsBySlab.keys.toList()..sort();

    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        header: (ctx) => pw.SizedBox(height: 24),
        build: (ctx) => [
          // Pre-table section
          pw.Container(
            margin: const pw.EdgeInsets.only(left: 36, right: 36, top: 24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _header(inv, company, logoBytes),
                _metaSection(inv, company),
                _addressSection(inv),
                PdfHelpers.sp(20),
              ],
            ),
          ),
          // Items table — direct child of MultiPage so it can span pages
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 36),
            child: _itemsTable(inv),
          ),
          // Post-table section
          pw.Container(
            margin: const pw.EdgeInsets.only(left: 36, right: 36, bottom: 24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                PdfHelpers.sp(16),
                _totalsSection(inv, sortedSlabs, itemsBySlab),
                PdfHelpers.sp(12),
                _amountInWords(inv),
                PdfHelpers.sp(16),
                _taxSummary(sortedSlabs, itemsBySlab, inv),
                PdfHelpers.sp(40),
                _signatureSection(),
                PdfHelpers.sp(20),
                _footer(inv),
              ],
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _header(Invoice inv, Company c, Uint8List? logoBytes) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(0, 12, 12, 12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border(bottom: pw.BorderSide(color: PdfTheme.primary, width: 2.5)),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logoBytes != null) pw.SizedBox(width: 60),
              pw.Expanded(
                child: pw.Text(inv.mode == 'quotation' ? 'QUOTATION' : 'TAX INVOICE',
                  textAlign: pw.TextAlign.center,
                  style: PdfTheme.sb(16, color: PdfTheme.primary).copyWith(letterSpacing: 1)),
              ),
              if (logoBytes != null) pw.SizedBox(width: 12),
              if (logoBytes != null)
                pw.Container(
                  width: 48, height: 48,
                  child: pw.Image(pw.MemoryImage(logoBytes), fit: pw.BoxFit.contain),
                ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 3,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    if (c.businessName.isNotEmpty)
                      pw.Text(c.businessName, style: PdfTheme.med(12, color: PdfTheme.dark)),
                    if (c.address.isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 2),
                        child: pw.Text(c.address, style: PdfTheme.reg(8, color: PdfTheme.dark_09)),
                      ),
                    if (c.gstNo.isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 2),
                        child: pw.Text('GSTIN: ${c.gstNo}${c.stateCode.isNotEmpty ? "  |  State Code: ${c.stateCode}" : ""}',
                          style: PdfTheme.reg(8.5, color: PdfTheme.dark)),
                      ),
                  ],
                ),
              ),
              if (c.mobileNo.isNotEmpty)
                pw.Expanded(
                  flex: 2,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Text('Ph: ${c.mobileNo}',
                        style: PdfTheme.reg(7.5, color: PdfTheme.dark_08)),
                      if (c.email.isNotEmpty)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 1),
                          child: pw.Text(c.email,
                            style: PdfTheme.reg(7.5, color: PdfTheme.dark_08)),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _metaSection(Invoice inv, Company company) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 18),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              children: [
                _metaField('Invoice No', inv.invoiceNo.isNotEmpty ? inv.invoiceNo : '-'),
                _metaField('Date', PdfHelpers.fmtDate(inv.invoiceDate)),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              children: [
                if (inv.invoiceType != 'partner')
                  _metaField('Customer ID', inv.partyCustomerCode.isNotEmpty ? inv.partyCustomerCode : (inv.partyGst.isNotEmpty ? inv.partyGst : '-')),
                if (inv.partyPartnerCode.isNotEmpty)
                  _metaField('Dealer Code', inv.partyPartnerCode),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _addressSection(Invoice inv) {
    String extra = inv.partyStateCode.isNotEmpty ? 'State Code: ${inv.partyStateCode}' : '';
    if (inv.partyGst.isEmpty && inv.partyMobile.isNotEmpty) {
      if (extra.isNotEmpty) extra += '\n';
      extra += 'Mobile: ${inv.partyMobile}';
    }
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 16),
      child: _addressBox(inv.mode == 'quotation' ? 'Quotation for' : 'Billed to', inv.partyName, inv.partyAddress, inv.partyGst, extra),
    );
  }

  static pw.Widget _addressBox(String title, String name, String? addr, String? gst, String extra) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfTheme.border),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        color: PdfTheme.headerBg,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: PdfTheme.med(12, color: PdfTheme.primary)),
          pw.Container(height: 1, margin: const pw.EdgeInsets.symmetric(vertical: 6), color: PdfTheme.border),
          pw.Text(name, style: PdfTheme.sb(10.5, color: PdfTheme.dark)),
          if (addr != null && addr.isNotEmpty) ...[
            PdfHelpers.sp(2),
            pw.Text(addr, style: PdfTheme.reg(9, color: PdfTheme.dark_08)),
          ],
          if (gst != null && gst.isNotEmpty) ...[
            PdfHelpers.sp(4),
            pw.Text('GSTIN: $gst', style: PdfTheme.med(9, color: PdfTheme.dark)),
          ],
          if (extra.isNotEmpty) ...[
            PdfHelpers.sp(2),
            pw.Text(extra, style: PdfTheme.reg(9, color: PdfTheme.dark_08)),
          ],
        ],
      ),
    );
  }

  static pw.Widget _itemsTable(Invoice inv) {
    final hStyle = PdfTheme.med(8.5, color: PdfTheme.dark);
    final cStyle = PdfTheme.reg(8.5, color: PdfTheme.dark);
    final cBold = PdfTheme.med(8.5, color: PdfTheme.dark);
    final headers = ['S.No', 'Description of Goods', 'HSN/SAC', 'Qty', 'Unit', 'Rate (\u20B9)', 'Amount (\u20B9)'];
    final colW = [0.4, 2.8, 0.8, 0.4, 0.5, 0.8, 1.0];

    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfTheme.border)),
      child: pw.Table(
        border: pw.TableBorder(
          horizontalInside: pw.BorderSide(color: PdfTheme.border, width: 0.5),
          verticalInside: pw.BorderSide(color: PdfTheme.border, width: 0.5),
        ),
        columnWidths: Map.fromIterables(
          List.generate(headers.length, (i) => i),
          colW.map((w) => pw.FlexColumnWidth(w)),
        ),
        children: [
          pw.TableRow(
            repeat: true,
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [PdfTheme.headerBg, PdfColor.fromInt(0xFFEEF2F6)],
                begin: pw.Alignment.topCenter, end: pw.Alignment.bottomCenter,
              ),
            ),
            children: headers.map((h) => PdfHelpers.headCell(h, hStyle)).toList(),
          ),
          ...inv.items.asMap().entries.map((e) {
            final i = e.value;
            final idx = e.key + 1;
            return pw.TableRow(
              decoration: idx % 2 == 0 ? pw.BoxDecoration(color: PdfTheme.evenRow) : null,
              children: [
                PdfHelpers.cell('$idx', cStyle, pw.TextAlign.center),
                PdfHelpers.cell(i.itemName, cStyle, pw.TextAlign.left, maxLines: 2),
                PdfHelpers.cell(i.hsnCode, cStyle, pw.TextAlign.center),
                PdfHelpers.cell(i.quantity.toInt().toString(), cStyle, pw.TextAlign.center),
                PdfHelpers.cell('Nos', cStyle, pw.TextAlign.center),
                PdfHelpers.cell(PdfHelpers.fmt(i.taxableValue / i.quantity), cStyle, pw.TextAlign.right),
                PdfHelpers.cell(PdfHelpers.fmt(i.taxableValue), cBold, pw.TextAlign.right),
              ],
            );
          }),
        ],
      ),
    );
  }

  static pw.Widget _totalsSection(Invoice inv, List<int> slabs, Map<int, List<InvoiceItem>> bySlab) {
    final cStyle = PdfTheme.reg(9.5, color: PdfTheme.dark);
    final cB = PdfTheme.med(9.5, color: PdfTheme.dark);
    final gStyle = PdfTheme.sb(14, color: PdfTheme.primary);
    final totalTaxable = inv.taxable;
    final totalGst = inv.cgstTotal + inv.sgstTotal + inv.igstTotal;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfTheme.totalBg, border: pw.Border.all(color: PdfTheme.border),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        children: [
          _totalRow('Totals c/o', PdfHelpers.fmt(inv.subtotal), cStyle),
          if (inv.discount > 0) _totalRow('Less: Discount', PdfHelpers.fmt(inv.discount), cStyle),
          _dashLine(),
          _totalRow('Sub Total', PdfHelpers.fmt(totalTaxable), cB),
          _totalRow('Add: GST', PdfHelpers.fmt(totalGst), cStyle),
          _dashLine(),
          _totalRow('Grand Total', PdfHelpers.fmt(inv.grandTotal), gStyle),
        ],
      ),
    );
  }

  static pw.Widget _totalRow(String label, String value, pw.TextStyle style) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [pw.Text(label, style: style), pw.Text('\u20B9 $value', style: style)],
      ),
    );
  }

  static pw.Widget _dashLine() {
    return pw.Container(margin: const pw.EdgeInsets.symmetric(vertical: 4), height: 0.5, color: PdfTheme.border);
  }

  static pw.Widget _taxSummary(List<int> slabs, Map<int, List<InvoiceItem>> bySlab, Invoice inv) {
    final hStyle = PdfTheme.med(8.5, color: PdfTheme.dark);
    final cStyle = PdfTheme.reg(8.5, color: PdfTheme.dark);
    final cB = PdfTheme.med(8.5, color: PdfTheme.dark);
    final isInter = inv.igstTotal > 0;
    final headers = ['Tax Rate', 'Taxable Amount (\u20B9)', isInter ? 'IGST (\u20B9)' : 'CGST (\u20B9)', isInter ? '' : 'SGST (\u20B9)', 'Total Tax (\u20B9)']
        .where((h) => h.isNotEmpty).toList();
    final colW = [1.0, 1.2, isInter ? 1.0 : 1.0, isInter ? 0.0 : 1.0, 1.0].where((w) => w > 0).toList();

    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfTheme.border)),
      child: pw.Table(
        border: pw.TableBorder(
          horizontalInside: pw.BorderSide(color: PdfTheme.border, width: 0.5),
          verticalInside: pw.BorderSide(color: PdfTheme.border, width: 0.5),
        ),
        columnWidths: Map.fromIterables(
          List.generate(colW.length, (i) => i),
          colW.map((w) => pw.FlexColumnWidth(w)),
        ),
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [PdfTheme.headerBg, PdfColor.fromInt(0xFFEEF2F6)],
                begin: pw.Alignment.topCenter, end: pw.Alignment.bottomCenter,
              ),
            ),
            children: headers.map((h) => PdfHelpers.headCell(h, hStyle)).toList(),
          ),
          ...slabs.map((slab) {
            final items = bySlab[slab]!;
            final taxable = items.fold(0.0, (s, i) => s + i.taxableValue);
            final cgst = items.fold(0.0, (s, i) => s + i.cgstAmount);
            final sgst = items.fold(0.0, (s, i) => s + i.sgstAmount);
            final igst = items.fold(0.0, (s, i) => s + i.igstAmount);
            final totalTax = cgst + sgst + igst;
            final cells = <pw.Widget>[
              PdfHelpers.cell('GST @ $slab%', cStyle, pw.TextAlign.center),
              PdfHelpers.cell(PdfHelpers.fmt(taxable), cStyle, pw.TextAlign.center),
            ];
            if (isInter) {
              cells.add(PdfHelpers.cell(PdfHelpers.fmt(igst), cStyle, pw.TextAlign.center));
            } else {
              cells.addAll([
                PdfHelpers.cell(PdfHelpers.fmt(cgst), cStyle, pw.TextAlign.center),
                PdfHelpers.cell(PdfHelpers.fmt(sgst), cStyle, pw.TextAlign.center),
              ]);
            }
            cells.add(PdfHelpers.cell(PdfHelpers.fmt(totalTax), cB, pw.TextAlign.center));
            return pw.TableRow(children: cells);
          }),
        ],
      ),
    );
  }

  static pw.Widget _amountInWords(Invoice inv) {
    return pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(text: 'Amount in words: ', style: PdfTheme.med(10, color: PdfTheme.dark).copyWith(fontStyle: pw.FontStyle.italic)),
          pw.TextSpan(text: PdfHelpers.toWords(inv.grandTotal), style: PdfTheme.reg(10, color: PdfTheme.dark).copyWith(fontStyle: pw.FontStyle.italic)),
        ],
      ),
    );
  }

  static pw.Widget _signatureSection() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(width: 160, height: 1, color: PdfTheme.dark),
            PdfHelpers.sp(6),
            pw.Text('Authorised Signatory', style: PdfTheme.reg(9, color: PdfTheme.dark_07)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _metaField(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Text('$label: ', style: PdfTheme.reg(9, color: PdfTheme.dark_07)),
          pw.Text(value, style: PdfTheme.med(9.5, color: PdfTheme.dark)),
        ],
      ),
    );
  }

  static pw.Widget _footer(Invoice inv) {
    return pw.Center(
      child: pw.Text(
        inv.mode == 'quotation' ? 'This is a System generated quotation from mebikeindia.' : 'This is System generated slip from mebikeindia. No need of signature.',
        style: PdfTheme.reg(7.5, color: PdfTheme.dark_05)),
    );
  }
}
