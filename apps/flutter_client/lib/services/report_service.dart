import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/coalition.dart';
import '../models/election.dart';
import '../models/forecast.dart';
import '../models/party.dart';

/// Generates PDF reports for parties, candidates, forecasts, and coalition
/// scenarios (spec section 38 exports / section 64 "analyst reports").
/// Every report carries a generated timestamp, model version (where
/// applicable), and a disclaimer that figures are model estimates —
/// mirroring the same "never present a forecast as a bare fact" rule the
/// in-app screens follow (section 2, 80).
///
/// Arabic PDF text requires a font with Arabic glyphs (the built-in PDF
/// base-14 fonts do not have them), so Arabic reports fetch `PdfGoogleFonts`
/// at runtime from Google Fonts — the first Arabic report generated needs
/// network access. English/Latin reports use the PDF package's built-in
/// Helvetica, which needs no network at all, so report generation never
/// requires network access unless the report is actually in Arabic.
/// [useArabicFont] can be forced to false to skip the Arabic font fetch
/// even for an Arabic report (falls back to Helvetica, which cannot
/// render Arabic glyphs) — used by widget tests so report generation
/// stays hermetic/offline-safe.
class ReportService {
  static Future<pw.Font> _bodyFont({required bool arabic, required bool useArabicFont}) async {
    if (arabic && useArabicFont) {
      try {
        return await PdfGoogleFonts.notoNaskhArabicRegular();
      } catch (_) {
        // Offline or fetch failed — fall back rather than crash report
        // generation (section 67 failure-handling philosophy applied to
        // this feature too).
      }
    }
    return pw.Font.helvetica();
  }

  static Future<pw.Font> _boldFont({required bool arabic, required bool useArabicFont}) async {
    if (arabic && useArabicFont) {
      try {
        return await PdfGoogleFonts.notoNaskhArabicBold();
      } catch (_) {}
    }
    return pw.Font.helveticaBold();
  }

