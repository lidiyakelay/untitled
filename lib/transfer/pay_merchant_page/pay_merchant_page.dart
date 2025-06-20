import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:stardom/core/utils/extensions/context_extensions.dart';
import 'package:stardom/core/utils/extensions/string_extensions.dart';
import 'package:stardom/data/datasources/local/transaction_local_data_source.dart';
import 'package:stardom/domain/entities/auth/user_data.dart';
import 'package:stardom/domain/entities/common/account_info.dart';
import 'package:stardom/domain/entities/send_money/send_money_prevalidation_entity.dart';
import 'package:stardom/domain/repositories/auth_repository.dart';
import 'package:stardom/presentation/state_management/buy/buy_bloc.dart';
import 'package:stardom/presentation/state_management/send_money/send_money_bloc.dart';
import 'package:stardom/presentation/state_management/send_money/send_money_event.dart';
import 'package:stardom/presentation/state_management/send_money/send_money_state.dart';
import 'package:stardom/presentation/widgets/base_screen.dart';
import 'package:stardom/presentation/widgets/bottom_sheet/account_type_bottom_sheet.dart';
import 'package:stardom/presentation/widgets/buttons/primary_button.dart';
import 'package:stardom/presentation/widgets/cards/transaction_card.dart';
import 'package:stardom/presentation/widgets/input_field/custom_input.dart';

import '../../../../app/di/injector.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/utils/constants/colors.dart';
import '../../../../core/utils/constants/sizes.dart';
import '../../../../domain/entities/send_money/send_money_prevalidation_response_entity.dart';
import '../../../widgets/buttons/secondary_button.dart';
import '../../../widgets/custom_dialog_box.dart';
import '../../../widgets/dialog/overdraft_dialog.dart';
import '../../home/home.dart';

class PayMerchantPage extends StatefulWidget {
  const PayMerchantPage({super.key});

  @override
  State<PayMerchantPage> createState() => _PayMerchantPageState();
}

