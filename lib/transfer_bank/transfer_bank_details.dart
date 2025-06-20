import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:stardom/app/di/injector.dart';
import 'package:stardom/app/routes/app_routes.dart';
import 'package:stardom/core/utils/constants/colors.dart';
import 'package:stardom/core/utils/constants/constants.dart';
import 'package:stardom/core/utils/constants/sizes.dart';
import 'package:stardom/core/utils/extensions/bank_extensions.dart';
import 'package:stardom/core/utils/extensions/context_extensions.dart';
import 'package:stardom/core/utils/extensions/language_extensions.dart';
import 'package:stardom/core/utils/extensions/string_extensions.dart';
import 'package:stardom/data/datasources/local/transaction_local_data_source.dart';
import 'package:stardom/domain/entities/auth/user_data.dart';
import 'package:stardom/domain/entities/bank/bank.dart';
import 'package:stardom/domain/entities/bank/bank_account_info.dart';
import 'package:stardom/domain/entities/bank/bank_transfer.dart';
import 'package:stardom/domain/entities/common/key_value.dart';
import 'package:stardom/domain/entities/send_money/send_money_prevalidation_entity.dart';
import 'package:stardom/domain/repositories/auth_repository.dart';
import 'package:stardom/presentation/pages/transfer_bank/components/choose_bank_bottom_sheet.dart';
import 'package:stardom/presentation/pages/transfer_bank/components/contact_bottom_sheet.dart';
import 'package:stardom/presentation/state_management/bank/bank_bloc.dart';
import 'package:stardom/presentation/state_management/send_money/send_money_bloc.dart';
import 'package:stardom/presentation/state_management/send_money/send_money_event.dart';
import 'package:stardom/presentation/state_management/send_money/send_money_state.dart';
import 'package:stardom/presentation/widgets/base_screen.dart';
import 'package:stardom/presentation/widgets/buttons/primary_button.dart';
import 'package:stardom/presentation/widgets/custom_dialog_box.dart';
import 'package:stardom/presentation/widgets/input_field/custom_input.dart';

import '../../state_management/auth/auth_bloc.dart';
import '../../state_management/auth/auth_event.dart';
import '../../state_management/auth/auth_state.dart';
import 'components/transaction_tile.dart';

class TransferBankDetails extends StatefulWidget {
  const TransferBankDetails({super.key});

  @override
  TransferBankDetailsState createState() => TransferBankDetailsState();
}

class TransferBankDetailsState extends State<TransferBankDetails> {
  List<Bank> banks = [];
  List<Transaction> recentTransactions = [];

  final userRepository = sl<AuthRepository>();
  late int selectedIndex;
  bool isAccountNoEnabled = false;
  final TextEditingController idController = TextEditingController();
  FocusNode _idFocus = FocusNode();
  final TextEditingController _accountController = TextEditingController();
  FocusNode _accountFocus = FocusNode();
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _amountFocus = FocusNode();
  final TextEditingController _reasonController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  final ValueNotifier<bool> isNextEnabledNotifier = ValueNotifier(false);
  final ValueNotifier<Bank?> selectedBankNotifier = ValueNotifier(null);
  final ValueNotifier<String?> accountNameNotifier = ValueNotifier(null);
  final ValueNotifier<String?> accountNumberErrorNotifier = ValueNotifier(null);
  final ValueNotifier<String?> amountErrorNotifier = ValueNotifier(null);
  String? idErrorNotifier;
  String balance = '- -';
  late StreamSubscription<AuthState> _authBlocSubscription;

  loadData() {
    BlocProvider.of<AuthBloc>(context).add(FetchBalanceEvent());
  }

  void attachedIdListener(FocusNode node) {
    node.addListener(() {
      if (!_idFocus.hasFocus) {
        Future.delayed(
          const Duration(),
          () => SystemChannels.textInput.invokeMethod('TextInput.hide'),
        );
      }

      if (!_idFocus.hasFocus) {
        customerPrevalidation(withAmount: false);
      } else {
        setState(() {
          idErrorNotifier = null;
        });
        accountNameNotifier.value = null;
      }
      _updateNextButtonState("");
    });
  }

