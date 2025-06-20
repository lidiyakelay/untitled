import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:stardom/app/routes/app_routes.dart';
import 'package:stardom/core/utils/extensions/context_extensions.dart';
import 'package:stardom/core/utils/extensions/date_formatter.dart';
import 'package:stardom/core/utils/extensions/string_extensions.dart';
import 'package:stardom/data/datasources/local/transaction_local_data_source.dart';
import 'package:stardom/domain/entities/common/account_info.dart';
import 'package:stardom/domain/entities/send_money/send_money_entity.dart';
import 'package:stardom/domain/entities/send_money/send_money_response_entity.dart';
import 'package:stardom/domain/repositories/auth_repository.dart';
import 'package:stardom/domain/usecases/auth/validate_pin_usecase.dart';
import 'package:stardom/presentation/state_management/send_money/send_money_event.dart';
import 'package:stardom/presentation/widgets/base_screen.dart';
import 'package:stardom/presentation/widgets/cards/transaction_avatar.dart';
import 'package:stardom/presentation/widgets/custom_dialog_box.dart';

import '../../../../app/di/injector.dart';
import '../../../../core/utils/constants/colors.dart';
import '../../../../core/utils/constants/constants.dart';
import '../../../../core/utils/constants/sizes.dart';
import '../../../../core/utils/encryption/pin_encryption.dart';
import '../../../../domain/entities/auth/encrypted_pin.dart';
import '../../../../domain/entities/auth/user_data.dart';
import '../../../state_management/send_money/send_money_bloc.dart';
import '../../../state_management/send_money/send_money_state.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../../../widgets/input_field/custom_pin_input.dart';
import '../../home/home.dart';

class ConfirmTransactionScreen extends StatefulWidget {
  final String identityFullName;
  final String id;
  final String channelSessionId;
  final double amount;
  final String remark;
  final double transactionFee;
  final bool useOD;
  final AccountInfoTypes selectedAccount;

  const ConfirmTransactionScreen({
    super.key,
    required this.id,
    required this.identityFullName,
    required this.channelSessionId,
    required this.amount,
    required this.remark,
    required this.transactionFee,
    required this.useOD,
    required this.selectedAccount,
  });

  @override
  State<ConfirmTransactionScreen> createState() =>
      _ConfirmTransactionScreenState();
}

