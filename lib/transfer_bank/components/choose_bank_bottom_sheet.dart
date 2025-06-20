import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:stardom/core/utils/constants/colors.dart';
import 'package:stardom/core/utils/constants/sizes.dart';
import 'package:stardom/core/utils/extensions/bank_extensions.dart';
import 'package:stardom/core/utils/extensions/context_extensions.dart';
import 'package:stardom/core/utils/extensions/language_extensions.dart';
import 'package:stardom/domain/entities/bank/bank.dart';
import 'package:stardom/presentation/widgets/input_field/custom_input.dart';

class ChooseBankBottomSheet extends StatefulWidget {
  final List<Bank> banks;

  const ChooseBankBottomSheet({super.key, required this.banks});

  @override
  ChooseBankBottomSheetState createState() => ChooseBankBottomSheetState();
}

class ChooseBankBottomSheetState extends State<ChooseBankBottomSheet> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    List<Bank> filteredBanks = widget.banks
        .where((bank) => context
            .strings()
            .bank(bankNames: bank.instNameInfo)
            .toLowerCase()
            .contains(searchQuery.toLowerCase()))
        .toList();

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        CustomInput(
          labelText: context.strings().choose_bank,
          labelInline: true,
          showInlineLabelWhenFocused: true,
          onChanged: (value) {
            setState(() {
              searchQuery = value ?? "";
            });
          },
          suffix: const Icon(
            Iconsax.bank,
            size: SSizes.iconMd,
            color: SColors.onSurfaceLight,
          ),
        ),
        SizedBox(
          height: size.height * 0.7,
          child: ListView.builder(
            itemCount: filteredBanks.length,
            itemBuilder: (context, index) {
              var bankItem = filteredBanks[index];
              return ListTile(
                leading: bankItem.logoImage != null
                    ? Image.memory(
                        bankItem.logoImage!,
                        height: SSizes.iconLg,
                        width: SSizes.iconLg,
                      )
                    : const Icon(
                        Iconsax.bank,
                        size: SSizes.iconLg,
                        color: SColors.onSurfaceLight,
                      ),
                title: bankItem.bic == 'MPesa'
                    ? Row(spacing: 10, children: [
                        Text(
                          context
                              .strings()
                              .bank(bankNames: bankItem.instNameInfo),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: SSizes.md, vertical: 2),
                          decoration: BoxDecoration(
                            color: SColors.primary.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(SSizes.borderRadiusLg),
                          ),
                          margin:
                              const EdgeInsets.symmetric(horizontal: SSizes.sm),
                          child: Text(context.strings().free,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium!
                                  .copyWith(color: SColors.primary)),
                        ),
                      ])
                    : Text(
                        context
                            .strings()
                            .bank(bankNames: bankItem.instNameInfo),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                onTap: () {
                  context.pop(bankItem);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
