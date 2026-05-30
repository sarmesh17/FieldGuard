import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../service/geofence_logger.dart';

/// Diagnostics viewer for the in-memory geofence log ring-buffer.
///
/// Rebuilds reactively via [GeofenceLogger.changeNotifier] and shows the most
/// recent entries first. Supports copying the full log to the clipboard and
/// clearing the buffer.
class GeofenceLogScreen extends StatelessWidget {
  const GeofenceLogScreen({super.key});

  static const _appBarColor = Color(0xff0E5A3B);
  static const _bgColor = Color(0xFFF5F6FA);

  Color _levelColor(GeoLogLevel level) => switch (level) {
        GeoLogLevel.debug => Colors.blueGrey,
        GeoLogLevel.info => const Color(0xff1E40AF),
        GeoLogLevel.warn => Colors.orange.shade800,
        GeoLogLevel.error => Colors.red.shade700,
      };

  String _exportText(List<GeoLogEntry> entries) => entries
      .map((e) => '${e.timeString} ${e.levelIcon} [${e.tag}] ${e.message}')
      .join('\n');

  @override
  Widget build(BuildContext context) {
    final logger = GeofenceLogger.instance;
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _appBarColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Geofence Logs',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Copy logs',
            icon: const Icon(Icons.copy_rounded, color: Colors.white),
            onPressed: () async {
              final entries = logger.entries;
              if (entries.isEmpty) return;
              await Clipboard.setData(
                ClipboardData(text: _exportText(entries)),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logs copied to clipboard')),
                );
              }
            },
          ),
          IconButton(
            tooltip: 'Clear logs',
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
            onPressed: logger.clear,
          ),
        ],
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: logger.changeNotifier,
        builder: (context, _, __) {
          final entries = logger.entries.reversed.toList(growable: false);
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_history_rounded,
                    size: w * 0.15,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: h * 0.02),
                  Text(
                    'No geofence logs yet',
                    style: TextStyle(
                      fontSize: w * 0.045,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.symmetric(
              horizontal: w * 0.04,
              vertical: h * 0.015,
            ),
            itemCount: entries.length,
            separatorBuilder: (_, __) => SizedBox(height: h * 0.008),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final color = _levelColor(entry.level);
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: w * 0.03,
                  vertical: h * 0.012,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(w * 0.025),
                  border: Border(left: BorderSide(color: color, width: 4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(entry.levelIcon,
                            style: TextStyle(fontSize: w * 0.035)),
                        SizedBox(width: w * 0.02),
                        Expanded(
                          child: Text(
                            entry.tag,
                            style: TextStyle(
                              fontSize: w * 0.035,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                        Text(
                          entry.timeString,
                          style: TextStyle(
                            fontSize: w * 0.03,
                            color: Colors.grey.shade500,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: h * 0.006),
                    Text(
                      entry.message,
                      style: TextStyle(
                        fontSize: w * 0.034,
                        color: Colors.grey.shade800,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
