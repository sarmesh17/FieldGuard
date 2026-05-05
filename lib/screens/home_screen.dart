import 'package:flutter/material.dart';
import '../core/responsive/responsive.dart';
import '../widgets/counter_card.dart';
import '../widgets/info_card.dart';

/// Home screen demonstrating the responsive design system.
///
/// Uses [ResponsiveBuilder] to adapt layout based on screen size and
/// orientation. Wraps content in [SafeArea] and [SingleChildScrollView]
/// to handle notches and prevent overflow on small screens.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenType, orientation, constraints) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'Field Guard',
                style: AppTextStyles.headlineMedium,
              ),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              child: _buildBody(screenType, orientation),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _incrementCounter,
            tooltip: 'Increment',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildBody(ScreenType screenType, Orientation orientation) {
    // On large screens (tablets) or landscape, use a side-by-side layout.
    final useTwoColumn =
        screenType == ScreenType.large ||
        (screenType == ScreenType.medium &&
            orientation == Orientation.landscape);

    if (useTwoColumn) {
      return _buildTwoColumnLayout();
    }
    return _buildSingleColumnLayout();
  }

  Widget _buildSingleColumnLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CounterCard(counter: _counter),
        AppSpacing.sectionGap,
        const InfoCard(
          title: 'Responsive Design',
          description:
              'This layout adapts to your screen size. Try rotating your '
              'device or running on different screen sizes to see the layout '
              'adjust automatically.',
          icon: Icons.devices,
        ),
        AppSpacing.sectionGap,
        const InfoCard(
          title: 'Scalable Typography',
          description:
              'Text sizes scale proportionally based on screen width and '
              'respect system accessibility settings.',
          icon: Icons.text_fields,
        ),
        AppSpacing.sectionGap,
        const InfoCard(
          title: 'Flexible Spacing',
          description:
              'Padding and margins use a centralized spacing system that '
              'scales consistently across all breakpoints.',
          icon: Icons.space_bar,
        ),
      ],
    );
  }

  Widget _buildTwoColumnLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CounterCard(counter: _counter),
        AppSpacing.sectionGap,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: InfoCard(
                title: 'Responsive Design',
                description:
                    'This layout adapts to your screen size. Rotate or '
                    'resize to see changes.',
                icon: Icons.devices,
              ),
            ),
            SizedBox(width: AppSpacing.md),
            const Expanded(
              child: InfoCard(
                title: 'Scalable Typography',
                description:
                    'Text sizes scale proportionally and respect system '
                    'accessibility settings.',
                icon: Icons.text_fields,
              ),
            ),
          ],
        ),
        AppSpacing.sectionGap,
        const InfoCard(
          title: 'Flexible Spacing',
          description:
              'Padding and margins use a centralized spacing system that '
              'scales consistently across all breakpoints.',
          icon: Icons.space_bar,
        ),
      ],
    );
  }
}
