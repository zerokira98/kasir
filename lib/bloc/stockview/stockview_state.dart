part of 'stockview_bloc.dart';

abstract class StockviewState extends Equatable {
  const StockviewState();

  @override
  List<Object> get props => [];
}

class StockviewInitial extends StockviewState {}

class StockviewLoading extends StockviewState {}

class StockviewLoaded extends StockviewState {
  final Filter filter;
  final List<ItemCards> datas;
  final String? message;
  StockviewLoaded({required this.filter, required this.datas, this.message}) {
    // this.message = message??'';
  }
  @override
  List<Object> get props => [filter, datas];
}

class Filter extends Equatable {
  final String? nama;
  final String? tempatBeli;
  final int? barcode;
  final int currentPage;
  final int maxRow;
  final DateTime startDate;
  final DateTime endDate;
  Filter(
      {this.nama,
      this.tempatBeli,
      this.barcode,
      required this.currentPage,
      required this.maxRow,
      required this.startDate,
      required this.endDate});
  Filter copyWith({
    String? nama,
    String? tempatBeli,
    int? currentPage,
    int? maxRow,
    DateTime? startDate,
    DateTime? endDate,
    int? barcode,
  }) {
    return Filter(
      nama: nama ?? this.nama,
      tempatBeli: tempatBeli ?? this.tempatBeli,
      barcode: barcode ?? this.barcode,
      currentPage: currentPage ?? this.currentPage,
      maxRow: maxRow ?? this.maxRow,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  @override
  List<Object?> get props =>
      [nama, tempatBeli, currentPage, maxRow, startDate, endDate, barcode];
}
