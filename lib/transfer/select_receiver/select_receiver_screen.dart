import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:stardom/core/utils/extensions/context_extensions.dart';
import 'package:stardom/data/datasources/local/transaction_local_data_source.dart';
import 'package:stardom/domain/entities/auth/user_data.dart';
import 'package:stardom/domain/entities/send_money/send_money_prevalidation_entity.dart';
import 'package:stardom/domain/repositories/auth_repository.dart';
import 'package:stardom/presentation/state_management/send_money/send_money_bloc.dart';
import 'package:stardom/presentation/state_management/send_money/send_money_event.dart';
import 'package:stardom/presentation/state_management/send_money/send_money_state.dart';
import 'package:stardom/presentation/widgets/base_screen.dart';
import 'package:stardom/presentation/widgets/buttons/primary_button.dart';
import 'package:stardom/presentation/widgets/cards/transaction_card.dart';
import 'package:stardom/presentation/widgets/input_field/custom_input.dart';

import '../../../../app/di/injector.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/utils/constants/colors.dart';
import '../../../../core/utils/constants/sizes.dart';
import '../../../widgets/custom_dialog_box.dart';
import '../../home/home.dart';

class SelectReceiverScreen extends StatefulWidget {
  const SelectReceiverScreen({super.key});

  @override
  State<SelectReceiverScreen> createState() => _SelectReceiverScreenState();
}

class _SelectReceiverScreenState extends State<SelectReceiverScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController idController = TextEditingController();
  final userRepository = sl<AuthRepository>();

  List<Transaction> transactionsList = [];
  bool _isButtonEnabled = false;

  Future<void> getTransactions() async {
    final transactionDataSource = sl<TransactionLocalDataSource>();

    // Fetch transactions for both types
    final mpesaTransactions =
        await transactionDataSource.getTransactionsByType('M-PESA');
    final merchantTransactions =
        await transactionDataSource.getTransactionsByType('M-PESA-MERCHANT');

    // Debugging prints
    print("M-PESA Transactions: ${mpesaTransactions.length}");
    print("M-PESA-Merchant Transactions: ${merchantTransactions.length}");

    if (merchantTransactions.isNotEmpty) {
      print(
          "Latest M-PESA-Merchant Transaction: ${merchantTransactions.first.toMap()}");
    }

    // Merge both lists
    final allTransactions = [...mpesaTransactions, ...merchantTransactions];

    // Sort by `createdAt` in descending order (latest first)
    allTransactions.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));

    // Keep only the top 5 latest transactions
    final latestTransactions = allTransactions.take(5).toList();

    setState(() {
      transactionsList = latestTransactions;
    });

    print(
        "Final Transactions List: ${latestTransactions.map((t) => t.toMap()).toList()}");
  }

  @override
  void initState() {
    super.initState();
    getTransactions();
  }

  void _onFormChanged() {
    setState(() {
      _isButtonEnabled = _formKey.currentState?.validate() ?? false;
    });
  }

  customerPrevalidation() async {
    User? user = await userRepository.getLocalUser();
    if (user != null && idController.text.trim().length < 13) {
      if (idController.text.trim().length >= 9) {
        BlocProvider.of<SendMoneyBloc>(context).add(SendMoneyPrevalidationEvent(
            SendMoneyPrevalidationEntity(
                initiator: user.msisdn,
                receiverParty: idController.text.trim(),
                amount: '0')));
      } else {
        BlocProvider.of<SendMoneyBloc>(context).add(
            PayForMerchantPrevalidationEvent(SendMoneyPrevalidationEntity(
                initiator: user.msisdn,
                receiverParty: idController.text.trim(),
                amount: '0')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
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
                        'send_money_prevalidation_dialog_retry'),
              ));
              return;
            }
            context.pushNamed(AppRoutes.transactionDetails, pathParameters: {
              'identityFullName': state.data!.identityFullName,
              'id': idController.text.trim()
            });
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
                        'pay_merchant_prevalidation_dialog_retry'),
              ));
              return;
            }
            context.pushNamed(AppRoutes.transactionDetails, pathParameters: {
              'identityFullName': state.data!.identityFullName,
              'id': idController.text.trim()
            });
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
                  analyticsButtonName: 'send_money_prevalidation_dialog_retry'),
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
                  analyticsButtonName:
                      'pay_merchant_prevalidation_dialog_retry'),
            ));
          }
        },
        child: Form(
          key: _formKey,
          onChanged: _onFormChanged,
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
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(12),
                  ],
                  labelText: context.strings().phone_or_id,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.strings().phone_or_id_required;
                    }
                    return null;
                  },
                ),
                SizedBox(height: size.height * 0.01),
                PrimaryButton(
                  text: context.strings().next_button,
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      customerPrevalidation();
                    }
                  },
                  enabled: _isButtonEnabled,
                  analyticsButtonName: 'transfer_select_receiver_next',
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
