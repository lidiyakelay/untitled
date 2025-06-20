import 'package:equatable/equatable.dart';
import 'package:stardom/domain/entities/scan_to_pay/scan_to_pay_prevalidation_response_entity.dart';
import 'package:stardom/domain/entities/scan_to_pay/scan_to_pay_response_entity.dart';

abstract class ScanToPayState extends Equatable {}

class ScanToPayInitial extends ScanToPayState {
  @override
  List<Object?> get props => [];
}

// Global Loading state
class ScanToPayLoading extends ScanToPayState {
  @override
  List<Object?> get props => [];
}

class ScanToPayPrevalidationSuccess extends ScanToPayState {
  final ScanToPayPrevalidationResponseEntity? data;
  ScanToPayPrevalidationSuccess(this.data);
  @override
  List<Object?> get props => [data];
}

class ScanToPayPrevalidationFailure extends ScanToPayState {
  final ScanToPayPrevalidationResponseEntity? data;
  ScanToPayPrevalidationFailure(this.data);
  @override
  List<Object?> get props => [data];
}

class ScanToPayPrevalidationError extends ScanToPayState {
  final String error;
  ScanToPayPrevalidationError(this.error);
  @override
  List<Object?> get props => [error];
}

class ScanToPaySuccess extends ScanToPayState {
  final ScanToPayResponseEntity data;
  ScanToPaySuccess(this.data);
  @override
  List<Object?> get props => [data];
}

class ScanToPayFailure extends ScanToPayState {
  final String error;
  ScanToPayFailure(this.error);
  @override
  List<Object?> get props => [error];
}