  void attachedAccountListener(FocusNode node) {
    node.addListener(() {
      if (!_accountFocus.hasFocus) {
        Future.delayed(
          const Duration(),
          () => SystemChannels.textInput.invokeMethod('TextInput.hide'),
        );
      }

      if (!_accountFocus.hasFocus) {
        accountNumberErrorNotifier.value = null;
        accountNameNotifier.value = null;
        if (selectedBankNotifier.value != null &&
            _accountController.text.trim().isNotEmpty) {
          _accountController.text = _accountController.text.trim();
          context.read<BankBloc>().add(FetchBankAccountInfo(
                BankAccountInfo(
                  bank: selectedBankNotifier.value!,
                  accountNumber: _accountController.text,
                ),
              ));
        }
      }
      _updateNextButtonState("");
    });
  }

  @override
  void initState() {
    super.initState();
    getTransactions();
    selectedIndex = 100;
    context.read<BankBloc>().add(FetchBanks(forceRefresh: false));
    attachedAccountListener(_accountFocus);

    attachedIdListener(_idFocus);

    loadData();
    _authBlocSubscription =
        BlocProvider.of<AuthBloc>(context).stream.listen((state) {
      if (state is BalanceFetched) {
        if (mounted) {
          setState(() {
            balance = state.mpesaBalance;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _authBlocSubscription.cancel();
    _accountController.dispose();
    _amountController.dispose();
    _reasonController.dispose();
    selectedBankNotifier.dispose();
    accountNameNotifier.dispose();
    accountNumberErrorNotifier.dispose();
    amountErrorNotifier.dispose();
    isNextEnabledNotifier.dispose();
    context.hideLoading();
    super.dispose();
  }

  void _updateNextButtonState(_) {
    isNextEnabledNotifier.value = selectedIndex == 0
        ? idController.text.isNotEmpty &&
            accountNameNotifier.value != null &&
            _amountController.text.isNotEmpty
        : selectedBankNotifier.value != null &&
            accountNameNotifier.value != null &&
            _accountController.text.isNotEmpty &&
            _amountController.text.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.sizeOf(context);

    return BaseScreen(
      title: Align(
        alignment: Alignment.centerLeft,
        child: Text(context.strings().transfer,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.normal)),
      ),
      leading: IconButton(
        padding: const EdgeInsets.only(left: SSizes.md),
        icon: const Icon(
          Iconsax.arrow_left,
          color: SColors.onSurface,
          size: SSizes.iconMd,
        ),
        onPressed: () => context.pop(),
      ),
      content: MultiBlocListener(
        listeners: [
          BlocListener<BankBloc, BankState>(
            listenWhen: (previous, current) {
              return ModalRoute.of(context)?.isCurrent ?? false;
            },
            listener: (context, state) {
              if (state is BankLoading) {
                context.showLoading();
              } else if (state is BankListLoaded) {
                context.hideLoading();
                setState(() {
                  banks = state.banks;
                });
              } else if (state is BankListFailure) {
                context.hideLoading();
                context.showSnackBar(
                  state.error,
                  textColor: SColors.white,
                  backgroundColor: SColors.surfaceContainerError,
                );
              } else if (state is BankAccountLoaded) {
                context.hideLoading();
                accountNameNotifier.value =
                    state.bankAccount.fullNames.capitalizeWords();
                _updateNextButtonState("");
              } else if (state is BankAccountFailure) {
                context.hideLoading();
                accountNumberErrorNotifier.value = state.error;
                _updateNextButtonState("");
              } else if (state is PreValidateSuccess) {
                context.hideLoading();
                var transactionFee = state.result.responseParameters.firstWhere(
                    (e) => e.key == 'Charge' || e.key == 'TransactionFee',
                    orElse: () => KeyValue(key: '', value: '0.00'));

                context.pushNamed(AppRoutes.transferBankConfirm,
                    extra: BankTransfer(
                        recipientName: accountNameNotifier.value ??
                            context.strings().not_registered,
                        bank: selectedBankNotifier.value!,
                        accountNumber: _accountController.text,
                        amount: _amountController.text
                            .replaceAll(',', '')
                            .toDouble(),
                        reason: _reasonController.text,
                        transactionFee: transactionFee.value.toDouble()));
              } else if (state is PreValidateFailure) {
                context.hideLoading();
                context.showDialogBox(CustomDialogBox(
                  dialogTitle: state.error,
                  primaryButton: PrimaryButton(
                      analyticsButtonName:
                          'transfer_bank_details_prevalidation_error_retry',
                      text: context.strings().retry_button,
                      onPressed: () {
                        context.pop();
                      },
                      enabled: true),
                ));
              }
            },
          ),
          BlocListener<SendMoneyBloc, SendMoneyState>(
            listenWhen: (previous, current) {
              return ModalRoute.of(context)?.isCurrent ?? false;
            },
            listener: (context, state) {
              if (state is SendMoneyLoading) {
                context.showLoading();
              }
              if (state is SendMoneyPrevalidationSuccess) {
                context.hideLoading();
                if (state.data?.responseCode != '0') {
                  if (state.data?.responseCode == '1' ||
                      state.data?.responseCode == 'TPCHODTS28009') {
                    context.showDialogBox(CustomDialogBox(
                      dialogTitle: context.strings().balance_insufficient,
                      primaryButton: PrimaryButton(
                          analyticsButtonName:
                              'transfer_bank_details_prevalidation_balance_insufficient',
                          text: context.strings().close_button,
                          onPressed: () {
                            context.pop();
                          },
                          enabled: true),
                    ));
                  } else if (state.data?.responseCode == '2044') {
                    context.showDialogBox(CustomDialogBox(
                      dialogTitle: context.strings().recipient_same,
                      primaryButton: PrimaryButton(
                          analyticsButtonName:
                              'transfer_bank_details_prevalidation_recipient_same_retry',
                          text: context.strings().retry_button,
                          onPressed: () {
                            context.pop();
                          },
                          enabled: true),
                    ));
                  } else if (state.data?.responseCode == '2004') {
                    accountNameNotifier.value = null;
                    setState(() {
                      idErrorNotifier = context.strings().not_registered;
                    });
                    context.showDialogBox(CustomDialogBox(
                      dialogTitle:
                          context.strings().not_registered_ethiotel_message,
                      primaryButton: PrimaryButton(
                          analyticsButtonName:
                              'send_money_unregistered_ethiotel_close',
                          text: context.strings().close_button,
                          onPressed: () {
                            context.pop();
                          },
                          enabled: true),
                    ));
                  } else {
                    context.showDialogBox(CustomDialogBox(
                      dialogTitle: context.strings().error_validation_failed,
                      primaryButton: PrimaryButton(
                          analyticsButtonName:
                              'transfer_bank_details_prevalidation_error_close',
                          text: context.strings().close_button,
                          onPressed: () {
                            context.pop();
                          },
                          enabled: true),
                    ));
                  }
                  return;
                }
                _updateNextButtonState("");
                if (accountNameNotifier.value?.trim().isEmpty ?? true) {
                  if (state.data?.identityFullName.trim().isEmpty ?? true) {
                    var phone = idController.text
                        .formatPhoneNumber()
                        .replaceAll(" ", "");
                    if (phone.startsWith("9")) {
                      accountNameNotifier.value = null;
                      setState(() {
                        idErrorNotifier = context.strings().not_registered;
                      });
                      context.showDialogBox(CustomDialogBox(
                        dialogTitle:
                            context.strings().not_registered_ethiotel_message,
                        primaryButton: PrimaryButton(
                            analyticsButtonName:
                                'send_money_unregistered_ethiotel_close',
                            text: context.strings().close_button,
                            onPressed: () {
                              context.pop();
                            },
                            enabled: true),
                      ));
                    } else {
                      setState(() {
                        idErrorNotifier = null;
                      });
                      accountNameNotifier.value =
                          context.strings().not_registered;
                      context.showDialogBox(CustomDialogBox(
                        dialogTitle:
                            context.strings().not_registered_safari_message,
                        primaryButton: PrimaryButton(
                            analyticsButtonName:
                                'send_money_unregistered_safari_continue',
                            text: context.strings().continue_button,
                            onPressed: () {
                              context.pop();
                            },
                            enabled: true),
                      ));
                    }
                  } else {
                    setState(() {
                      accountNameNotifier.value =
                          state.data?.identityFullName.capitalizeWords();
                    });
                  }
                  _updateNextButtonState("");
                } else {
                  var amount =
                      _amountController.text.replaceAll(",", "").trim();
                  if ((double.tryParse(amount) ?? 0) > 0) {
                    context.pushNamed(
                      AppRoutes.confirmTransaction,
                      queryParameters: {
                        'identityFullName': accountNameNotifier.value,
                        'id': idController.text
                            .trim()
                            .formatPhoneNumber()
                            .normalizeMsisdn(),
                        'channelSessionId': state.data!.channelSessionId ?? '',
                        'amount':
                            _amountController.text.replaceAll(",", "").trim(),
                        'remark': "",
                        'transactionFee': state.data!.transactionCharge ?? '0',
                      },
                    );
                  }
                  return;
                }
              }

              if (state is SendMoneyPrevalidationFailure) {
                context.hideLoading();
                _updateNextButtonState("");
                context.showDialogBox(CustomDialogBox(
                  dialogTitle: state.error,
                  primaryButton: PrimaryButton(
                      analyticsButtonName:
                          'transfer_bank_details_prevalidation_error_retry',
                      text: context.strings().retry_button,
                      onPressed: () {
                        context.pop();
                      },
                      enabled: true),
                ));
              }
            },
          )
        ],
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ValueListenableBuilder<Bank?>(
                valueListenable: selectedBankNotifier,
                builder: (context, selectedBank, _) => InkWell(
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  onTap: () async {
                    Bank? result = await context.showBottomSheet<Bank>(
                        bottomSheetContent: ChooseBankBottomSheet(banks: banks),
                        bottomSheetTitle: context.strings().choose_bank,
                        fullscreen: true,
                        hideDragHandle: true);
                    if (result != null) {
                      selectedBankNotifier.value = result;
                      setState(() {
                        isAccountNoEnabled = true;
                        selectedIndex = banks.indexOf(result);
                        accountNameNotifier.value = null;
                        if (selectedIndex == 0) {
                          idController.clear();
                        } else {
                          _accountController.clear();
                        }
                      });
                    }
                  },
                  child: CustomInput(
                      enabled: false,
                      labelText: selectedBank != null
                          ? context
                              .strings()
                              .bank(bankNames: selectedBank.instNameInfo)
                          : context.strings().choose_bank,
                      labelInline: true,
                      nextFocusNode: _accountFocus,
                      unFocusedLabelStyle: selectedBank != null
                          ? Theme.of(context).textTheme.titleMedium
                          : null,
                      suffix:
                          selectedBank != null && selectedBank.logoImage != null
                              ? Image.memory(
                                  selectedBank.logoImage!,
                                  height: SSizes.iconLg,
                                )
                              : const Icon(
                                  Iconsax.bank,
                                  size: SSizes.iconLg,
                                  color: SColors.onSurfaceLight,
                                ),
                      validator: (value) {
                        if (selectedBank == null) {
                          return;
                        } else {
                          return null;
                        }
                      }),
                ),
              ),
              selectedIndex == 0
                  ? () {
                      if (!_idFocus.hasListeners) {
                        var node = FocusNode();
                        attachedIdListener(node);
                        _idFocus = node;
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: CustomInput(
                              controller: idController,
                              labelInline: true,
                              showInlineLabelWhenFocused: true,
                              focusNode: _idFocus,
                              nextFocusNode: _amountFocus,
                              focusedTextStyle:
                                  Theme.of(context).textTheme.titleMedium,
                              unFocusedTextStyle:
                                  Theme.of(context).textTheme.titleMedium,
                              inputType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(12),
                              ],
                              onChanged: _updateNextButtonState,
                              labelText: context.strings().phone_or_id,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return context.strings().phone_or_id_required;
                                }
                                return null;
                              },
                              errorText: idErrorNotifier,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 4, top: 4),
                            child: IconButton(
                              icon: SvgPicture.asset(Assets.contact),
                              iconSize: SSizes.iconMd,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () async {
                                String? phone =
                                    await context.showBottomSheet<String>(
                                  bottomSheetTitle:
                                      context.strings().choose_contact,
                                  bottomSheetContent:
                                      const ContactBottomSheet(),
                                  fullscreen: true,
                                );
                                if (phone != null) {
                                  idController.text = phone.replaceAll(" ", "");
                                  setState(() {
                                    accountNameNotifier.value = null;
                                  });
                                  customerPrevalidation(withAmount: false);
                                }
                              },
                            ),
                          ),
                        ],
                      );
                    }()
                  : ValueListenableBuilder<String?>(
                      valueListenable: accountNumberErrorNotifier,
                      builder: (context, accountNumberError, _) {
                        if (!_accountFocus.hasListeners) {
                          var node = FocusNode();
                          attachedAccountListener(node);
                          _accountFocus = node;
                        }

                        return CustomInput(
                          controller: _accountController,
                          labelText: context.strings().bank_account_number,
                          labelInline: true,
                          showInlineLabelWhenFocused: true,
                          focusNode: _accountFocus,
                          nextFocusNode: _amountFocus,
                          focusedTextStyle:
                              Theme.of(context).textTheme.titleMedium,
                          unFocusedTextStyle:
                              Theme.of(context).textTheme.titleMedium,
                          inputType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return context.strings().account_required;
                            } else {
                              return null;
                            }
                          },
                          enabled: isAccountNoEnabled,
                          onChanged: _updateNextButtonState,
                          errorText: accountNumberError,
                        );
                      },
                    ),
              const SizedBox(height: SSizes.sm),
              ValueListenableBuilder<String?>(
                  valueListenable: accountNameNotifier,
                  builder: (context, name, _) => name != null
                      ? Padding(
                          padding: const EdgeInsets.only(
                              left: SSizes.md, bottom: SSizes.md + 4, top: 0),
                          child: Text(name,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: SColors.primary)),
                        )
                      : const SizedBox.shrink()),
              ValueListenableBuilder(
                valueListenable: amountErrorNotifier,
                builder: (context, amountError, _) => CustomInput(
                  controller: _amountController,
                  labelText: context.strings().amount,
                  labelInline: true,
                  showInlineLabelWhenFocused: true,
                  inputType: TextInputType.number,
                  focusNode: _amountFocus,
                  focusedTextStyle: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                          color: SColors.primary,
                          fontSize: SSizes.fontSizeXl,
                          fontWeight: FontWeight.w500),
                  unFocusedTextStyle: Theme.of(context).textTheme.titleMedium,
                  suffix: Text(context.strings().birr,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(fontSize: SSizes.fontSizeXl)),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      final formatted = newValue.text.inputFormatCurrency();
                      return TextEditingValue(
                        text: formatted,
                        selection:
                            TextSelection.collapsed(offset: formatted.length),
                      );
                    }),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty || value == "0") {
                      return context.strings().amount_required;
                    } else {
                      return null;
                    }
                  },
                  onChanged: _updateNextButtonState,
                  errorText: amountError,
                ),
              ),
              // CustomInput(
              //   controller: _reasonController,
              //   labelText: context.strings().bank_payment_reason,
              //   labelInline: true,
              //   showInlineLabelWhenFocused: true,
              //   focusedTextStyle: Theme.of(context).textTheme.titleMedium,
              //   unFocusedTextStyle: Theme.of(context).textTheme.titleMedium,
              // ),
              const SizedBox(height: SSizes.sm),
              Padding(
                padding: const EdgeInsets.only(left: SSizes.md),
                child: Text(
                    '${context.strings().available_balance} : '
                    '${balance.formatCurrency()} ${context.strings().birr}',
                    style: Theme.of(context).textTheme.titleSmall),
              ),
              const SizedBox(height: SSizes.sm),
              ValueListenableBuilder<bool>(
                  valueListenable: isNextEnabledNotifier,
                  builder: (context, isNextEnabled, _) => PrimaryButton(
                        text: context.strings().next_button,
                        onPressed: () {
                          if (selectedIndex == 0) {
                            if (_formKey.currentState!.validate()) {
                              print("calling this");
                              customerPrevalidation();
                            }
                          } else {
                            if (_formKey.currentState!.validate()) {
                              amountErrorNotifier.value = null;
                              context
                                  .read<BankBloc>()
                                  .add(PreValidateTransferRequested(
                                    BankTransfer(
                                      recipientName: accountNameNotifier.value!,
                                      bank: selectedBankNotifier.value!,
                                      accountNumber: _accountController.text,
                                      amount: _amountController.text
                                          .replaceAll(',', '')
                                          .toDouble(),
                                      reason: _reasonController.text,
                                    ),
                                  ));
                            }
                          }
                        },
                        enabled: isNextEnabled,
                        analyticsButtonName: 'transfer_bank_details_next',
                      )),
              SizedBox(
                height: size.height * 0.02,
              ),
              Text(
                context.strings().recent_transactions,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.normal),
              ),
              Expanded(
                child: recentTransactions.isEmpty
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
                        shrinkWrap: true,
                        itemCount: recentTransactions.length,
                        itemBuilder: (context, index) {
                          final transaction = recentTransactions[index];
                          if (transaction.type == 'Bank') {
                            final identifier =
                                transaction.receiverId.split(":").first;
                            final accountNumber =
                                transaction.receiverId.split(":").last;
                            final transactionBank = banks.firstWhere(
                              (bank) =>
                                  bank.shortcode == identifier ||
                                  bank.bic == identifier,
                              orElse: () => Bank(
                                  priority: 0,
                                  instNameInfo: [],
                                  bic: '',
                                  logo: '',
                                  shortcode: '',
                                  instType: InstitutionType.direct),
                            );
                            final formatted = transaction.amount
                                .toInt()
                                .toString()
                                .inputFormatCurrency();

                            return TransactionTile(
                              transaction: transaction,
                              bank: transactionBank,
                              onTap: () {
                                selectedBankNotifier.value = transactionBank;
                                selectedIndex = banks.indexOf(transactionBank);
                                accountNameNotifier.value =
                                    transaction.receiverParty;
                                _accountController.text = accountNumber;
                                setState(() {
                                  idErrorNotifier = null;
                                  isAccountNoEnabled = true;
                                  _amountController.value = TextEditingValue(
                                    text: formatted,
                                    selection: TextSelection.collapsed(
                                        offset: formatted.length),
                                  );
                                });
                              },
                            );
                          } else {
                            final title = transaction.receiverParty;
                            final subTitle = transaction.receiverId;

                            return TransactionTile(
                              transaction: transaction,
                              onTap: () {
                                final formatted = transaction.amount
                                    .toInt()
                                    .toString()
                                    .inputFormatCurrency();

                                final mpesa = banks.firstWhere(
                                  (bank) => bank.bic == 'MPesa',
                                  orElse: () => banks.first,
                                );

                                setState(() {
                                  selectedIndex = banks.indexOf(mpesa);
                                  selectedBankNotifier.value = mpesa;
                                  idController.text =
                                      subTitle.normalizeMsisdn();
                                  idErrorNotifier = null;
                                  _amountController.value = TextEditingValue(
                                    text: formatted,
                                    selection: TextSelection.collapsed(
                                        offset: formatted.length),
                                  );
                                });
                                accountNameNotifier.value = null;
                                customerPrevalidation(withAmount: false);
                              },
                            );
                          }
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> getTransactions() async {
    final transactionDataSource = sl<TransactionLocalDataSource>();

    final bankTransactions =
        await transactionDataSource.getTransactionsByType('Bank');

    final mpesaTransactions =
        await transactionDataSource.getTransactionsByType('M-PESA');

    // Merge both lists
    final allTransactions = [...mpesaTransactions, ...bankTransactions];

    // Sort by `createdAt` in descending order (latest first)
    allTransactions.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));

    // Keep only the top 5 latest transactions
    final latestTransactions = allTransactions.take(5).toList();

    setState(() {
      recentTransactions = latestTransactions;
    });
  }

  customerPrevalidation({bool withAmount = true}) async {
    User? user = await userRepository.getLocalUser();
    if (user != null && idController.text.trim().length >= 9) {
      print("calling this");
      BlocProvider.of<SendMoneyBloc>(context).add(SendMoneyPrevalidationEvent(
          SendMoneyPrevalidationEntity(
              initiator: user.msisdn,
              receiverParty: idController.text.trim(),
              amount: withAmount
                  ? _amountController.text.replaceAll(',', '').trim()
                  : '1')));
    }
  }
}
