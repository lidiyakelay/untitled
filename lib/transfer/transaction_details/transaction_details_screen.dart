import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:stardom/app/routes/app_routes.dart';
import 'package:stardom/core/utils/extensions/context_extensions.dart';
import 'package:stardom/core/utils/extensions/string_extensions.dart';
import 'package:stardom/domain/repositories/auth_repository.dart';
import 'package:stardom/domain/repositories/send_money_repository.dart';
import 'package:stardom/presentation/state_management/auth/auth_bloc.dart';
import 'package:stardom/presentation/state_management/auth/auth_event.dart';
import 'package:stardom/presentation/state_management/auth/auth_state.dart';
import 'package:stardom/presentation/widgets/base_screen.dart';
import 'package:stardom/presentation/widgets/buttons/secondary_button.dart';

import '../../../../app/di/injector.dart';
import '../../../../core/utils/constants/colors.dart';
import '../../../../core/utils/constants/sizes.dart';
import '../../../../domain/entities/auth/user_data.dart';
import '../../../../domain/entities/send_money/send_money_prevalidation_entity.dart';
import '../../../../domain/entities/send_money/send_money_prevalidation_response_entity.dart';
import '../../../state_management/send_money/send_money_bloc.dart';
import '../../../state_management/send_money/send_money_event.dart';
import '../../../state_management/send_money/send_money_state.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../../../widgets/cards/transaction_card.dart';
import '../../../widgets/custom_dialog_box.dart';
import '../../../widgets/dialog/overdraft_dialog.dart';
import '../../../widgets/input_field/custom_input.dart';
import '../../home/home.dart';

class TransactionDetailsScreen extends StatefulWidget {
  final String identityFullName;
  final String id;

  const TransactionDetailsScreen(
      {super.key, required this.identityFullName, required this.id});

