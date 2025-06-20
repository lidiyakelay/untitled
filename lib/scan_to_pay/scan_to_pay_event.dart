import '../../../domain/entities/scan_to_pay/scan_to_pay_entity.dart';

abstract class ScanToPayEvent {}

class ScanToPayPrevalidationEvent extends ScanToPayEvent {
  final ScanToPayEntity entity;

  ScanToPayPrevalidationEvent(this.entity);
}
class ScanToPayMoneyEvent extends ScanToPayEvent {
  final ScanToPayEntity entity;

  ScanToPayMoneyEvent(this.entity);
}
