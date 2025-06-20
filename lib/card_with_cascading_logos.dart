import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stardom/core/utils/constants/colors.dart';
import 'package:stardom/core/utils/constants/sizes.dart';
import 'package:stardom/presentation/widgets/buttons/text_button.dart';

class CardWithCascadingLogos extends StatelessWidget {
  final String titleIcon;
  final String title;
  final String subtitle;
  final List<String> logoAssets;
  final String learnHowText;
  final VoidCallback onLearnHow;

  const CardWithCascadingLogos({
    super.key,
    required this.titleIcon,
    required this.title,
    required this.subtitle,
    required this.logoAssets,
    required this.learnHowText,
    required this.onLearnHow,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final minSize = min(size.height, size.width);

    return Container(
      decoration: BoxDecoration(
        color: SColors.surfaceContainer,
        borderRadius: BorderRadius.circular(SSizes.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(SSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: SSizes.sm,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              spacing: SSizes.sm,
              children: [
                titleIcon.endsWith('.svg')
                    ? SvgPicture.asset(
                        titleIcon,
                        width: minSize * 0.08,
                        height: minSize * 0.08,
                      )
                    : Image.asset(
                        titleIcon,
                        width: minSize * 0.08,
                        height: minSize * 0.08,
                        fit: BoxFit.contain,
                      ),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: SColors.onSurfaceDark),
                ),
              ],
            ),
            const SizedBox(height: SSizes.xs),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: SSizes.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: minSize * 0.08,
                  width: minSize * 0.5,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (int i = 0; i < logoAssets.length.clamp(0, 5); i++)
                        Positioned(
                          left: i * 18, // adjust this for more or less overlap
                          child: SizedBox(
                            width: minSize * 0.06,
                            height: minSize * 0.06,
                            child: CircleAvatar(
                              radius: minSize * 0.06,
                              backgroundImage: AssetImage(logoAssets[i]),
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ),
                      if (logoAssets.length > 5)
                        Positioned(
                          left: 5 * 18,
                          child: Container(
                            width: minSize * 0.06,
                            height: minSize * 0.06,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: SColors.onSurfaceContainer,
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "+15",
                                // "+${logoAssets.length - 5}",
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                STextButton(
                  text: learnHowText,
                  onPressed: onLearnHow,
                  textColor: SColors.primary,
                  enabled: true,
                  wrap: true,
                  analyticsButtonName: 'add_money_learn_how',
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
