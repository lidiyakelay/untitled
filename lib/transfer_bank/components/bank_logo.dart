import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:stardom/core/utils/constants/colors.dart';
import 'package:stardom/core/utils/constants/sizes.dart';

class BankLogo extends StatelessWidget {
  final Uint8List? logoImage;
  final double size;

  const BankLogo({super.key, required this.logoImage, required this.size});

  @override
  Widget build(BuildContext context) {
    return logoImage != null
        ? Image.memory(logoImage!, height: size, width: size)
        : const Icon(Iconsax.bank, size: SSizes.iconSm, color: SColors.onSurfaceLight);
  }
}