  static pw.Widget _disclaimer(String text, pw.TextStyle style) => pw.Container(
        margin: const pw.EdgeInsets.only(top: 24),
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400), borderRadius: pw.BorderRadius.circular(4)),
        child: pw.Text(text, style: style.copyWith(fontSize: 9, color: PdfColors.grey700)),
      );

  static Future<Uint8List> buildForecastReport({
    required ForecastRun run,
    required ElectionRuleSetSummary rules,
    required String title,
    required String generatedOnLabel,
    required String modelVersionLabel,
    required String seatsLabel,
    required String voteShareLabel,
    required String disclaimer,
    bool arabic = false,
    bool useArabicFont = true,
  }) async {
    final body = await _bodyFont(arabic: arabic, useArabicFont: useArabicFont);
    final bold = await _boldFont(arabic: arabic, useArabicFont: useArabicFont);
    final baseStyle = pw.TextStyle(font: body, fontSize: 11);
    final boldStyle = pw.TextStyle(font: bold, fontSize: 11, fontWeight: pw.FontWeight.bold);
    final dir = arabic ? pw.TextDirection.rtl : pw.TextDirection.ltr;

    final doc = pw.Document();
    final sorted = [...run.partyResults]..sort((a, b) => b.seatsMedian.compareTo(a.seatsMedian));

    doc.addPage(
      pw.MultiPage(
        textDirection: dir,
        build: (context) => [
          pw.Header(level: 0, child: pw.Text(title, style: pw.TextStyle(font: bold, fontSize: 20))),
          pw.Text('$generatedOnLabel: ${DateTime.now().toIso8601String()}', style: baseStyle),
          pw.Text('$modelVersionLabel: ${run.modelVersion} · ${run.datasetVersion}', style: baseStyle),
          pw.Text('Data cutoff: ${run.dataCutoffAt.toIso8601String()}', style: baseStyle),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headerStyle: boldStyle,
            cellStyle: baseStyle,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            data: [
              [arabic ? 'القائمة' : 'List', seatsLabel, '80%', voteShareLabel, arabic ? 'احتمال الأكبر' : 'P(Largest)'],
              ...sorted.map((r) => [
                    arabic ? r.listNameAr : r.listNameEn,
                    '${r.seatsMedian}',
                    '${r.seatsLow80}-${r.seatsHigh80}',
                    '${r.forecastVoteShareMedian.toStringAsFixed(1)}%',
                    '${(r.probabilityLargestList * 100).round()}%',
                  ]),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            '${arabic ? 'الأغلبية' : 'Majority threshold'}: ${rules.majorityThreshold} / ${rules.totalSeats}',
            style: baseStyle,
          ),
          _disclaimer(disclaimer, baseStyle),
        ],
      ),
    );
    return doc.save();
  }

  static Future<Uint8List> buildPartyReport({
    required Party party,
    ElectoralList? electoralList,
    ForecastPartyResult? forecastResult,
    required String title,
    required String generatedOnLabel,
    required String disclaimer,
    bool arabic = false,
    bool useArabicFont = true,
  }) async {
    final body = await _bodyFont(arabic: arabic, useArabicFont: useArabicFont);
    final bold = await _boldFont(arabic: arabic, useArabicFont: useArabicFont);
    final baseStyle = pw.TextStyle(font: body, fontSize: 11);
    final dir = arabic ? pw.TextDirection.rtl : pw.TextDirection.ltr;

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        textDirection: dir,
        build: (context) => [
          pw.Header(level: 0, child: pw.Text(title, style: pw.TextStyle(font: bold, fontSize: 20))),
          pw.Text('$generatedOnLabel: ${DateTime.now().toIso8601String()}', style: baseStyle),
          pw.SizedBox(height: 12),
          pw.Text(arabic ? party.nameAr : party.nameEn, style: pw.TextStyle(font: bold, fontSize: 16)),
          if (party.abbreviation != null) pw.Text(party.abbreviation!, style: baseStyle),
          pw.SizedBox(height: 8),
          pw.Text('${arabic ? 'حالة التسجيل' : 'Registration status'}: ${party.registrationStatus}', style: baseStyle),
          if (party.registrationStatusVerifiedAt != null)
            pw.Text('${arabic ? 'تاريخ التحقق' : 'Verified'}: ${party.registrationStatusVerifiedAt}', style: baseStyle),
          if ((arabic ? party.descriptionAr : party.descriptionEn) != null) ...[
            pw.SizedBox(height: 8),
            pw.Text((arabic ? party.descriptionAr : party.descriptionEn)!, style: baseStyle),
          ],
          if (forecastResult != null) ...[
            pw.SizedBox(height: 16),
            pw.Text(arabic ? 'التوقع الحالي' : 'Current forecast', style: pw.TextStyle(font: bold, fontSize: 13)),
            pw.Text(
              '${arabic ? 'المقاعد' : 'Seats'}: ${forecastResult.seatsMedian} '
              '(80%: ${forecastResult.seatsLow80}-${forecastResult.seatsHigh80})',
              style: baseStyle,
            ),
            pw.Text(
              '${arabic ? 'نسبة الأصوات' : 'Vote share'}: ${forecastResult.forecastVoteShareMedian.toStringAsFixed(1)}%',
              style: baseStyle,
            ),
          ],
          _disclaimer(disclaimer, baseStyle),
        ],
      ),
    );
    return doc.save();
  }

  static Future<Uint8List> buildCandidateReport({
    required String fullNameAr,
    required String fullNameEn,
    required String listNameEn,
    required String listNameAr,
    required int listRank,
    String? hometown,
    String? biography,
    double? seatProbability,
    int? seatsMedian,
    int? seatsLow80,
    int? seatsHigh80,
    required String title,
    required String generatedOnLabel,
    required String disclaimer,
    bool arabic = false,
    bool useArabicFont = true,
  }) async {
    final body = await _bodyFont(arabic: arabic, useArabicFont: useArabicFont);
    final bold = await _boldFont(arabic: arabic, useArabicFont: useArabicFont);
    final baseStyle = pw.TextStyle(font: body, fontSize: 11);
    final dir = arabic ? pw.TextDirection.rtl : pw.TextDirection.ltr;

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        textDirection: dir,
        build: (context) => [
          pw.Header(level: 0, child: pw.Text(title, style: pw.TextStyle(font: bold, fontSize: 20))),
          pw.Text('$generatedOnLabel: ${DateTime.now().toIso8601String()}', style: baseStyle),
          pw.SizedBox(height: 12),
          pw.Text(arabic ? fullNameAr : fullNameEn, style: pw.TextStyle(font: bold, fontSize: 16)),
          pw.Text('${arabic ? listNameAr : listNameEn} · #$listRank', style: baseStyle),
          if (hometown != null) pw.Text('${arabic ? 'البلدة' : 'Hometown'}: $hometown', style: baseStyle),
          if (biography != null) ...[
            pw.SizedBox(height: 8),
            pw.Text(biography, style: baseStyle),
          ],
          if (seatProbability != null) ...[
            pw.SizedBox(height: 16),
            pw.Text(
              '${arabic ? 'الاحتمال التقديري للفوز بمقعد' : 'Estimated seat probability'}: '
              '${(seatProbability * 100).round()}%',
              style: pw.TextStyle(font: bold, fontSize: 14),
            ),
            if (seatsMedian != null)
              pw.Text(
                '${arabic ? 'توقع مقاعد القائمة' : 'List seat forecast'}: $seatsMedian '
                '(80%: $seatsLow80-$seatsHigh80)',
                style: baseStyle,
              ),
          ],
          _disclaimer(disclaimer, baseStyle),
        ],
      ),
    );
    return doc.save();
  }

  static Future<Uint8List> buildCoalitionReport({
    required List<String> listNames,
    required CoalitionSimulationResult result,
    required String title,
    required String generatedOnLabel,
    required String disclaimer,
    bool arabic = false,
    bool useArabicFont = true,
  }) async {
    final body = await _bodyFont(arabic: arabic, useArabicFont: useArabicFont);
    final bold = await _boldFont(arabic: arabic, useArabicFont: useArabicFont);
    final baseStyle = pw.TextStyle(font: body, fontSize: 11);
    final dir = arabic ? pw.TextDirection.rtl : pw.TextDirection.ltr;

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        textDirection: dir,
        build: (context) => [
          pw.Header(level: 0, child: pw.Text(title, style: pw.TextStyle(font: bold, fontSize: 20))),
          pw.Text('$generatedOnLabel: ${DateTime.now().toIso8601String()}', style: baseStyle),
          pw.SizedBox(height: 12),
          pw.Text(listNames.join(' + '), style: pw.TextStyle(font: bold, fontSize: 14)),
          pw.SizedBox(height: 12),
          pw.Text(
            '${arabic ? 'مجموع المقاعد' : 'Combined seats'}: ${result.seatsMedian} '
            '(80%: ${result.seatsLow80}-${result.seatsHigh80})',
            style: baseStyle,
          ),
          pw.Text('${arabic ? 'عتبة الأغلبية' : 'Majority threshold'}: ${result.majorityThreshold}', style: baseStyle),
          pw.Text(
            '${arabic ? 'احتمال الوصول إلى الأغلبية' : 'Probability of reaching a majority'}: '
            '${(result.majorityProbability * 100).round()}%',
            style: pw.TextStyle(font: bold, fontSize: 13),
          ),
          _disclaimer(
            '${arabic ? 'جدوى رياضية فقط' : 'Mathematical feasibility only'} - $disclaimer',
            baseStyle,
          ),
        ],
      ),
    );
    return doc.save();
  }

  /// Opens the OS print/preview dialog for [bytes] — works on Windows and
  /// Android alike via the `printing` package, avoiding a separate
  /// file-save flow.
  static Future<void> previewOrPrint(Uint8List bytes, String documentName) {
    return Printing.layoutPdf(onLayout: (_) async => bytes, name: documentName);
  }
}
