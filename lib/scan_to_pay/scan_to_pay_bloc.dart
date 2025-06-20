import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stardom/app/di/injector.dart';
import 'package:stardom/core/services/analytics_service.dart';
import 'package:stardom/core/services/context_service.dart';
import 'package:stardom/core/services/event_service.dart';
import 'package:stardom/core/utils/extensions/context_extensions.dart';
import 'package:stardom/presentation/state_management/scan_to_pay/scan_to_pay_event.dart';
import 'package:stardom/presentation/state_management/scan_to_pay/scan_to_pay_state.dart';

import '../../../domain/usecases/scan_to_pay/scan_to_pay_prevalidation_usecase.dart';
import '../../../domain/usecases/scan_to_pay/scan_to_pay_usecase.dart';

class ScanToPayBloc extends Bloc<ScanToPayEvent, ScanToPayState> {
  final ScanToPayPrevalidationUseCase scanToPayPrevalidationUseCase;
  final ScanToPayUseCase scanToPayUseCase;

  final BuildContext? context = sl<ContextService>().context;
  final analyticsService = sl<AnalyticsService>();

  ScanToPayBloc({required this.scanToPayPrevalidationUseCase, required this.scanToPayUseCase})
      : super(ScanToPayInitial()) {
    on<ScanToPayPrevalidationEvent>(_onScanToPayPrevalidation);
    on<ScanToPayMoneyEvent>(_onScanToPay);
  }

  // 🔹 Send Money Prevalidation
  Future<void> _onScanToPayPrevalidation(ScanToPayPrevalidationEvent event, Emitter<ScanToPayState> emit) async {
    emit(ScanToPayLoading()); // Emit loading state
    print('here we go 1');

    try {
      print('here we go 3');

      final result = await scanToPayPrevalidationUseCase.call(event.entity);
      if (result?.responseCode == '0') {
        emit(ScanToPayPrevalidationSuccess(result)); // Emit success state
        analyticsService.logCustomEvent(name: 'scan_to_pay_prevalidation', parameters: {
          'status': 'prevalidation_success',
        });
        saveEventTOStorage(
          'scan_to_pay_prevalidation',
          "prevalidation_success, status: completed",
        );
      } else {
        emit(ScanToPayPrevalidationFailure(result)); // Emit failure state
        analyticsService.logCustomEvent(name: 'scan_to_pay_prevalidation', parameters: {
          'status': 'prevalidation_failure',
        });
        saveEventTOStorage(
          'scan_to_pay_prevalidation',
          "prevalidation_failure, status: error",
        );
      }
    } catch (e) {
      emit(ScanToPayPrevalidationError("Error: $e")); // Emit failure state on error
      analyticsService.logCustomEvent(name: 'scan_to_pay_prevalidation', parameters: {
        'status': 'error',
      });
      saveEventTOStorage(
        'scan_to_pay_prevalidation',
        "prevalidation_failure, status: error",
      );
    }
  }

  Future<void> _onScanToPay(ScanToPayMoneyEvent event, Emitter<ScanToPayState> emit) async {
    emit(ScanToPayLoading()); // Emit loading state
    try {
      final result = await scanToPayUseCase.call(event.entity);
      if (result?.responseCode == '0' || result?.responseCode == 'SVC0437') {
        emit(ScanToPaySuccess(result!)); // Emit success state
        analyticsService.logCustomEvent(name: 'scan_to_pay', parameters: {
          'status': 'payment_success',
        });
        analyticsService.logPurchase(
          itemName: 'Scan to Pay',
          value: double.tryParse(event.entity.amount) ?? 0,
          parameters: {
            'bank': event.entity.bankName,
            'bic': event.entity.bic,
            'status': 'scan_to_pay_success',
          },
        );
        saveEventTOStorage(
          'scan_to_pay',
          "payment_success to bank:${event.entity.bankName}, status: completed",
        );
      } else {
        emit(ScanToPayFailure(
            context != null ? context!.strings().payment_failed : "Payment failed")); // Emit failure state
        analyticsService.logCustomEvent(name: 'scan_to_pay', parameters: {
          'bank': event.entity.bankName,
          'bic': event.entity.bic,
          'status': 'payment_failure',
        });
        saveEventTOStorage(
          'scan_to_pay',
          "payment_failure to bank:${event.entity.bankName}, status: completed",
        );
      }
    } catch (e) {
      emit(ScanToPayFailure(
          context != null ? context!.strings().error_occurred : 'Error occurred')); // Emit failure state on error
      analyticsService.logCustomEvent(name: 'scan_to_pay', parameters: {
        'status': 'error',
      });
      saveEventTOStorage(
        'scan_to_pay',
        "payment_failure to bank:${event.entity.bankName}, status: completed",
      );
    }
  }
}