class _ConfirmTransactionScreenState extends State<ConfirmTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final userRepository = sl<AuthRepository>();
  final TextEditingController _otpController = TextEditingController();
  bool _isOtpCorrect = true;
  bool _isOtpChecked = false;
  String? errorMessage;
  String correctPin = '4321';
  int attempts = 0;

  bool isSuccess = false;
  bool isLoading = false;

  void _validatePin(String pin) async {
    context.showLoading();
    var encryptedPin = await PinEncryption.encryptPin(pin: pin);

    var pinResponse = await sl<ValidatePinUseCase>().execute(user.msisdn, pin);

    setState(() {
      _isOtpChecked = true;
      // TODO validate on backend
      _isOtpCorrect = pinResponse.isValid;
    });

    if (_isOtpCorrect) {
      sendMoney(encryptedPin);
    } else {
      if (!mounted) return;
      context.hideLoading();
      setState(() {
        errorMessage = context.strings().wrong_pin;
        attempts++;
      });
    }
  }

  sendMoney(EncryptedPin encryptedPin) {
    widget.id.length >= 9
        ? BlocProvider.of<SendMoneyBloc>(context).add(SendMoneyPayEvent(
            SendMoneyEntity(
                primaryParty: user.msisdn,
                receiverParty: widget.id,
                securityCredential: encryptedPin.securityCredential,
                secretKey: encryptedPin.secretKey,
                amount: widget.amount.toString(),
                channelSessionID: widget.channelSessionId,
                remark: widget.remark)))
        : BlocProvider.of<SendMoneyBloc>(context).add(PayForMerchantEvent(
            SendMoneyEntity(
                primaryParty: user.msisdn,
                useOD: widget.useOD,
                receiverParty: widget.id,
                securityCredential: encryptedPin.securityCredential,
                secretKey: encryptedPin.secretKey,
                amount: widget.amount.toString(),
                channelSessionID: widget.channelSessionId,
                remark: widget.remark,
                selectedAccount: widget.selectedAccount)));
  }

  showSuccessDialog(SendMoneyResponseEntity data) {
    context.showDialogBox(CustomDialogBox(
      svgIconPath: Assets.success,
      svgIconColor: SColors.success,
      dialogTitle: context.strings().transfer_success,
      primaryButton: PrimaryButton(
        text: context.strings().close_button,
        enabled: true,
        onPressed: () {
          saveTransactionAndShowReceipt(data.transactionID ?? '', widget.id);
        },
        analyticsButtonName: "send_money_success_dialog_close",
      ),
    ));
  }

  saveTransactionAndShowReceipt(String transactionId, String id) {
    final transactionDataSource = sl<TransactionLocalDataSource>();
    if (id.length >= 9) {
      transactionDataSource
          .addTransaction(Transaction(
              receiverParty: widget.identityFullName,
              receiverId: widget.id,
              type: 'M-PESA',
              amount: widget.amount,
              isDeducted: true))
          .then((value) {
        showReceipt(transactionId);
      });
    } else {
      transactionDataSource
          .addTransaction(Transaction(
              receiverParty: widget.identityFullName,
              receiverId: widget.id,
              type: 'M-PESA-MERCHANT',
              amount: widget.amount,
              isDeducted: true))
          .then((value) {
        showReceipt(transactionId);
      });
    }
  }

  var timestamp = DateTime.now();

  showReceipt(String? transactionId) {
    Map<String, dynamic> transactionData = {
      "totalAmount": widget.amount + widget.transactionFee,
      "transactionData": {
        "Transaction Type":
            "${widget.id.length >= 9 ? "Individual" : "Merchant"} Transfer",
        "Payer’s Name": user.name,
        "Payer’s Phone No.": "+251 ${user.msisdn.formatPhoneNumber()}",
        "Recipient’s Name": widget.identityFullName,
        "Recipient’s Phone No.": widget.id.length >= 9
            ? "+251 ${widget.id.normalizeMsisdn().formatPhoneNumber()}"
            : widget.id,
        "Amount Paid": widget.amount.toString().formatCurrency(),
        "Transaction Fee": widget.transactionFee.toString().formatCurrency(),
        "VAT":
            (0.15 * widget.amount).floorToDouble().toString().formatCurrency(),
        "Transaction ID": transactionId ?? '',
        "Date and time": timestamp.toReceiptDate(),
      }
    };
    if (widget.id.length >= 9) {
      context.pushNamed(AppRoutes.receipt,
          extra: transactionData,
          queryParameters: {'reasonTypeId': '10000097'});
    } else {
      context.pushNamed(AppRoutes.receipt,
          extra: transactionData,
          queryParameters: {'reasonTypeId': '10000059'});
    }
  }

  late User user;

  @override
  void initState() {
    super.initState();
    _initiateUser();
  }

  void _initiateUser() async {
    final localUser = (await sl<AuthRepository>().getLocalUser())!;
    setState(() {
      user = localUser;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return BlocListener<SendMoneyBloc, SendMoneyState>(
      listenWhen: (previous, current) {
        return ModalRoute.of(context)?.isCurrent ?? false;
      },
      listener: (context, state) {
        if (state is SendMoneyLoading) {
          context.showLoading();
        }
        if (state is SendMoneyPaySuccess) {
          context.hideLoading();
          var transactionEntry = state.data.additionalInfo
              .firstWhere((element) => element.key == "TransactionID");
          saveTransactionAndShowReceipt(transactionEntry.value, widget.id);
          setState(() {
            errorMessage = null;
          });
        }
        if (state is PayForMerchantSuccess) {
          context.hideLoading();
          var transactionEntry = state.data.additionalInfo
              .firstWhere((element) => element.key == "TransactionID");
          saveTransactionAndShowReceipt(transactionEntry.value, widget.id);
          setState(() {
            errorMessage = null;
          });
        }
        if (state is SendMoneyPayFailure) {
          context.hideLoading();
          context.showDialogBox(CustomDialogBox(
            dialogTitle: state.error,
            primaryButton: PrimaryButton(
                text: context.strings().retry_button,
                onPressed: () {
                  context.goNamed(
                    AppRoutes.homeScreen,
                  );
                },
                enabled: true,
                analyticsButtonName: "send_money_failure_dialog_retry"),
          ));
        }
        if (state is PayForMerchantFailure) {
          context.hideLoading();
          context.showDialogBox(CustomDialogBox(
            dialogTitle: state.error,
            primaryButton: PrimaryButton(
                text: context.strings().retry_button,
                onPressed: () {
                  context.goNamed(
                    AppRoutes.homeScreen,
                  );
                },
                enabled: true,
                analyticsButtonName: "pay_merchant_failure_dialog_retry"),
          ));
        }
      },
      child: BaseScreen(
        allowResize: false,
        title: Row(
          spacing: SSizes.appBarHeight / 1.2,
          children: [
            IconWidget(
              icon: Iconsax.arrow_left,
              iconColor: SColors.onSurface,
              onTap: () {
                context.pop();
              },
              iconSize: SSizes.lg,
              backgroundColor: SColors.onSurfaceLightest,
              showbackground: true,
            ),
            Text(context.strings().confirm_transaction,
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        content: Form(
          key: _formKey,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: Column(
              children: [
                SizedBox(
                  height: size.height * 0.02,
                ),
                TransactionAvatar(title: widget.identityFullName),
                Text(widget.identityFullName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: SSizes.fontSizeLg,
                        fontWeight: FontWeight.w500)),
                const SizedBox(
                  height: 5,
                ),
                Text(widget.id, style: Theme.of(context).textTheme.labelMedium),
                SizedBox(height: size.height * 0.02),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: widget.id.length >= 9
                            ? context.strings().you_transferring
                            : context.strings().you_paying,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      TextSpan(
                        text:
                            ' ${widget.amount.toString().formatCurrency()} ${context.strings().birr}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge!
                            .copyWith(color: SColors.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: context.strings().transaction_fee,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      TextSpan(
                        text:
                            ' ${widget.transactionFee.toString().formatCurrency()}'
                            ' ${context.strings().birr}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: size.height * 0.04),
                Text(context.strings().enter_pin_confirm,
                    style: Theme.of(context).textTheme.bodySmall),
                SizedBox(height: size.height * 0.01),
                CustomPinInput(
                  enabled: true,
                  pinLength: 4,
                  maxAttempt: 3,
                  pinController: _otpController,
                  pinValidator: (pin) async {
                    context.showLoading();
                    bool isValid;
                    try {
                      var pinResponse = await sl<ValidatePinUseCase>()
                          .execute(user.msisdn, pin ?? '');
                      isValid = pinResponse.isValid;
                    } catch (e) {
                      isValid = false;
                    }
                    // if (!pinValid) {
                    //   if (context.mounted) context.hideLoading();
                    // }
                    if (context.mounted) context.hideLoading();
                    return isValid
                        ? null
                        : context.mounted
                            ? context.strings().error_incorrect_pin
                            : '';
                  },
                  onPinVerified: () async {
                    var encryptedPin =
                        await PinEncryption.encryptPin(pin: user.pin);
                    sendMoney(encryptedPin);
                  },
                  onBiometricAuth: (isAuthenticated, errorMessage) async {
                    if (isAuthenticated) {
                      var encryptedPin =
                          await PinEncryption.encryptPin(pin: user.pin);
                      sendMoney(encryptedPin);
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
                if (errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(4),
                    width: size.width,
                    child: Text(
                      errorMessage!,
                      textAlign: TextAlign.start,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: Colors.red),
                    ),
                  ),
                SizedBox(height: size.height * 0.001),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