class _PayMerchantPageState extends State<PayMerchantPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController idController = TextEditingController();
  final userRepository = sl<AuthRepository>();

  List<Transaction> transactionsList = [];
  bool _isButtonEnabled = false;
  final TextEditingController amountController = TextEditingController();
  final FocusNode _idFocusNode = FocusNode();
  bool isAmountEnabled = false;
  bool prevalidateCustomer = false;
  String? receiverName;
  bool _isIdValid = false;
  List<AccountInfo> availableAccounts = [];
  AccountInfo? selectedAccount;

  loadData() {
    getTransactions();
    context.read<BuyBloc>().add(GetAccountsRequested());
  }

  @override
  void initState() {
    super.initState();

    _idFocusNode.addListener(() {
      if (!_idFocusNode.hasFocus) {
        final idText = idController.text.trim();
        if (idText.isNotEmpty) {
          customerPrevalidation().then((isValid) {
            setState(() {
              _isIdValid = isValid;
            });
            _updateButtonState();
          });
        } else {
          setState(() {
            _isIdValid = false;
          });
          _updateButtonState();
        }
      }
    });

    amountController.addListener(_updateButtonState);
    idController.addListener(_onIdChanged);

    getTransactions();
    loadData();
  }

  void _updateButtonState() {
    var accountAllowOD =
        selectedAccount?.accountType == AccountInfoTypes.main.accountType;
    setState(() {
      _isButtonEnabled = _isIdValid &&
          amountController.text.trim().isNotEmpty &&
          (selectedAccount != null &&
              (accountAllowOD ||
                  selectedAccount!.availableBalance.toDouble() > 0.0));
    });
  }

  void _onIdChanged() {
    // If user starts changing the ID after validation, clear the receiver name
    if (receiverName != null) {
      setState(() {
        _isButtonEnabled = false;
        receiverName = null;
        isAmountEnabled = false;
      });
    }
  }

  getTransactions() async {
    final transactionDataSource = sl<TransactionLocalDataSource>();
    final transactions =
        await transactionDataSource.getTransactionsByType('M-PESA-MERCHANT');
    setState(() {
      transactionsList = transactions;
    });
  }

  customerPrevalidation() async {
    prevalidateCustomer = true;
    User? user = await userRepository.getLocalUser();
    if (user != null && idController.text.trim().length < 9) {
      BlocProvider.of<SendMoneyBloc>(context).add(
          PayForMerchantPrevalidationEvent(SendMoneyPrevalidationEntity(
              initiator: user.msisdn,
              receiverParty: idController.text.trim(),
              amount: '1')));
    }
  }

  confirmPrevalidation() async {
    User? user = await userRepository.getLocalUser();
    if (user != null && idController.text.trim().length < 9) {
      BlocProvider.of<SendMoneyBloc>(context)
          .add(PayForMerchantPrevalidationEvent(SendMoneyPrevalidationEntity(
        initiator: user.msisdn,
        receiverParty: idController.text.trim(),
        amount: amountController.text.trim(),
        selectedAccount: AccountInfoTypes.values.firstWhere(
            (account) => account.accountType == selectedAccount?.accountType,
            orElse: () => AccountInfoTypes.main),
      )));
    }
  }

  @override
  void dispose() {
    _idFocusNode.dispose();
    idController.removeListener(_onIdChanged);
    idController.dispose();
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    var minSize = min(size.height, size.width);

    return BaseScreen(
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
          Text(context.strings().enter_merchant_id,
              style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
      content: MultiBlocListener(
        listeners: [
          BlocListener<SendMoneyBloc, SendMoneyState>(
            listenWhen: (previous, current) {
              return ModalRoute.of(context)?.isCurrent ?? false;
            },
            listener: (context, state) {
              if (state is SendMoneyLoading) {
                context.showLoading();
              }
              if (state is PayForMerchantPrevalidationSuccess) {
                context.hideLoading();
                if (state.data?.identityFullName == null ||
                    state.data?.identityFullName == '') {
                  context.showDialogBox(CustomDialogBox(
                    dialogTitle: context.strings().receiver_not_found,
                    primaryButton: PrimaryButton(
                      text: context.strings().retry_button,
                      onPressed: () {
                        context.pop();
                      },
                      enabled: true,
                      analyticsButtonName:
                          'pay_merchant_prevalidation_dialog_retry',
                    ),
                  ));
                  return;
                } else if (state.data?.responseCode != '0') {
                  if (state.data?.responseCode == 'TPCHODTS28009') {
                    context.showDialogBox(CustomDialogBox(
                      dialogTitle: context.strings().overdraft_register_title,
                      dialogDescription:
                          context.strings().overdraft_register_desc,
                      primaryButton: PrimaryButton(
                        text: context.strings().continue_button,
                        enabled: true,
                        onPressed: () {
                          context.pop();
                          context.pushNamed(AppRoutes.activateOverDraftScreen);
                        },
                        analyticsButtonName:
                            'send_money_prevalidation_dialog_register_overdraft_dialog_continue',
                      ),
                      secondaryButton: SecondaryButton(
                        text: context.strings().cancel_button,
                        enabled: true,
                        onPressed: () {
                          context.pop();
                        },
                        analyticsButtonName:
                            'send_money_prevalidation_dialog_register_overdraft_dialog_cancel',
                      ),
                    ));
                    return;
                  } else if (state.data?.responseCode == 'ODE2011') {
                    context.showDialogBox(CustomDialogBox(
                      dialogTitle:
                          context.strings().credit_limit_is_insufficient,
                      primaryButton: PrimaryButton(
                        text: context.strings().close_button,
                        onPressed: () {
                          context.pop();
                        },
                        enabled: true,
                        analyticsButtonName:
                            'pay_merchant_prevalidation_dialog_close',
                      ),
                    ));
                    return;
                  } else if (state.data?.responseCode == 'E0020') {
                    print("--OD here--");
                    final odBalance = state.data!.additionalInfo
                        .firstWhere(
                          (el) => el.key == 'UseODAmount',
                          orElse: () => SendMoneyAdditionalInfo(
                              key: 'UseODAmount', value: ''),
                        )
                        .value;
                    context.showDialogWidget(OverdraftDialog(
                      dialogTitle: context.strings().overdraft_dialog_title,
                      transactionAmount:
                          amountController.text.replaceAll(',', '').toDouble(),
                      overdraftAmount: odBalance.toDouble(),
                      onPressed: () {
                        context.pop;
                        context.pushNamed(
                          AppRoutes.confirmTransaction,
                          queryParameters: {
                            'identityFullName': state.data!.identityFullName,
                            'id': idController.text.trim(),
                            'channelSessionId':
                                state.data!.channelSessionId ?? '',
                            'amount': amountController.text.trim(),
                            'remark': '',
                            'transactionFee':
                                state.data!.transactionCharge ?? '0',
                            'useOD': 'true',
                            'selectedAccount': selectedAccount?.accountType
                          },
                        );
                      },
                    ));
                    return;
                  } else if (state.data?.responseCode
                          .toLowerCase()
                          .startsWith('ode') ==
                      true) {
                    context.showDialogBox(CustomDialogBox(
                      showCloseIcon: false,
                      dialogTitle: context.strings().insufficient_balance,
                      primaryButton: PrimaryButton(
                        text: context.strings().retry_button,
                        onPressed: () {
                          context.pop();
                        },
                        enabled: true,
                        analyticsButtonName:
                            'send_money_prevalidation_dialog_retry',
                      ),
                    ));
                    return;
                  }
                } else if (prevalidateCustomer) {
                  setState(() {
                    _isIdValid = true;
                    _updateButtonState();
                    isAmountEnabled = true;
                    receiverName = state.data!.identityFullName;
                  });
                  return;
                }
                context.pushNamed(
                  AppRoutes.confirmTransaction,
                  queryParameters: {
                    'identityFullName': state.data!.identityFullName,
                    'id': idController.text.trim(),
                    'channelSessionId': state.data!.channelSessionId ?? '',
                    'amount': amountController.text.trim(),
                    'remark': '',
                    'transactionFee': state.data!.transactionCharge ?? '0',
                    'selectedAccount': selectedAccount?.accountType
                  },
                );
              }

              if (state is PayForMerchantPrevalidationFailure) {
                context.hideLoading();
                context.showDialogBox(CustomDialogBox(
                  dialogTitle: state.error,
                  primaryButton: PrimaryButton(
                    text: context.strings().retry_button,
                    onPressed: () {
                      context.pop();
                    },
                    enabled: true,
                    analyticsButtonName:
                        'pay_merchant_prevalidation_dialog_retry',
                  ),
                ));
              }
            },
          ),
          BlocListener<BuyBloc, BuyState>(
              listenWhen: (previous, current) =>
                  ModalRoute.of(context)?.isCurrent ?? false,
              listener: (context, state) {
                if (state is BuyLoading) {
                  context.showLoading();
                } else if (state is GetAccountsDone) {
                  setState(() {
                    availableAccounts = state.result;
                    selectedAccount = availableAccounts.sortByPriority().first;
                  });
                }
                if (state is! BuyLoading) {
                  context.hideLoading();
                }
              }),
        ],
        child: Form(
          key: _formKey,
          child: SizedBox(
            height: size.height,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: size.height * 0.02,
                ),
                CustomInput(
                  controller: idController,
                  labelInline: true,
                  showInlineLabelWhenFocused: true,
                  focusedTextStyle: Theme.of(context).textTheme.titleMedium,
                  unFocusedTextStyle: Theme.of(context).textTheme.titleMedium,
                  inputType: TextInputType.number,
                  focusNode: _idFocusNode,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(12),
                  ],
                  labelText: context.strings().merchant_id,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.strings().merchant_id_required;
                    }
                    if (value.length > 9) {
                      return context.strings().merchant_id_too_long;
                    } else if (value.length < 4) {
                      return 'merchant id too short';
                    }

                    return null;
                  },
                ),
                if (receiverName != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: Text(
                      receiverName!,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                CustomInput(
                  controller: amountController,
                  labelInline: true,
                  labelText: context.strings().amount,
                  enabled: isAmountEnabled,
                  inputType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  validator: (value) {
                    if (!isAmountEnabled) return null;
                    if (value == null || value.isEmpty) {
                      return context.strings().amount_required;
                    }
                    return null;
                  },
                  suffix: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      context.strings().birr,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontSize: 20),
                    ),
                  ),
                ),
                InkWell(
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  onTap: () async {
                    AccountInfo? result =
                        await context.showBottomSheet<AccountInfo>(
                      bottomSheetContent: AccountTypeBottomSheet(
                        selectedAccount: selectedAccount,
                        availableAccounts: availableAccounts,
                      ),
                      bottomSheetTitle: context.strings().choose_balance,
                    );
                    if (result != null) {
                      setState(() {
                        selectedAccount = result;
                      });
                    }
                  },
                  child: CustomInput(
                      enabled: false,
                      labelText: selectedAccount != null
                          ? switch (selectedAccount!.accountName) {
                              "Available Balance" =>
                                context.strings().available_balance,
                              "Reward Balance" =>
                                context.strings().reward_balance,
                              null => selectedAccount!.accountType,
                              String() => selectedAccount!.accountType,
                            }
                          : context.strings().choose_balance,
                      labelInline: true,
                      focusedLabelStyle:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: SColors.onSurfaceLight,
                              ),
                      unFocusedLabelStyle:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: SColors.onSurfaceLight,
                              ),
                      suffix: Icon(Iconsax.arrow_down_1, size: minSize * 0.06),
                      helper: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${selectedAccount?.availableBalance.formatCurrency() ?? '0.00'} ${context.strings().birr}',
                          textAlign: TextAlign.end,
                        ),
                      ),
                      validator: (value) {
                        if (selectedAccount == null) {
                          return "";
                        } else {
                          return null;
                        }
                      }),
                ),
                SizedBox(height: size.height * 0.01),
                PrimaryButton(
                  text: context.strings().next_button,
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      setState(() {
                        prevalidateCustomer = false;
                      });
                      confirmPrevalidation();
                    }
                  },
                  enabled: _isButtonEnabled,
                  analyticsButtonName: 'scan_to_pay_using_merchant_id_next',
                ),
                SizedBox(height: size.height * 0.02),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(context.strings().recent_transactions,
                        style: Theme.of(context).textTheme.titleSmall),
                    // Text(context.strings().see_all,
                    //     style: Theme.of(context).textTheme.titleSmall),
                  ],
                ),
                Expanded(
                  child: transactionsList.isEmpty
                      ? Center(
                          child: Text(
                            context.strings().no_transactions,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall!
                                .copyWith(color: SColors.onSurfaceDark),
                          ),
                        )
                      : ListView.builder(
                          itemCount: transactionsList.length,
                          itemBuilder: (context, index) {
                            final transaction = transactionsList[index];
                            final title = transaction.receiverParty;
                            final subTitle = transaction.receiverId;
                            return TransactionCard(
                              title: title,
                              subtitle: subTitle,
                              onPressed: () {
                                setState(() {
                                  idController.text = subTitle;
                                  customerPrevalidation();
                                });
                              },
                            );
                          }),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
