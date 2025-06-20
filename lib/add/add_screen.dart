import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:stardom/app/routes/app_routes.dart';
import 'package:stardom/core/utils/constants/colors.dart';
import 'package:stardom/core/utils/constants/constants.dart';
import 'package:stardom/core/utils/constants/sizes.dart';
import 'package:stardom/core/utils/extensions/context_extensions.dart';
import 'package:stardom/presentation/widgets/base_screen.dart';
import 'package:stardom/presentation/widgets/cards/card_with_cascading_logos.dart';

class AddScreen extends StatelessWidget {
  const AddScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final abroadServices = [
      Assets.dahabshiil,
      Assets.terra,
      Assets.thunes,
      Assets.onafriq,
    ];
    final banks = [
      Assets.hibret,
      Assets.dashen,
      Assets.abyssiniya,
      Assets.awash,
      Assets.cbe,
      Assets.zemen,
    ];

    return BaseScreen(
        title: Align(
          alignment: Alignment.center,
          widthFactor: 1,
          child: Text(context.strings().add_money,
              textAlign: TextAlign.center, style: Theme.of(context).textTheme.displaySmall),
        ),
        leading: IconButton(
          padding: const EdgeInsets.only(left: SSizes.md),
          icon: const Icon(Iconsax.arrow_left, color: SColors.onSurface),
          onPressed: () => context.pop(),
        ),
        content: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          spacing: SSizes.md,
          children: [
            CardWithCascadingLogos(
              titleIcon: Assets.pay,
              title: context.strings().transfer_from_bank,
              subtitle: context.strings().transfer_from_bank_subtitle,
              logoAssets: banks,
              learnHowText: context.strings().learn_how,
              onLearnHow: () => context.pushNamed(AppRoutes.transferBankInfo),
            ),
            CardWithCascadingLogos(
              titleIcon: Assets.receiveAbroad,
              title: context.strings().receive_from_abroad,
              subtitle: context.strings().receive_from_abroad_subtitle,
              logoAssets: abroadServices,
              learnHowText: context.strings().learn_how,
              onLearnHow: () => context.pushNamed(AppRoutes.receiveAbroadInfo),
            ),
          ],
        ));
  }
}
