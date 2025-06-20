import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iconsax/iconsax.dart';
import 'package:stardom/core/utils/constants/colors.dart';
import 'package:stardom/core/utils/constants/constants.dart';
import 'package:stardom/core/utils/constants/sizes.dart';
import 'package:stardom/core/utils/extensions/bank_extensions.dart';
import 'package:stardom/core/utils/extensions/context_extensions.dart';
import 'package:stardom/core/utils/extensions/date_formatter.dart';
import 'package:stardom/core/utils/extensions/string_extensions.dart';
import 'package:stardom/data/datasources/local/transaction_local_data_source.dart';
import 'package:stardom/domain/entities/bank/bank.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onTap;
  final Bank? bank;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.onTap,
    this.bank,
  });

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.sizeOf(context);
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: SSizes.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SSizes.borderRadiusMd),
      ),
      leading: bank != null && bank!.logoImage != null
          ? CircleAvatar(
              radius: 25,
              backgroundImage: MemoryImage(bank!.logoImage!),
              backgroundColor: Colors.transparent,
            )
          : transaction.type == 'Bank'
              ? const CircleAvatar(
                  radius: 25,
                  backgroundColor: SColors.softGrey,
                  child: Icon(Iconsax.bank,
                      size: SSizes.iconSm, color: SColors.onSurfaceLight),
                )
              : CircleAvatar(
                  radius: 25,
                  backgroundColor: SColors.softGrey,
                  child: SvgPicture.asset(
                    Assets.mpesaRed,
                    height: size.height * 0.045,
                  ),
                ),
      title: Text(
        transaction.receiverParty.capitalizeWords(),
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: SColors.onSurfaceDarkest),
      ),
      subtitle: Text(
        transaction.type == 'Bank'
            ? transaction.receiverId.split(":").last
            : "251 ${transaction.receiverId.formatPhoneNumber()}",
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 3,
        children: [
          Text(
            (transaction.isDeducted ? "- " : "+ ") +
                transaction.amount.toString().formatCurrency(),
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: SColors.onSurfaceDarkest),
          ),
          Text(
            transaction.createdAt?.toReadableDate() ?? "",
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
