import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:stardom/app/di/injector.dart';
import 'package:stardom/app/routes/app_routes.dart';
import 'package:stardom/core/utils/constants/colors.dart';
import 'package:stardom/core/utils/constants/constants.dart';
import 'package:stardom/core/utils/constants/sizes.dart';
import 'package:stardom/core/utils/extensions/bank_extensions.dart';
import 'package:stardom/core/utils/extensions/context_extensions.dart';
import 'package:stardom/core/utils/extensions/date_formatter.dart';
import 'package:stardom/core/utils/extensions/string_extensions.dart';
import 'package:stardom/data/datasources/local/transaction_local_data_source.dart';
import 'package:stardom/domain/entities/auth/user_data.dart';
import 'package:stardom/domain/entities/bank/bank.dart';
import 'package:stardom/domain/entities/bank/bank_transfer.dart';
import 'package:stardom/domain/repositories/auth_repository.dart';
import 'package:stardom/presentation/controllers/login/login_auth_viewmodel.dart';
import 'package:stardom/presentation/state_management/bank/bank_bloc.dart';
import 'package:stardom/presentation/widgets/base_screen.dart';
import 'package:stardom/presentation/widgets/buttons/primary_button.dart';
import 'package:stardom/presentation/widgets/custom_dialog_box.dart';
import 'package:stardom/presentation/widgets/input_field/custom_pin_input.dart';

class TransferBankConfirm extends StatefulWidget {
  final BankTransfer transferRequest;

  const TransferBankConfirm({super.key, required this.transferRequest});

  @override
  TransferBankConfirmState createState() => TransferBankConfirmState();
}

class TransferBankConfirmState extends State<TransferBankConfirm> {
  var pinController = TextEditingController();
  List<Bank> banks = [];
  late User user;

  @override
  void initState() {
    super.initState();
    _initiateUser();
    context.read<BankBloc>().add(FetchBanks(forceRefresh: false));
  }

  @override
  void dispose() {
    context.hideLoading();
    super.dispose();
  }

