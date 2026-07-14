import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfTheme {
  static pw.Font? regular, medium, semiBold;

  static const PdfColor primary = PdfColor.fromInt(0xFFFF6F61);
  static const PdfColor secondary = PdfColor.fromInt(0xFFD15C4A);
  static const PdfColor accent = PdfColor.fromInt(0xFFFF6584);
  static const PdfColor dark = PdfColor.fromInt(0xFF2D3748);
  static const PdfColor light = PdfColor.fromInt(0xFFF7FAFC);
  static const PdfColor border = PdfColor.fromInt(0xFFE2E8F0);
  static const PdfColor pageBg = PdfColor.fromInt(0xFFF5F7FA);
  static const PdfColor headerBg = PdfColor.fromInt(0xFFF8FAFC);
  static const PdfColor evenRow = PdfColor.fromInt(0xFFF8FAFC);
  static const PdfColor totalBg = PdfColor.fromInt(0xFFF8FAFC);
  // Faded variants (manually computed as blend with white)
  static const PdfColor dark_09 = PdfColor.fromInt(0xFF3A4A5D);
  static const PdfColor dark_08 = PdfColor.fromInt(0xFF4A5A6D);
  static const PdfColor dark_07 = PdfColor.fromInt(0xFF5A6A7D);
  static const PdfColor dark_05 = PdfColor.fromInt(0xFF7A8A9D);
  static const PdfColor primary_015 = PdfColor.fromInt(0xFFFFF0ED);

  static Future<void> loadFonts() async {
    if (regular != null) return;
    regular = pw.Font.ttf(await rootBundle.load('assets/fonts/Poppins-Regular.ttf'));
    medium = pw.Font.ttf(await rootBundle.load('assets/fonts/Poppins-Medium.ttf'));
    semiBold = pw.Font.ttf(await rootBundle.load('assets/fonts/Poppins-SemiBold.ttf'));
  }

  static pw.TextStyle ts(double size, {PdfColor? color, pw.Font? font, pw.FontWeight? weight, bool italic = false, double? letterSpacing}) {
    return pw.TextStyle(
      fontSize: size,
      font: font ?? regular,
      fontWeight: weight,
      color: color,
      fontStyle: italic ? pw.FontStyle.italic : null,
      letterSpacing: letterSpacing,
    );
  }

  static pw.TextStyle reg(double size, {PdfColor? color}) => ts(size, color: color);
  static pw.TextStyle med(double size, {PdfColor? color}) => ts(size, font: medium, color: color);
  static pw.TextStyle sb(double size, {PdfColor? color}) => ts(size, font: semiBold, color: color, weight: pw.FontWeight.bold);
}

class PdfHelpers {
  static pw.Widget sp(double h) => pw.SizedBox(height: h);
  static pw.Widget sw(double w) => pw.SizedBox(width: w);

  static pw.Widget cell(String text, pw.TextStyle style, pw.TextAlign align, {int? maxLines}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: pw.Text(text, style: style, textAlign: align, maxLines: maxLines),
    );
  }

  static pw.Widget headCell(String text, pw.TextStyle style) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: pw.Text(text, style: style, textAlign: pw.TextAlign.center),
    );
  }

  static pw.Widget comboCell(String text, pw.TextStyle style) {
    final idx = text.indexOf('+');
    if (idx >= 0) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(text.substring(0, idx).trim(), style: style, maxLines: 1),
            pw.Text('+ ${text.substring(idx + 1).trim()}', style: style, maxLines: 1),
          ],
        ),
      );
    }
    return cell(text, style, pw.TextAlign.left);
  }

  static String fmt(double v) {
    if (v == 0) return '0.00';
    final s = v.toStringAsFixed(2);
    final parts = s.split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    final buf = StringBuffer();
    int count = 0;
    for (int i = intPart.length - 1; i >= 0; i--) {
      count++;
      buf.write(intPart[i]);
      if (count == 3 && i > 0) { buf.write(','); count = 0; }
      else if (count == 2 && i > 0) { buf.write(','); count = 0; }
    }
    return '${buf.toString().split('').reversed.join()}.$decPart';
  }

  static String fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  static String toWords(double amount) {
    if (amount == 0) return 'Zero Only';
    final int n = amount.round();
    final ones = ['', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
      'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'];
    final tens = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];

    String convert(int x) {
      if (x < 20) return ones[x];
      if (x < 100) return '${tens[x ~/ 10]} ${ones[x % 10]}'.trim();
      if (x < 1000) return '${ones[x ~/ 100]} Hundred ${convert(x % 100)}'.trim();
      return '';
    }

    String r = '';
    int x = n;
    if (x >= 10000000) { r += '${convert(x ~/ 10000000)} Crore '; x %= 10000000; }
    if (x >= 100000) { r += '${convert(x ~/ 100000)} Lakh '; x %= 100000; }
    if (x >= 1000) { r += '${convert(x ~/ 1000)} Thousand '; x %= 1000; }
    if (x >= 100) { r += '${convert(x ~/ 100)} Hundred '; x %= 100; }
    if (x > 0) r += convert(x);
    return 'INR ${r.trim()} Only';
  }
}
