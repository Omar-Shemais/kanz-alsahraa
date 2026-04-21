import 'package:flutter/material.dart';

import '../../../generated/l10n.dart';
import 'countdown_timer.dart';
import 'helper.dart';

class HeaderView extends StatelessWidget {
  final String? headerText;
  final VoidCallback? callback;
  final bool showSeeAll;
  final bool showCountdown;
  final Duration countdownDuration;
  final double? verticalMargin;
  final double? horizontalMargin;
  final ScrollController? scrollController;

  const HeaderView({
    this.headerText,
    this.showSeeAll = false,
    super.key,
    this.callback,
    this.verticalMargin = 6.0,
    this.horizontalMargin,
    this.showCountdown = false,
    this.countdownDuration = const Duration(),
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    var isDesktop = Layout.isDisplayDesktop(context);

    return SizedBox(
      width: screenSize.width,
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        padding: EdgeInsets.only(
          left: horizontalMargin ?? 18.0,
          top: 8.0,
          right: horizontalMargin ?? 18.0,
          bottom: 12.0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // Title on the Start (Right in RTL)
            Expanded(
              flex: 10,
              child: Column(
                mainAxisSize: MainAxisSize.min, // Shrink to content
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Start = Right in RTL
                children: [
                  Text(
                    headerText ?? '',
                    style: isDesktop
                        ? Theme.of(context).textTheme.headlineSmall!.copyWith(
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            )
                        : Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: Colors.black,
                            ),
                  ),
                  if (showCountdown) const SizedBox(height: 2),
                  if (showCountdown)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          S.of(context).endsIn('').toUpperCase(),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondary
                                    .withOpacity(0.8),
                              )
                              .apply(fontSizeFactor: 0.6),
                        ),
                        CountDownTimer(countdownDuration),
                      ],
                    ),
                ],
              ),
            ),
            // "See All" on the End (Left in RTL)
            if (showSeeAll)
              InkResponse(
                onTap: callback,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4.0,
                    horizontal: 8.0,
                  ),
                  child: Text(
                    S.of(context).seeAll,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: const Color(0xFFB18729),
                          fontWeight: FontWeight.w600,
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
