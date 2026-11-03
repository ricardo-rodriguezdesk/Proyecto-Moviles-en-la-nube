import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../providers/onboarding_provider.dart';

class _OnboardingPageData {
  const _OnboardingPageData(this.icon, this.title, this.body);
  final IconData icon;
  final String title;
  final String body;
}

const _pages = [
  _OnboardingPageData(
    Icons.wb_sunny_outlined,
    'Mide la luz de tu espacio',
    'Coloca tu celular donde quieres tu planta. Lumen lee el sensor de luz '
        'y te dice qué especies van a crecer bien ahí.',
  ),
  _OnboardingPageData(
    Icons.local_florist_outlined,
    'Plantas cada mes',
    'Elige un plan y recibe plantas seleccionadas para la luz de tu casa, '
        'con su guía de cuidados.',
  ),
  _OnboardingPageData(
    Icons.notifications_active_outlined,
    'Cuidados a tiempo',
    'Recibe recordatorios de riego, novedades del vivero y avisos de '
        'talleres directo en tu celular.',
  ),
];

/// Estado del carrusel (página actual). Vive solo mientras la pantalla existe.
class OnboardingPageController extends ChangeNotifier {
  final pageController = PageController();
  int _page = 0;

  int get page => _page;
  bool get isLast => _page == _pages.length - 1;

  void onPageChanged(int index) {
    _page = index;
    notifyListeners();
  }

  void next() {
    pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnboardingPageController(),
      child: const _OnboardingView(),
    );
  }
}

class _OnboardingView extends StatelessWidget {
  const _OnboardingView();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<OnboardingPageController>();
    final onboarding = context.read<OnboardingProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: AnimatedOpacity(
                  opacity: c.isLast ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: TextButton(
                    onPressed: c.isLast ? null : onboarding.finish,
                    child: const Text('Saltar'),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: c.pageController,
                onPageChanged: c.onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (_, i) => _OnboardingPage(data: _pages[i]),
              ),
            ),
            SmoothPageIndicator(
              controller: c.pageController,
              count: _pages.length,
              effect: ExpandingDotsEffect(
                activeDotColor: scheme.primary,
                dotColor: scheme.outlineVariant,
                dotHeight: 8,
                dotWidth: 8,
                expansionFactor: 3,
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: FilledButton(
                  onPressed: c.isLast ? onboarding.finish : c.next,
                  child: Text(c.isLast ? 'Empezar' : 'Siguiente'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});

  final _OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [scheme.primaryContainer, scheme.tertiaryContainer],
                  ),
                ),
                child: Icon(data.icon, size: 96, color: scheme.primary),
              ),
              const SizedBox(height: 40),
              Text(data.title,
                  textAlign: TextAlign.center, style: text.headlineMedium),
              const SizedBox(height: 16),
              Text(
                data.body,
                textAlign: TextAlign.center,
                style:
                    text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
