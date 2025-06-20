import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:stardom/core/utils/constants/colors.dart';
import 'package:stardom/core/utils/constants/constants.dart';
import 'package:stardom/core/utils/constants/sizes.dart';
import 'package:stardom/core/utils/extensions/context_extensions.dart';
import 'package:stardom/presentation/widgets/base_screen.dart';
import 'package:stardom/presentation/widgets/cards/accordion_steps.dart';
import 'package:stardom/presentation/widgets/cards/accordion_table.dart';

class ReceiveFromAbroadInfo extends StatelessWidget {
  const ReceiveFromAbroadInfo({super.key});

  @override
  Widget build(BuildContext context) {
    List<String> cashgoSteps = [
      context.strings().cashgo_step_one,
      context.strings().cashgo_step_two,
      context.strings().cashgo_step_three,
      context.strings().cashgo_step_four,
      context.strings().cashgo_step_five,
      context.strings().cashgo_step_six,
      context.strings().cashgo_step_seven,
    ];

    List<String> safSteps = [
      context.strings().safari_kenya_step_one,
      context.strings().safari_kenya_step_two,
      context.strings().safari_kenya_step_three,
      context.strings().safari_kenya_step_four,
      context.strings().safari_kenya_step_five,
      context.strings().safari_kenya_step_six,
    ];

    List<String> remitlySteps = [
      context.strings().remitly_step_one,
      context.strings().remitly_step_two,
      context.strings().remitly_step_three,
      context.strings().remitly_step_four,
      context.strings().remitly_step_five,
      context.strings().remitly_step_six,
      context.strings().remitly_step_seven,
      context.strings().remitly_step_eight,
      context.strings().remitly_step_nine,
      context.strings().remitly_step_ten,
      context.strings().remitly_step_eleven,
      context.strings().remitly_step_twelve,
      context.strings().remitly_step_thirteen,
      context.strings().remitly_step_fourteen,
    ];

    List<String> dahabshiilSteps = [
      context.strings().dahabshiil_step_one,
      context.strings().dahabshiil_step_two,
      context.strings().dahabshiil_step_three,
      context.strings().dahabshiil_step_four,
      context.strings().dahabshiil_step_five,
      context.strings().dahabshiil_step_six,
      context.strings().dahabshiil_step_seven,
      context.strings().dahabshiil_step_eight,
      context.strings().dahabshiil_step_nine,
    ];

    List<AccordionTableRow> otherPartners = [
      AccordionTableRow(partner: 'iDT (Boss Money)', country: 'US'),
      AccordionTableRow(partner: 'GME', country: 'Korea'),
      AccordionTableRow(partner: 'G-Money Trans', country: 'Korea'),
      AccordionTableRow(partner: 'Capital Services', country: 'App'),
      AccordionTableRow(partner: 'BNB transfer', country: 'US and Canada'),
      AccordionTableRow(partner: 'Paysend', country: 'US, UK, Canada and Europe'),
      AccordionTableRow(partner: 'ClickSend', country: 'Most African Countries'),
      AccordionTableRow(partner: 'Batelco Financial Services', country: 'Bahrain'),
      AccordionTableRow(partner: 'BFC Bahrain', country: 'Bahrain'),
      AccordionTableRow(partner: 'NAFEX', country: 'Bahrain'),
      AccordionTableRow(partner: 'AL Mulla Exchange', country: 'Kuwait'),
      AccordionTableRow(partner: 'Bin Yaala Exchange', country: 'UAE'),
      AccordionTableRow(partner: 'Lulu Exchange Company WLL-Oman', country: 'Oman'),
      AccordionTableRow(partner: 'Unimoni Qatar', country: 'Qatar'),
      AccordionTableRow(partner: 'Unimoni Oman', country: 'Oman'),
    ];

    return BaseScreen(
        title: Align(
          alignment: Alignment.center,
          widthFactor: 1,
          child: Text(context.strings().receive_from_abroad,
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
              Text(
                context.strings().major_partners,
                textAlign: TextAlign.start,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
              ),
              Column(
                spacing: SSizes.md,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AccordionSteps(
                    item: AccordionStepsItem(
                      header: context.strings().cash_go,
                      headerIconAsset: Assets.cashgo,
                      steps: cashgoSteps,
                      website: 'https://www.cashgoethiopia.com',
                    ),
                  ),
                  AccordionSteps(
                    item: AccordionStepsItem(
                      header: context.strings().safari_kenya,
                      headerIconAsset: Assets.safariKenya,
                      steps: safSteps,
                      website: 'https://www.safaricom.co.ke',
                    ),
                  ),
                  AccordionSteps(
                    item: AccordionStepsItem(
                      header: context.strings().remitly,
                      headerIconAsset: Assets.remitly,
                      steps: remitlySteps,
                      website: 'https://www.remitly.com',
                    ),
                  ),
                  AccordionSteps(
                    item: AccordionStepsItem(
                      header: context.strings().dahabshiil,
                      headerIconAsset: Assets.dahabshiil,
                      steps: dahabshiilSteps,
                      website: 'https://www.dahabshiil.com',
                    ),
                  ),
                  AccordionTable(
                    item: AccordionTableItem(
                      title: context.strings().other_partners,
                      header: AccordionTableRow(
                        partner: context.strings().partner,
                        country: context.strings().country,
                      ),
                      body: otherPartners,
                    ),
                  )
                ],
              )
            ],
          ),
        ));
  }
}
