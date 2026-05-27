import 'package:flutter/material.dart';

/// A slide-to-confirm control for starting / stopping field tracking.
///
/// Inactive  → thumb on the left, slide RIGHT to start (green).
/// Active     → thumb on the right, slide LEFT to stop (red).
/// While [busy] the thumb shows a spinner and dragging is ignored.
class SlideToTrack extends StatefulWidget {
  final bool active;
  final bool busy;

  /// Fired when the user slides past the threshold. [desired] is the state
  /// being requested (true = start, false = stop).
  final ValueChanged<bool> onSlide;

  const SlideToTrack({
    super.key,
    required this.active,
    required this.busy,
    required this.onSlide,
  });

  @override
  State<SlideToTrack> createState() => _SlideToTrackState();
}

class _SlideToTrackState extends State<SlideToTrack> {
  static const double _height = 58;
  static const double _thumb = 50;
  static const double _pad = 4;

  double _dx = 0;
  bool _dragging = false;

  double _maxX(double width) => width - _thumb - _pad * 2;

  @override
  void didUpdateWidget(SlideToTrack old) {
    super.didUpdateWidget(old);
    // Parent flipped the state — settle the thumb on the correct side.
    if (old.active != widget.active) {
      _dx = 0;
      _dragging = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final start = !widget.active; // sliding to START vs STOP
    final accent =
        start ? const Color(0xff0E5A3B) : Colors.red.shade600;
    final label = widget.busy
        ? (start ? 'Starting…' : 'Stopping…')
        : (start ? 'Slide to start tracking' : 'Slide to stop tracking');

    return LayoutBuilder(
      builder: (context, c) {
        final maxX = _maxX(c.maxWidth);
        // Resting offset: start → thumb left (0); active → thumb right (maxX).
        final rest = start ? 0.0 : maxX;
        final thumbX = (_dragging ? _dx : rest).clamp(0.0, maxX);
        final progress = maxX <= 0 ? 0.0 : (thumbX / maxX);
        // Fill follows the thumb so it reads as a slider.
        final fill = start ? progress : (1 - progress);

        return GestureDetector(
          onHorizontalDragStart: widget.busy
              ? null
              : (_) => setState(() {
                    _dragging = true;
                    _dx = rest;
                  }),
          onHorizontalDragUpdate: widget.busy
              ? null
              : (d) => setState(
                  () => _dx = (_dx + d.delta.dx).clamp(0.0, maxX)),
          onHorizontalDragEnd: widget.busy
              ? null
              : (_) {
                  final crossed =
                      start ? _dx >= maxX * 0.65 : _dx <= maxX * 0.35;
                  setState(() => _dragging = false);
                  if (crossed) widget.onSlide(start);
                },
          child: Container(
            height: _height,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_height / 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Progress fill
                FractionallySizedBox(
                  alignment: start
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  widthFactor: (0.12 + fill * 0.88).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(_height / 2),
                    ),
                  ),
                ),
                // Label
                Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
                // Thumb
                AnimatedPositioned(
                  duration: Duration(milliseconds: _dragging ? 0 : 220),
                  curve: Curves.easeOut,
                  left: _pad + thumbX,
                  top: _pad,
                  child: Container(
                    width: _thumb,
                    height: _thumb,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: widget.busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              start
                                  ? Icons.chevron_right
                                  : Icons.chevron_left,
                              color: Colors.white,
                              size: 26,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
