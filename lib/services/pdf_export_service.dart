import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/diary_entry.dart';

class PdfExportService {
  /// Generates a PDF of all diary entries and returns the file path.
  static Future<String> exportDiary(List<DiaryEntry> entries) async {
    final pdf = pw.Document();

    final moodColors = [
      PdfColors.red400,
      PdfColors.orange400,
      PdfColors.grey500,
      PdfColors.green500,
      PdfColors.blue400,
    ];

    final months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];

    // ── Cover page ────────────────────────────────────────────────────────────
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) => pw.Container(
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [PdfColors.teal700, PdfColors.teal900],
              begin: pw.Alignment.topLeft,
              end: pw.Alignment.bottomRight,
            ),
          ),
          padding: const pw.EdgeInsets.all(60),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Spacer(),
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Text('🧠',
                    style: const pw.TextStyle(fontSize: 40)),
              ),
              pw.SizedBox(height: 32),
              pw.Text(
                'Emotion\nDiary',
                style: pw.TextStyle(
                  fontSize: 52,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Text(
                'AI-Driven Emotional Insight Report',
                style: const pw.TextStyle(
                    fontSize: 16, color: PdfColors.teal100),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Exported on ${_formatDate(DateTime.now(), months)}',
                style: const pw.TextStyle(
                    fontSize: 12, color: PdfColors.teal200),
              ),
              pw.Spacer(),
              pw.Divider(color: PdfColors.teal500),
              pw.SizedBox(height: 12),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Entries: ${entries.length}',
                      style: const pw.TextStyle(
                          color: PdfColors.white, fontSize: 13)),
                  pw.Text(
                    entries.isEmpty
                        ? ''
                        : 'From ${_formatDate(entries.last.createdAt, months)} to ${_formatDate(entries.first.createdAt, months)}',
                    style: const pw.TextStyle(
                        color: PdfColors.teal200, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // ── Stats summary page ────────────────────────────────────────────────────
    if (entries.isNotEmpty) {
      final moodCounts = List<int>.filled(5, 0);
      for (final e in entries) {
        moodCounts[e.mood.clamp(0, 4)]++;
      }
      final avgMood =
          entries.map((e) => e.mood).reduce((a, b) => a + b) / entries.length;
      final labels = ['Awful', 'Bad', 'Okay', 'Good', 'Great'];
      final emojis = ['😣', '😞', '😐', '😊', '😄'];

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context ctx) => pw.Padding(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _pdfSectionHeader('Emotional Overview'),
                pw.SizedBox(height: 24),

                // Avg mood card
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.teal50,
                    borderRadius: pw.BorderRadius.circular(12),
                    border: pw.Border.all(color: PdfColors.teal200),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Average Mood Score',
                              style: const pw.TextStyle(
                                  fontSize: 12, color: PdfColors.grey700)),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            '${avgMood.toStringAsFixed(1)} / 4.0',
                            style: pw.TextStyle(
                              fontSize: 28,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.teal700,
                            ),
                          ),
                          pw.Text(
                            labels[avgMood.round().clamp(0, 4)],
                            style: const pw.TextStyle(
                                fontSize: 14, color: PdfColors.teal600),
                          ),
                        ],
                      ),
                      pw.Spacer(),
                      pw.Text(
                        emojis[avgMood.round().clamp(0, 4)],
                        style: const pw.TextStyle(fontSize: 48),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 24),
                pw.Text('Mood Distribution',
                    style: pw.TextStyle(
                        fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 12),

                // Bar chart (manual)
                ...List.generate(5, (i) {
                  final count = moodCounts[i];
                  final maxCount = moodCounts.reduce((a, b) => a > b ? a : b);
                  final barWidth = maxCount == 0
                      ? 0.0
                      : (count / maxCount) * 300;

                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Row(
                      children: [
                        pw.SizedBox(
                            width: 16,
                            child: pw.Text(emojis[i],
                                style: const pw.TextStyle(fontSize: 13))),
                        pw.SizedBox(width: 8),
                        pw.SizedBox(
                          width: 52,
                          child: pw.Text(labels[i],
                              style: const pw.TextStyle(
                                  fontSize: 11, color: PdfColors.grey600)),
                        ),
                        pw.Container(
                          width: barWidth,
                          height: 18,
                          decoration: pw.BoxDecoration(
                            color: moodColors[i],
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Text('$count',
                            style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey700)),
                      ],
                    ),
                  );
                }),

                pw.Spacer(),
                pw.Divider(),
                pw.SizedBox(height: 8),
                pw.Text(
                  'UCCD3223 Mobile Applications Development — Group 39',
                  style: const pw.TextStyle(
                      fontSize: 10, color: PdfColors.grey500),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ── Diary entry pages ─────────────────────────────────────────────────────
    const entriesPerPage = 3;
    for (int i = 0; i < entries.length; i += entriesPerPage) {
      final pageEntries = entries.sublist(
          i, (i + entriesPerPage).clamp(0, entries.length));

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context ctx) => pw.Padding(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _pdfSectionHeader(
                    'Diary Entries  (${i + 1}–${(i + pageEntries.length)})'),
                pw.SizedBox(height: 16),
                ...pageEntries.map((entry) => _pdfEntryCard(
                    entry, months, moodColors)),
                pw.Spacer(),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Emotion Diary — Exported ${_formatDate(DateTime.now(), months)}',
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey400)),
                    pw.Text('Page ${ctx.pageNumber}',
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey400)),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Save to temp directory
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/emotion_diary_$timestamp.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  static pw.Widget _pdfSectionHeader(String title) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title,
              style: pw.TextStyle(
                  fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Container(
            width: 40,
            height: 3,
            decoration: pw.BoxDecoration(
              color: PdfColors.teal600,
              borderRadius: pw.BorderRadius.circular(2),
            ),
          ),
        ],
      );

  static pw.Widget _pdfEntryCard(
      DiaryEntry entry, List<String> months, List<PdfColor> moodColors) {
    final color = moodColors[entry.mood.clamp(0, 4)];
    final labels = ['Awful', 'Bad', 'Okay', 'Good', 'Great'];
    final emojis = ['😣', '😞', '😐', '😊', '😄'];

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header row
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(
                  color: PdfColor(color.red, color.green, color.blue, 0.15),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(emojis[entry.mood.clamp(0, 4)],
                    style: const pw.TextStyle(fontSize: 16)),
              ),
              pw.SizedBox(width: 10),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(labels[entry.mood.clamp(0, 4)],
                      style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          color: color)),
                  pw.Text(
                    _formatDate(entry.createdAt, months),
                    style: const pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey500),
                  ),
                ],
              ),
              pw.Spacer(),
              if (entry.emotionIntensity != null)
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Text(
                    'Intensity: ${entry.emotionIntensity!.toStringAsFixed(1)}/10',
                    style: const pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey600),
                  ),
                ),
            ],
          ),
          pw.SizedBox(height: 10),

          // Entry text
          pw.Text(entry.entryText,
              style: const pw.TextStyle(
                  fontSize: 12, color: PdfColors.grey800, lineSpacing: 2)),

          // AI reflection
          if (entry.aiReflection != null) ...[
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.teal50,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('✨ ',
                      style: const pw.TextStyle(fontSize: 11)),
                  pw.Expanded(
                    child: pw.Text(
                      entry.aiReflection!,
                      style: const pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.teal800,
                          lineSpacing: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Trigger keyword
          if (entry.triggerKeyword != null) ...[
            pw.SizedBox(height: 6),
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: pw.BoxDecoration(
                color: PdfColors.orange50,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text('# ${entry.triggerKeyword}',
                  style: const pw.TextStyle(
                      fontSize: 10, color: PdfColors.orange800)),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatDate(DateTime dt, List<String> months) =>
      '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
}