  @override
  State<TransactionDetailsScreen> createState() =>
      _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final userRepository = sl<AuthRepository>();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController additionalNotesController =
      TextEditingController();
  late User user;
  String balance = '--';

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
    BlocProvider.of<AuthBloc>(context).stream.listen((state) {
      if (state is BalanceFetched) {
        if (mounted) {
          setState(() {
            balance = state.mpesaBalance.formatCurrency();
          });
        }
      }
    });
    BlocProvider.of<AuthBloc>(context).add(FetchBalanceEvent());
  }

  customerPrevalidation() async {
    widget.id.length >= 9
        ? BlocProvider.of<SendMoneyBloc>(context).add(
            SendMoneyPrevalidationEvent(SendMoneyPrevalidationEntity(
                initiator: user.msisdn,
                receiverParty: widget.id,
                amount: amountController.text.trim())))
        : BlocProvider.of<SendMoneyBloc>(context).add(
            PayForMerchantPrevalidationEvent(SendMoneyPrevalidationEntity(
                initiator: user.msisdn,
                receiverParty: widget.id,
                amount: amountController.text.trim())));
  }

  backUp() async {
    if (widget.id.length >= 9) {
      context.showLoading();
      final result = await sl<SendMoneyRepository>().sendMoneyPrevalidation(
          SendMoneyPrevalidationEntity(
              initiator: user.msisdn,
              receiverParty: widget.id,
              amount: amountController.text.trim()));
      context.hideLoading();
      print(result?.responseCode);
      print(result?.responseDescription);
      if (result!.responseCode == 'TPCHODTS28009') {
        context.showDialogBox(CustomDialogBox(
          dialogTitle: context.strings().overdraft_register_title,
          dialogDescription: context.strings().overdraft_register_desc,
          primaryButton: PrimaryButton(
            text: context.strings().continue_button,
            enabled: true,
            onPressed: () {
              context.pop();
              context.pushNamed(AppRoutes.activateOverDraftScreen);
            },
            analyticsButtonName:
                'package_airtime_register_overdraft_dialog_continue',
          ),
          secondaryButton: SecondaryButton(
            text: context.strings().cancel_button,
            enabled: true,
            onPressed: () {
              context.pop();
            },
            analyticsButtonName:
                'package_airtime_register_overdraft_dialog_cancel',
          ),
        ));
      }
      if (result.responseCode == '2044') {
        context.showDialogBox(CustomDialogBox(
          dialogTitle: context.strings().recipient_same,
          primaryButton: PrimaryButton(
            text: context.strings().close_button,
            onPressed: () {
              context.pop();
            },
            enabled: true,
            analyticsButtonName: 'transfer_recipient_same_dialog_close',
          ),
        ));
      }
      if (result.responseCode == '0') {
        context.pushNamed(
          AppRoutes.confirmTransaction,
          queryParameters: {
            'identityFullName': widget.identityFullName,
            'id': widget.id,
            'channelSessionId': result.channelSessionId ?? '',
            'amount': amountController.text.trim(),
            'remark': additionalNotesController.text.trim(),
            'transactionFee': result.transactionCharge ?? '0',
          },
        );
      }
    } else {
      context.showLoading();
      final result = await sl<SendMoneyRepository>()
          .payForMerchantPrevalidation(SendMoneyPrevalidationEntity(
              initiator: user.msisdn,
              receiverParty: widget.id,
              amount: amountController.text.trim()));
      context.hideLoading();
      if (result!.responseCode == 'TPCHODTS28009') {
        context.showDialogBox(CustomDialogBox(
          dialogTitle: context.strings().balance_insufficient,
          primaryButton: PrimaryButton(
            text: context.strings().close_button,
            onPressed: () {
              context.pop();
            },
            enabled: true,
            analyticsButtonName: 'transfer_balance_insufficient_dialog_close',
          ),
        ));
      }
      if (result.responseCode == '0') {
        context.pushNamed(
          AppRoutes.confirmTransaction,
          queryParameters: {
            'identityFullName': widget.identityFullName,
            'id': widget.id,
            'channelSessionId': result.channelSessionId ?? '',
            'amount': amountController.text.trim(),
            'remark': additionalNotesController.text.trim(),
            'transactionFee': result.transactionCharge ?? '0',
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return BaseScreen(
      allowResize: true,
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
          Text(context.strings().transfer,
              style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
      content: BlocListener<SendMoneyBloc, SendMoneyState>(
        listenWhen: (previous, current) {
          return ModalRoute.of(context)?.isCurrent ?? false;
        },
        listener: (context, state) {
          if (state is SendMoneyLoading) {
            context.showLoading();
          }
          if (state is SendMoneyPrevalidationSuccess) {
            context.hideLoading();
            print("------details channel session id-----");
            print(state.data?.channelSessionId);
            print(state.data?.transactionCharge);
            if (state.data?.responseCode == 'TPCHODTS28009') {
              context.showDialogBox(CustomDialogBox(
                dialogTitle: context.strings().overdraft_register_title,
                dialogDescription: context.strings().overdraft_register_desc,
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
                  analyticsButtonName: 'send_money_prevalidation_dialog_retry',
                ),
              ));
              return;
            } else if (state.data?.responseCode != '0') {
              context.showDialogBox(CustomDialogBox(
                dialogTitle: context.strings().error_validation_failed,
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
            }
            context.pushNamed(
              AppRoutes.confirmTransaction,
              queryParameters: {
                'identityFullName': widget.identityFullName,
                'id': widget.id,
                'channelSessionId': state.data!.channelSessionId ?? '',
                'amount': amountController.text.trim(),
                'remark': additionalNotesController.text.trim(),
                'transactionFee': state.data!.transactionCharge ?? '0',
              },
            );
          }
          if (state is PayForMerchantPrevalidationSuccess) {
            context.hideLoading();
            if (state.data?.responseCode == 'TPCHODTS28009') {
              context.showDialogBox(CustomDialogBox(
                dialogTitle: context.strings().overdraft_register_title,
                dialogDescription: context.strings().overdraft_register_desc,
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
                dialogTitle: context.strings().credit_limit_is_insufficient,
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
                    orElse: () =>
                        SendMoneyAdditionalInfo(key: 'UseODAmount', value: ''),
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
                      'identityFullName': widget.identityFullName,
                      'id': widget.id,
                      'channelSessionId': state.data!.channelSessionId ?? '',
                      'amount': amountController.text.trim(),
                      'remark': additionalNotesController.text.trim(),
                      'transactionFee': state.data!.transactionCharge ?? '0',
                      'useOD': 'true',
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
                  analyticsButtonName: 'send_money_prevalidation_dialog_retry',
                ),
              ));
              return;
            } else if (state.data?.responseCode != '0') {
              context.showDialogBox(CustomDialogBox(
                dialogTitle: context.strings().error_validation_failed,
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
            }

            context.pushNamed(
              AppRoutes.confirmTransaction,
              queryParameters: {
                'identityFullName': widget.identityFullName,
                'id': widget.id,
                'channelSessionId': state.data!.channelSessionId ?? '',
                'amount': amountController.text.trim(),
                'remark': additionalNotesController.text.trim(),
                'transactionFee': state.data!.transactionCharge ?? '0',
              },
            );
          }
          if (state is SendMoneyPrevalidationFailure) {
            context.hideLoading();
            context.showDialogBox(CustomDialogBox(
              dialogTitle: state.error,
              primaryButton: PrimaryButton(
                text: context.strings().retry_button,
                onPressed: () {
                  context.pop();
                },
                enabled: true,
                analyticsButtonName: 'send_money_prevalidation_dialog_retry',
              ),
            ));
          }
          if (state is PayForMerchantFailure) {
            context.hideLoading();
            context.showDialogBox(CustomDialogBox(
              dialogTitle: state.error,
              primaryButton: PrimaryButton(
                text: context.strings().retry_button,
                onPressed: () {
                  context.pop();
                },
                enabled: true,
                analyticsButtonName: 'pay_merchant_prevalidation_dialog_retry',
              ),
            ));
          }
        },
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: size.height * 0.02,
              ),
              TransactionCard(
                title: widget.identityFullName,
                subtitle: widget.id,
              ),
              SizedBox(height: size.height * 0.02),
              CustomInput(
                  controller: amountController,
                  labelInline: true,
                  labelText: context.strings().amount,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  validator: (value) {
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
                  helper: Text(
                      '${context.strings().available_balance} : $balance',
                      style: Theme.of(context).textTheme.bodySmall)),
              // CustomInput(
              //   controller: additionalNotesController,
              //   labelInline: true,
              //   labelText: context.strings().additional_notes,
              //   suffix: const Icon(Icons.cancel_outlined),
              //   validator: (value) {
              //     if (value == null || value.isEmpty) {
              //       return context.strings().additional_notes_required;
              //     }
              //     return null;
              //   },
              // ),
              const Spacer(),
              PrimaryButton(
                text: context.strings().next_button,
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    customerPrevalidation();
                  }
                },
                enabled: true,
                analyticsButtonName: 'transfer_details_next',
              )
            ],
          ),
        ),
      ),
    );
  }
}
