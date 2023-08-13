import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'movie.dart';

const transitionDuration = Duration(milliseconds: 500);

class TicketBookingScreen extends StatefulWidget {
  const TicketBookingScreen({super.key});

  @override
  State<TicketBookingScreen> createState() => _TicketBookingScreenState();
}

class _TicketBookingScreenState extends State<TicketBookingScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late PageController _backgroundPageController;
  int _selectedIndex = 0;
  late Movie selectedMovie;
  bool _showPosterListView = true;
  final double moviesPageViewportFraction = .8;
  late AnimationController _animationController;
  late Animation<double> _posterAnimation;
  late Animation<RelativeRect> _cardAnimation;

  void onBook() {
    _animationController.forward(from: 0.0);
  }

  @override
  void initState() {
    super.initState();
    _backgroundPageController = PageController();
    _pageController =
        PageController(viewportFraction: moviesPageViewportFraction);
    selectedMovie = movies.first;

    _animationController =
        AnimationController(vsync: this, duration: transitionDuration);
    _animationController.addListener(() {
      if (_animationController.isCompleted && _showPosterListView) {
        setState(() => _showPosterListView = false);
      } else if (_animationController.value < 1.0 && !_showPosterListView) {
        setState(() => _showPosterListView = true);
      }
    });

    _posterAnimation = Tween<double>(
      begin: 0.0,
      end: 90,
    ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.linear));
  }

  void onBackPressed() {
    if (_animationController.isCompleted) {
      _animationController.reverse();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.of(context).size;
    final maxCardTopMargin = size.height * .26;
    const double cardMargin = 40;

    _cardAnimation = RelativeRectTween(
      begin: RelativeRect.fromLTRB(
          cardMargin, maxCardTopMargin, cardMargin, cardMargin),
      end: const RelativeRect.fromLTRB(0, 80, 0, 0),
    ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.linear));
  }

  @override
  void dispose() {
    _backgroundPageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return WillPopScope(
      onWillPop: () async {
        if (_animationController.isCompleted) {
          onBackPressed();
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: Stack(
          children: [
            PageView.builder(
              itemCount: movies.length,
              controller: _backgroundPageController,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final item = movies[index];
                return ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
            AnimatedBuilder(
              animation: _cardAnimation,
              builder: (context, child) {
                return Positioned.fromRelativeRect(
                  rect: RelativeRect.fromLTRB(
                    _cardAnimation.value.left,
                    _cardAnimation.value.top,
                    _cardAnimation.value.right,
                    _cardAnimation.value.bottom,
                  ),
                  child: _MovieDetailsContent(
                    selectedMovie: selectedMovie,
                    animationValue: _animationController.value,
                    onBookMovie: onBook,
                  ),
                );
              },
            ),
            AnimatedBuilder(
              animation: _cardAnimation,
              child: BackButton(
                color: Colors.white,
                onPressed: onBackPressed,
              ),
              builder: (_, child) {
                return Positioned(
                  top: 26,
                  left: 0,
                  child: Visibility(
                    visible: _cardAnimation.isCompleted,
                    child: child!,
                  ),
                );
              },
            ),
            NotificationListener<ScrollUpdateNotification>(
              onNotification: (notification) {
                if (notification.depth == 0) {
                  if (_backgroundPageController.page != _pageController.page) {
                    _backgroundPageController.position.jumpTo(
                        _pageController.position.pixels /
                            moviesPageViewportFraction);
                  }
                }
                return false;
              },
              child: Positioned.fill(
                bottom: size.height * .4,
                child: Visibility(
                  visible: _showPosterListView,
                  maintainState: true,
                  child: PageView.builder(
                    itemCount: movies.length,
                    controller: _pageController,
                    onPageChanged: (i) {
                      selectedMovie = movies[i];
                      setState(() => _selectedIndex = i);
                    },
                    itemBuilder: (context, index) {
                      return AnimatedBuilder(
                          animation: _posterAnimation,
                          child: UnconstrainedBox(
                            constrainedAxis: Axis.horizontal,
                            child: Container(
                              height: 400,
                              margin:
                                  const EdgeInsets.only(right: 24, left: 24),
                              decoration: BoxDecoration(
                                  color: Colors.blueGrey,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [
                                    BoxShadow(
                                        offset: Offset(0, 26),
                                        color: Colors.black54,
                                        blurRadius: 16,
                                        spreadRadius: -12),
                                  ],
                                  image: DecorationImage(
                                      fit: BoxFit.cover,
                                      image: NetworkImage(
                                          movies[index].imageUrl))),
                            ),
                          ),
                          builder: (context, child) {
                            if (index != _selectedIndex) {
                              final padding = _animationController.value * 32.0;
                              return Padding(
                                padding: EdgeInsets.only(
                                  left: index > _selectedIndex ? padding : 0,
                                  right: index < _selectedIndex ? padding : 0,
                                ),
                                child: child,
                              );
                            }
                            return Transform(
                              transform: Matrix4(
                                1.0 - (1 * _animationController.value),
                                0.0,
                                0.0,
                                0.0,
                                0.0,
                                1 - (1 * _animationController.value),
                                0.0,
                                0.0,
                                0.0,
                                0.0,
                                1.0,
                                1.0 * 0.0015,
                                0.0,
                                0.0,
                                0.0,
                                1.0,
                              ).scaled(1.0, 1.0, .9)
                                ..rotateX(-(_posterAnimation.value * 1.7)
                                        .clamp(0, 90) *
                                    math.pi /
                                    180),
                              alignment: FractionalOffset(0.5,
                                  _animationController.value.clamp(0.0, 0.22)),
                              child: child,
                            );
                          });
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MovieDetailsContent extends StatefulWidget {
  final Movie selectedMovie;
  final double animationValue;
  final VoidCallback onBookMovie;

  const _MovieDetailsContent({
    required this.selectedMovie,
    required this.animationValue,
    required this.onBookMovie,
  });

  @override
  _MovieDetailsContentState createState() => _MovieDetailsContentState();
}

class _MovieDetailsContentState extends State<_MovieDetailsContent>
    with SingleTickerProviderStateMixin {
  Movie get selectedMovie => widget.selectedMovie;

  double get animationValue => widget.animationValue;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;

    final isMovieDetailsMode = animationValue >= 0.5;

    return Container(
      padding: EdgeInsets.only(top: 16 * animationValue),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8 - 8 * animationValue)),
      // TODO: fix eventual widget overflow issue on some devices
      child: Column(
        children: [
          AnimatedOpacity(
            opacity: animationValue,
            duration: Duration.zero,
            child: Column(
              children: [
                Text(
                  "screen".toUpperCase(),
                  style: textTheme.titleLarge!.copyWith(
                      fontSize: 32,
                      color: Colors.grey.withOpacity(.5),
                      fontWeight: FontWeight.w900),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: _SeatsCard(
                    rows: 8,
                    seatCount: 12,
                  ),
                ),
                const _SeatsCard(
                  rows: 3,
                  seatCount: 14,
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(40, animationValue * 32, 40, 0),
            child: Column(
              children: [
                Text(
                  selectedMovie.name,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium!.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                AnimatedOpacity(
                  opacity: 1 - animationValue,
                  duration: Duration.zero,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(
                          Icons.location_on,
                          color: Colors.deepPurple,
                        ),
                      ),
                      Text(
                        selectedMovie.theaterName,
                        style: textTheme.bodyMedium!.copyWith(
                          color: Colors.grey,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: size.width * .7,
            child: AnimatedCrossFade(
              crossFadeState: animationValue > 0.0
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: transitionDuration,
              firstChild: SizedBox(
                height: 95,
                child: CupertinoTheme(
                  data: const CupertinoThemeData(
                      textTheme: CupertinoTextThemeData(
                          dateTimePickerTextStyle:
                              TextStyle(fontWeight: FontWeight.w900))),
                  child: CupertinoDatePicker(
                    maximumDate: DateTime(2025, 12, 30),
                    minimumDate: DateTime.now(),
                    use24hFormat: true,
                    onDateTimeChanged: (date) {},
                  ),
                ),
              ),
              secondChild: _BookInfo(),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 16, bottom: 24 * animationValue),
            child: SizedBox(
              height: 54,
              width: size.width * .82,
              child: ElevatedButton(
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.pink),
                    textStyle: MaterialStateProperty.all(const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ))),
                onPressed: () => !isMovieDetailsMode
                    ? widget.onBookMovie()
                    : () {
                        // Pay button has been pressed.
                      },
                child: Text(isMovieDetailsMode ? 'Pay' : 'Book'),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _SeatsCard extends StatelessWidget {
  final int rows;
  final int seatCount;

  const _SeatsCard({Key? key, required this.rows, required this.seatCount})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(rows, (index) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(seatCount, (index) {
            return Container(
              height: 10,
              width: 10,
              margin: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      }),
    );
  }
}

class _BookInfo extends StatelessWidget {
  Widget _row(String title, String data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.grey),
        ),
        Text(
          data,
          style:
              const TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _row("DATE", "JUN 18"),
        const Divider(),
        //_row("TIME", "18:30"),
        //Divider(),
        _row("CINEMA", "Zap Cinemas"),
        const Divider(),
        _row("QUAINT.", "2 Tickets"),
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            '\$25.00',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
          ),
        )
      ],
    );
  }
}