  void _initiateUser() async {
    user = (await sl<AuthRepository>().getLocalUser())!;
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.sizeOf(context);
    final LoginAuthViewModel loginAuthViewModel = LoginAuthViewModel();

    void initiateTransfer() {
      context.read<BankBloc>().add(TransferRequested(widget.transferRequest));
    }

    return BaseScreen(
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(context.strings().confirm_transfer,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall),
        ),
        leading: IconButton(
          padding: const EdgeInsets.only(left: SSizes.md),
          icon: const Icon(Iconsax.arrow_left, color: SColors.onSurface),
          onPressed: () => context.pop(),
        ),
        content: BlocListener<BankBloc, BankState>(
            listener: (context, state) {
              if (state is BankLoading) {
                context.showLoading();
              } else if (state is BankListLoaded) {
                setState(() {
                  banks = state.banks;
                });
              } else if (state is TransferSuccess) {
                var timestamp = DateTime.now();
                final transactionDataSource = sl<TransactionLocalDataSource>();
                transactionDataSource.addTransaction(Transaction(
                    receiverParty: widget.transferRequest.recipientName,
                    receiverId:
                        "${widget.transferRequest.bank.instType == InstitutionType.direct ? widget.transferRequest.bank.shortcode : widget.transferRequest.bank.bic}:${widget.transferRequest.accountNumber}",
                    type: 'Bank',
                    amount: widget.transferRequest.amount.toDouble(),
                    createdAt: timestamp,
                    isDeducted: true));

                if (state.responseCode == "SVC0437") {
                  context.showDialogBox(CustomDialogBox(
                    svgIconPath: Assets.pending,
                    showCloseIcon: false,
                    dialogTitle: context.strings().transaction_pending_title,
                    dialogDescription:
                        context.strings().transaction_pending_desc,
                    primaryButton: PrimaryButton(
                      enabled: true,
                      text: context.strings().close_button,
                      analyticsButtonName: "indirect_bank_pending_close",
                      onPressed: () {
                        if (mounted) {
                          context.pop();
                          context.goNamed(
                            AppRoutes.homeScreen,
                            extra: {'key': UniqueKey()},
                          );
                        }
                      },
                    ),
                  ));
                } else {
                  Map<String, dynamic> transactionData = {
                    "totalAmount": widget.transferRequest.amount +
                        widget.transferRequest.transactionFee,
                    "transactionData": {
                      "Transaction Type": "M-PESA to Bank Transfer",
                      "Sender Name": user.name,
                      "Sender Phone No.":
                          "+251 ${user.msisdn.formatPhoneNumber()}",
                      "Recipient's Bank Name": widget
                          .transferRequest.bank.instNameInfo
                          .firstWhere((name) => name.key == 'en',
                              orElse: () => widget
                                  .transferRequest.bank.instNameInfo.first)
                          .value,
                      "Recipient's Bank Account":
                          widget.transferRequest.accountNumber,
                      "Account Holder Name":
                          widget.transferRequest.recipientName,
                      "Amount": widget.transferRequest.amount.toString(),
                      "Transaction Fee":
                          widget.transferRequest.transactionFee.toString(),
                      "Transaction ID": state.transactionID,
                      "Date and time": timestamp.toReceiptDate(),
                    }
                  };
                  context.pushNamed(AppRoutes.receipt,
                      extra: transactionData,
                      queryParameters: {'reasonTypeId': '10000027'});
                }
              } else if (state is TransferFailure) {
                context.hideLoading();
                context.showDialogBox(CustomDialogBox(
                  dialogTitle: context.strings().transfer_fail,
                  primaryButton: PrimaryButton(
                    text: context.strings().close_button,
                    enabled: true,
                    onPressed: () {
                      context.pop();
                      context.pop();
                    },
                    analyticsButtonName: 'transfer_bank_confirm_close_dialog',
                  ),
                ));
              }
              if (state is! BankLoading) {
                context.hideLoading();
              }
            },
            child: Column(
              spacing: SSizes.md,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: size.height * 0.05),
                  child: Center(
                    child: SizedBox(
                      height: size.height * 0.05,
                      child: widget.transferRequest.bank.logoImage != null
                          ? CircleAvatar(
                              backgroundColor: Colors.transparent,
                              backgroundImage: MemoryImage(
                                  widget.transferRequest.bank.logoImage!),
                              radius: SSizes.iconMd,
                            )
                          : const Icon(
                              Iconsax.bank,
                              size: SSizes.iconMd,
                            ),
                    ),
                  ),
                ),
                Column(
                  spacing: SSizes.sm,
                  children: [
                    Text(
                      widget.transferRequest.recipientName,
                      style: Theme.of(context)
                          .textTheme
                          .headlineLarge
                          ?.copyWith(color: SColors.onSurfaceDark),
                    ),
                    Text(widget.transferRequest.accountNumber,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                                color: SColors.onSurface,
                                fontWeight: FontWeight.normal)),
                  ],
                ),
                Column(
                  children: [
                    Text.rich(
                      TextSpan(
                        text: context.strings().you_transferring,
                        style: Theme.of(context).textTheme.bodyLarge,
                        children: [
                          const TextSpan(text: ' : '),
                          TextSpan(
                            text: widget.transferRequest.amount
                                .toString()
                                .formatCurrency(),
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(color: SColors.primary),
                          ),
                          TextSpan(
                            text: ' ${context.strings().birr}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(color: SColors.primary),
                          ),
                        ],
                      ),
                    ),
                    Text.rich(
                      TextSpan(
                        text: context.strings().transaction_fee,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: SColors.onSurfaceLight),
                        children: [
                          const TextSpan(text: ' : '),
                          TextSpan(
                            text: widget.transferRequest.transactionFee
                                .toString()
                                .formatCurrency(),
                          ),
                          const TextSpan(text: ' '),
                          TextSpan(
                            text: context.strings().birr,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: size.height * 0.01),
                Text(context.strings().enter_pin_confirm,
                    style: Theme.of(context).textTheme.bodySmall),
                CustomPinInput(
                  enabled: true,
                  pinLength: 4,
                  maxAttempt: 3,
                  pinController: pinController,
                  pinValidator: (pin) async {
                    context.showLoading();
                    var pinValid = await loginAuthViewModel.validatePin(
                        msisdn: user.msisdn.normalizeMsisdn(), pin: pin ?? '');
                    if (!pinValid) {
                      if (context.mounted) context.hideLoading();
                    }
                    return pinValid
                        ? null
                        : context.mounted
                            ? context.strings().error_incorrect_pin
                            : '';
                  },
                  onPinVerified: () {
                    initiateTransfer();
                  },
                  onBiometricAuth: (isAuthenticated, errorMessage) {
                    if (isAuthenticated) {
                      initiateTransfer();
                    } else {
                      if (errorMessage != null) {
                        context.showSnackBar(
                          errorMessage,
                          textColor: SColors.white,
                          backgroundColor: SColors.surfaceContainerError,
                        );
                      }
                    }
                  },
                ),
                SizedBox(height: size.height * 0.001),
              ],
            )));
  }
}
