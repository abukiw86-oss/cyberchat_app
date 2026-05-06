import 'package:cyberchat/src/imports/imports.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  int _currentIndex = 0;

  late final List<Map<String, dynamic>> _onboardingData;

  late AnimationController _pulseController;
  final Random _random = Random();
  late Timer _matrixTimer;
  final List<MatrixSymbol> _matrixSymbols = [];

  @override
  void initState() {
    super.initState();
    _init();
    _pageController = PageController();
    _onboardingData = [
      {
        'title': 'Your Journey,\nPerfectly Planned',
        'subtitle':
            'Effortlessly create and organize your\ndream trips. Start exploring now!',
        'pageWidget': const FlutterLogo(size: 200),
      },
      {
        'title': 'Discover\nFriends Nearby',
        'subtitle':
            'See where your friends are traveling and\nexplore the world together.',
        'pageWidget': const FlutterLogo(size: 200),
      },
      {
        'title': 'Stay Updated\nwith Top Places',
        'subtitle':
            'Find trending destinations and must-see attractions,\nall tailored to enhance your travel plans.',
        'pageWidget': const FlutterLogo(size: 200),
      },
    ];
  }

  void _init() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    for (int i = 0; i < 30; i++) {
      _matrixSymbols.add(MatrixSymbol(
        position:
            Offset(_random.nextDouble() * 400, _random.nextDouble() * 800),
        symbol: _getRandomMatrixSymbol(),
      ));
    }

    _matrixTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          for (final symbol in _matrixSymbols) {
            if (_random.nextDouble() > 0.7) {
              symbol.symbol = _getRandomMatrixSymbol();
              symbol.position = Offset(symbol.position.dx,
                  symbol.position.dy + _random.nextDouble() * 5);
            }
            if (symbol.position.dy > 800) {
              symbol.position = Offset(symbol.position.dx, 0);
            }
          }
        });
      }
    });
  }

  String _getRandomMatrixSymbol() {
    const String chars =
        '0101010101001001001001001001010101010101010101010101010101010010101';
    return chars[_random.nextInt(chars.length)];
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _matrixTimer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _onGetStarted() {
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final matrix = _matrixSymbols;

    return _OnboardingView(
      theme: theme,
      colorScheme: colorScheme,
      textTheme: textTheme,
      pageController: _pageController,
      currentIndex: _currentIndex,
      onboardingData: _onboardingData,
      onPageChanged: (index) => setState(() => _currentIndex = index),
      onGetStarted: _onGetStarted,
      matrix: matrix,
    );
  }
}

class _OnboardingView extends StatelessWidget {
  const _OnboardingView({
    required this.matrix,
    required this.theme,
    required this.colorScheme,
    required this.textTheme,
    required this.pageController,
    required this.currentIndex,
    required this.onboardingData,
    required this.onPageChanged,
    required this.onGetStarted,
  });
  final List<MatrixSymbol> matrix;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final PageController pageController;
  final int currentIndex;
  final List<Map<String, dynamic>> onboardingData;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            CustomPaint(
              painter: MatrixRainPainter(symbols: matrix),
              size: Size.infinite,
            ),
            Text(
              'Cyberchat.',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: colorScheme.onSurface,
                fontSize: 22,
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: pageController,
                itemCount: onboardingData.length,
                onPageChanged: onPageChanged,
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                            ),
                            child:
                                onboardingData[index]['pageWidget'] as Widget,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                        ),
                        child: Column(
                          children: [
                            Text(
                              onboardingData[index]['title'] as String,
                              textAlign: TextAlign.center,
                              style: textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                                height: 1.2,
                                fontSize: 24,
                              ),
                            ),
                            SizedBox(height: AppSpacing.md),
                            Text(
                              onboardingData[index]['subtitle'] as String,
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.5,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  AppButton(
                    label: 'Get Started',
                    onPressed: onGetStarted,
                    variant: ButtonVariant.primary,
                    width: ButtonSize.medium,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
