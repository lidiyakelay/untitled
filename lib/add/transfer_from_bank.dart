import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:stardom/core/utils/constants/colors.dart';
import 'package:stardom/core/utils/constants/sizes.dart';
import 'package:stardom/core/utils/extensions/context_extensions.dart';
import 'package:stardom/presentation/widgets/base_screen.dart';

class TransferFromBankInfo extends StatelessWidget {
  const TransferFromBankInfo({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final minSize = min(size.height, size.width);

    return BaseScreen(
        title: Align(
          alignment: Alignment.center,
          widthFactor: 1,
          child: Text(context.strings().transfer_from_bank,
              textAlign: TextAlign.center, style: Theme.of(context).textTheme.displaySmall),
        ),
        leading: IconButton(
          padding: const EdgeInsets.only(left: SSizes.md),
          icon: const Icon(Iconsax.arrow_left, color: SColors.onSurface),
          onPressed: () => context.pop(),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: SSizes.lg,
            children: [
              const SizedBox.shrink(),
              Text(context.strings().move_money_steps,
                  textAlign: TextAlign.start, style: Theme.of(context).textTheme.bodySmall),
              Column(
                spacing: SSizes.md,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.strings().steps_section_title,
                      textAlign: TextAlign.start,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500)),
                  buildRow(
                    1,
                    context.strings().from_bank_step_one_title,
                    context.strings().from_bank_step_one_subtitle,
                    Theme.of(context).textTheme.bodySmall!,
                    minSize,
                  ),
                  buildRow(
                    2,
                    context.strings().from_bank_step_two_title,
                    context.strings().from_bank_step_two_subtitle,
                    Theme.of(context).textTheme.bodySmall!,
                    minSize,
                  ),
                  buildRow(
                    3,
                    context.strings().from_bank_step_three_title,
                    context.strings().from_bank_step_three_subtitle,
                    Theme.of(context).textTheme.bodySmall!,
                    minSize,
                  ),
                  buildRow(
                    4,
                    context.strings().from_bank_step_four_title,
                    context.strings().from_bank_step_four_subtitle,
                    Theme.of(context).textTheme.bodySmall!,
                    minSize,
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: SSizes.md, vertical: SSizes.sm),
                decoration: BoxDecoration(
                  color: SColors.primaryContainer,
                  borderRadius: BorderRadius.circular(SSizes.sm),
                ),
                // rich text child
                child: RichText(
                  textAlign: TextAlign.start,
                  text: TextSpan(
                    text: context.strings().note,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: SColors.onSurfaceDark),
                    children: [
                      TextSpan(
                        text: ':\n',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      TextSpan(
                        text: context.strings().note_description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ));
  }
}

Widget buildRow(int rowNumber, String title, String subtitle, TextStyle style, double minSize) {
  return Padding(
    padding: const EdgeInsets.only(left: SSizes.sm),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: SSizes.sm,
      children: [
        Text('$rowNumber.',
            textAlign: TextAlign.start,
            style: style.copyWith(color: SColors.onSurfaceDark, fontWeight: FontWeight.w500)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: SSizes.xs,
          children: [
            Text(title,
                textAlign: TextAlign.start,
                style: style.copyWith(color: SColors.onSurfaceDark, fontWeight: FontWeight.w500)),
            SizedBox(
              width: minSize * 0.8,
              child: Text(
                subtitle,
                textAlign: TextAlign.start,
                style: style,
                maxLines: 3,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
