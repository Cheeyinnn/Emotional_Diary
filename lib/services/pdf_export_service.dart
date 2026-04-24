import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/diary_entry.dart';

class PdfExportService {
  /// Generates a PDF of all diary entries and returns the file path.
  static Future<String> exportDiary(
    List<DiaryEntry> entries, {
    String? userName,
    String? userEmail,
  }) async {
    final pdf = pw.Document();

    final moodColors = [
      PdfColors.red400,
      PdfColors.orange400,
      PdfColors.grey500,
      PdfColors.green500,
      PdfColors.blue400,
    ];

    final labels = ['Awful', 'Bad', 'Okay', 'Good', 'Great'];

    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    final safeUserName =
        userName != null && userName.trim().isNotEmpty ? userName.trim() : 'Guest User';

    final safeUserEmail =
        userEmail != null && userEmail.trim().isNotEmpty ? userEmail.trim() : 'Not provided';

    final reportId = 'ED-${DateTime.now().millisecondsSinceEpoch}';

    final moodEmojiImages = [
      pw.MemoryImage(
        (await rootBundle.load('assets/emojis/awful.webp'))
            .buffer
            .asUint8List(),
      ),
      pw.MemoryImage(
        (await rootBundle.load('assets/emojis/bad.webp'))
            .buffer
            .asUint8List(),
      ),
      pw.MemoryImage(
        (await rootBundle.load('assets/emojis/okay.webp'))
            .buffer
            .asUint8List(),
      ),
      pw.MemoryImage(
        (await rootBundle.load('assets/emojis/good.webp'))
            .buffer
            .asUint8List(),
      ),
      pw.MemoryImage(
        (await rootBundle.load('assets/emojis/great.webp'))
            .buffer
            .asUint8List(),
      ),
    ];

    final sortedEntries = [...entries]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final reportPeriod = sortedEntries.isEmpty
        ? 'No diary entries recorded'
        : '${_formatDate(sortedEntries.last.createdAt, months)} to ${_formatDate(sortedEntries.first.createdAt, months)}';

    String mostFrequentMood = '-';
    double avgMood = 0.0;
    final moodCounts = List<int>.filled(5, 0);

    if (sortedEntries.isNotEmpty) {
      for (final e in sortedEntries) {
        moodCounts[e.mood.clamp(0, 4)]++;
      }

      avgMood = sortedEntries.map((e) => e.mood).reduce((a, b) => a + b) /
          sortedEntries.length;

      int maxIndex = 0;
      for (int i = 1; i < moodCounts.length; i++) {
        if (moodCounts[i] > moodCounts[maxIndex]) {
          maxIndex = i;
        }
      }
      mostFrequentMood = labels[maxIndex];
    }

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
                child: pw.Text(
                  'AI',
                  style: pw.TextStyle(
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.teal800,
                  ),
                ),
              ),
              pw.SizedBox(height: 32),
              pw.Text(
                'Personal\nEmotion Report',
                style: pw.TextStyle(
                  fontSize: 48,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Text(
                'AI-Driven Emotional Insight Report',
                style: const pw.TextStyle(
                  fontSize: 16,
                  color: PdfColors.teal100,
                ),
              ),
              pw.SizedBox(height: 26),

              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0x1FFFFFFF),
                  borderRadius: pw.BorderRadius.circular(12),
                  border: pw.Border.all(color: PdfColors.teal300),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Prepared for',
                      style: const pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.teal100,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      safeUserName,
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      safeUserEmail,
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.teal100,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),
              pw.Text(
                'Exported on ${_formatDate(DateTime.now(), months)}',
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.teal200,
                ),
              ),
              pw.Text(
                'Report ID: $reportId',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.teal200,
                ),
              ),

              pw.Spacer(),
              pw.Divider(color: PdfColors.teal500),
              pw.SizedBox(height: 12),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total Entries: ${sortedEntries.length}',
                    style: const pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 13,
                    ),
                  ),
                  pw.Text(
                    reportPeriod,
                    style: const pw.TextStyle(
                      color: PdfColors.teal200,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // ── Stats summary page ────────────────────────────────────────────────────
    if (sortedEntries.isNotEmpty) {
      final avgMoodIndex = avgMood.round().clamp(0, 4);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context ctx) => pw.Padding(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _pdfSectionHeader('Emotional Overview'),
                pw.SizedBox(height: 18),

                pw.Container(
                  padding: const pw.EdgeInsets.all(14),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(10),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _infoRow('Name', safeUserName),
                      _infoRow('Email', safeUserEmail),
                      _infoRow('Report Period', reportPeriod),
                      _infoRow('Report ID', reportId),
                    ],
                  ),
                ),

                pw.SizedBox(height: 20),

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
                          pw.Text(
                            'Average Mood Score',
                            style: const pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.grey700,
                            ),
                          ),
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
                            labels[avgMoodIndex],
                            style: const pw.TextStyle(
                              fontSize: 14,
                              color: PdfColors.teal600,
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text(
                            'Most Frequent Mood: $mostFrequentMood',
                            style: const pw.TextStyle(
                              fontSize: 11,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                      pw.Spacer(),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.teal100,
                          borderRadius: pw.BorderRadius.circular(12),
                        ),
                        child: pw.Image(
                          moodEmojiImages[avgMoodIndex],
                          width: 42,
                          height: 42,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 20),

                pw.Container(
                  padding: const pw.EdgeInsets.all(14),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: pw.BorderRadius.circular(10),
                    border: pw.Border.all(color: PdfColors.blue100),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'AI Summary Note',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        _generateSummaryNote(avgMood, mostFrequentMood),
                        style: const pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.blueGrey800,
                          lineSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 22),
                pw.Text(
                  'Mood Distribution',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),

                ...List.generate(5, (i) {
                  final count = moodCounts[i];
                  final maxCount = moodCounts.reduce((a, b) => a > b ? a : b);
                  final barWidth =
                      maxCount == 0 ? 0.0 : (count / maxCount) * 280;

                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Row(
                      children: [
                        pw.SizedBox(
                          width: 22,
                          child: pw.Image(
                            moodEmojiImages[i],
                            width: 14,
                            height: 14,
                          ),
                        ),
                        pw.SizedBox(width: 6),
                        pw.SizedBox(
                          width: 52,
                          child: pw.Text(
                            labels[i],
                            style: const pw.TextStyle(
                              fontSize: 11,
                              color: PdfColors.grey600,
                            ),
                          ),
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
                        pw.Text(
                          '$count',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey700,
                          ),
                        ),
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
                    fontSize: 10,
                    color: PdfColors.grey500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ── Diary entry pages ─────────────────────────────────────────────────────
    const entriesPerPage = 3;

    for (int i = 0; i < sortedEntries.length; i += entriesPerPage) {
      final pageEntries = sortedEntries.sublist(
        i,
        (i + entriesPerPage).clamp(0, sortedEntries.length),
      );

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context ctx) => pw.Padding(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _pdfSectionHeader(
                  'Diary Entries  (${i + 1}-${(i + pageEntries.length)})',
                ),
                pw.SizedBox(height: 16),
                ...pageEntries.map(
                  (entry) => _pdfEntryCard(
                    entry,
                    months,
                    moodColors,
                    moodEmojiImages,
                  ),
                ),
                pw.Spacer(),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '$safeUserName — Emotion Diary Exported ${_formatDate(DateTime.now(), months)}',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey400,
                      ),
                    ),
                    pw.Text(
                      'Page ${ctx.pageNumber}',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ── Disclaimer page ───────────────────────────────────────────────────────
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) => pw.Padding(
          padding: const pw.EdgeInsets.all(40),
          child: pw.Center(
            child: pw.Text(
              'Disclaimer: This report is generated for self-reflection purposes only. '
              'It is not a medical diagnosis and should not replace advice from a qualified mental health professional.',
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(
                fontSize: 12,
                color: PdfColors.grey700,
                lineSpacing: 2,
              ),
            ),
          ),
        ),
      ),
    );

    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/emotion_diary_$timestamp.pdf');

    await file.writeAsBytes(await pdf.save());

    return file.path;
  }

  static pw.Widget _pdfSectionHeader(String title) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
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

  static pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 90,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _pdfEntryCard(
    DiaryEntry entry,
    List<String> months,
    List<PdfColor> moodColors,
    List<pw.MemoryImage> moodEmojiImages,
  ) {
    final moodIndex = entry.mood.clamp(0, 4);
    final color = moodColors[moodIndex];
    final labels = ['Awful', 'Bad', 'Okay', 'Good', 'Great'];

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
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(
                  color: PdfColor(color.red, color.green, color.blue, 0.15),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Image(
                  moodEmojiImages[moodIndex],
                  width: 18,
                  height: 18,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    labels[moodIndex],
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: color,
                    ),
                  ),
                  pw.Text(
                    _formatDate(entry.createdAt, months),
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey500,
                    ),
                  ),
                ],
              ),
              pw.Spacer(),
              if (entry.emotionIntensity != null)
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Text(
                    'Intensity: ${entry.emotionIntensity!.toStringAsFixed(1)}/10',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
            ],
          ),
          pw.SizedBox(height: 10),

          pw.Text(
            entry.entryText,
            style: const pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey800,
              lineSpacing: 2,
            ),
          ),

          if (entry.aiReflection != null &&
              entry.aiReflection!.trim().isNotEmpty) ...[
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
                  pw.Text(
                    'AI: ',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.teal800,
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      entry.aiReflection!,
                      style: const pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.teal800,
                        lineSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (entry.activitySuggestion != null &&
              entry.activitySuggestion!.trim().isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Suggested Activity: ${entry.activitySuggestion}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.green800,
                    ),
                  ),
                  if (entry.activityDuration != null &&
                      entry.activityDuration!.trim().isNotEmpty) ...[
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'Duration: ${entry.activityDuration}',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.green700,
                      ),
                    ),
                  ],
                  if (entry.activitySteps != null &&
                      entry.activitySteps!.trim().isNotEmpty) ...[
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'Steps: ${entry.activitySteps}',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.green700,
                        lineSpacing: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          if (entry.triggerKeyword != null &&
              entry.triggerKeyword!.trim().isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColors.orange50,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(
                '# ${entry.triggerKeyword}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.orange800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _generateSummaryNote(double avgMood, String mostFrequentMood) {
    if (avgMood >= 3.3) {
      return 'Overall, this report shows a generally positive emotional pattern. '
          'The most frequent mood recorded was $mostFrequentMood. Continue using the diary to maintain self-awareness and strengthen positive routines.';
    } else if (avgMood >= 2.0) {
      return 'This report shows a balanced emotional pattern with some changes across entries. '
          'The most frequent mood recorded was $mostFrequentMood. Regular reflection may help identify triggers and support better emotional regulation.';
    } else {
      return 'This report shows several lower mood entries. '
          'The most frequent mood recorded was $mostFrequentMood. Consider using the suggested wellness activities and seeking support if negative feelings continue.';
    }
  }

  static String _formatDate(DateTime dt, List<String> months) =>
      '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
}