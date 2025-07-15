// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'company_bill_payment.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CompanyBillPaymentAdapter extends TypeAdapter<CompanyBillPayment> {
  @override
  final int typeId = 6;

  @override
  CompanyBillPayment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CompanyBillPayment(
      id: fields[0] as String,
      serverId: fields[1] as String?,
      billNo: fields[2] as String,
      amount: fields[3] as double,
      paymentMode: fields[4] as String,
      transactionType: fields[5] as String,
      remarks: fields[6] as String,
      siteId: fields[7] as String,
      transactionAt: fields[8] as DateTime,
      isSynced: fields[9] == null ? false : fields[9] as bool,
      attachmentPaths: (fields[10] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, CompanyBillPayment obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.serverId)
      ..writeByte(2)
      ..write(obj.billNo)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.paymentMode)
      ..writeByte(5)
      ..write(obj.transactionType)
      ..writeByte(6)
      ..write(obj.remarks)
      ..writeByte(7)
      ..write(obj.siteId)
      ..writeByte(8)
      ..write(obj.transactionAt)
      ..writeByte(9)
      ..write(obj.isSynced)
      ..writeByte(10)
      ..write(obj.attachmentPaths);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompanyBillPaymentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
