import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/utils/constants/colors.dart';
import '../../core/utils/constants/sizes.dart';
import 'buttons/primary_button.dart';
import 'buttons/secondary_button.dart';

class CustomDialogBox extends StatelessWidget {
  final String dialogTitle;
  final String? dialogDescription;
  final PrimaryButton? primaryButton;
  final SecondaryButton? secondaryButton;
  final String? svgIconPath;
  final Color? svgIconColor;
  final bool? showCloseIcon;

  const CustomDialogBox(
      {super.key,
      required this.dialogTitle,
      this.dialogDescription,
      this.primaryButton,
      this.secondaryButton,
      this.svgIconPath,
      this.svgIconColor,
      this.showCloseIcon = true});

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.sizeOf(context);
    double logoWidth = min(size.width, size.height) * 0.20;
    double titlePadding = min(size.width, size.height) * 0.14;
    double descriptionPadding = min(size.width, size.height) * 0.06;

    return WillPopScope(
      onWillPop: () async {
        return false; // Prevent back button press to close the dialog
      },
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SSizes.borderRadiusMd),
        ),
        contentPadding: EdgeInsets.zero,
        insetPadding: const EdgeInsets.all(SSizes.md),
        content: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(SSizes.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (svgIconPath != null) ...[
                SizedBox(
                  width: logoWidth,
                  height: logoWidth,
                  child: SvgPicture.asset(
                    svgIconPath!,
                    colorFilter: svgIconColor != null
                        ? ColorFilter.mode(svgIconColor!, BlendMode.srcIn)
                        : null,
                  ),
                ),
                const SizedBox(height: SSizes.sm),
              ] else if (svgIconPath == null && showCloseIcon!)
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(
                      Iconsax.close_circle,
                      color: SColors.onSurface,
                    ),
                    onPressed: () {
                      context.pop();
                    },
                  ),
                ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: titlePadding),
                child: Text(
                  dialogTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: SSizes.md),
              if (dialogDescription != null) ...[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: descriptionPadding),
                  child: Text(
                    dialogDescription!,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: SSizes.md),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (secondaryButton != null) ...[
                    Expanded(child: secondaryButton!),
                    const SizedBox(
                      width: SSizes.sm,
                    )
                  ],
                  if (primaryButton != null) ...[
                    Expanded(child: primaryButton!),
                  ],
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
