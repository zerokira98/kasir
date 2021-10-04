import 'dart:io';

import 'package:kasir/model/itemcard.dart';
import 'package:moor/ffi.dart';
import 'package:moor/moor.dart';
import 'package:path_provider/path_provider.dart';

import 'package:path/path.dart' as p;

part 'db_moor.g.dart';

class Stocks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get price => integer().withDefault(Constant(0))();
  IntColumn get qty => integer().withDefault(Constant(1))();
  DateTimeColumn get dateAdd => dateTime().nullable()();
  IntColumn get idItem =>
      integer().nullable().customConstraint('REFERENCES stockitems(id)')();
  IntColumn get idSupplier =>
      integer().nullable().customConstraint('REFERENCES tempatbelis(id)')();
}

class StockItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get barcode => integer().nullable()();
  TextColumn get nama => text().withLength(min: 3)();
}

class TempatBelis extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nama => text()();
}

class StockWithDetails {
  StockWithDetails(this.stock, this.item, this.tempatBeli);

  final Stock stock;
  final StockItem item;
  final TempatBeli tempatBeli;
  @override
  String toString() {
    return stock.toString() + item.nama + ' ' + tempatBeli.nama;
  }
}

LazyDatabase _openConnection() {
  // the LazyDatabase util lets us find the right location for the file async.
  return LazyDatabase(() async {
    // put the database file, called db.sqlite here, into the documents folder
    // for your app.
    final dbFolder = await getApplicationDocumentsDirectory();

    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return VmDatabase(file);
  });
}

@UseMoor(tables: [Stocks, StockItems, TempatBelis])
class MyDatabase extends _$MyDatabase {
  MyDatabase() : super(_openConnection());
  @override
  int get schemaVersion => 1;
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) {
          return m.createAll();
        },
        beforeOpen: (d) async {
          //aa
          if (d.wasCreated) {
            await into(tempatBelis)
                .insert(TempatBelisCompanion(nama: Value('')));
          }
        },
      );

  Future<List<StockItem>> get dataItem => select(stockItems).get();
  Future<List<Stock>> get dataStock => select(stocks).get();

  ///============
  Future<int> maxdataStock(
      {required DateTime startDate, required DateTime endDate}) {
    // var timenow = DateTime.now();
    // startDate = startDate ?? DateTime(timenow.year, timenow.month, 1);
    // endDate = endDate ??
    //     DateTime(timenow.year, timenow.month + 1, 1)
    //         .subtract(Duration(days: 1));
    var a = selectOnly(stocks);
    a.addColumns([stocks.id.count()]);
    a.where(stocks.dateAdd.isBiggerOrEqualValue(startDate) &
        stocks.dateAdd.isSmallerOrEqualValue(endDate));

    return a.map<int>((e) => e.read(stocks.id.count())).getSingle();
  }

  ///=========
  Future<List<TempatBeli>> tempatwithid(int id) =>
      (select(tempatBelis)..where((tbl) => tbl.id.equals(id))).get();

  ///====
  Future<List<StockWithDetails>> showStockwithDetails({
    int? idBarang,
    int? limit,
    int? page,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    ///----------Declare default variables
    var timenow = DateTime.now();
    startDate = startDate ?? DateTime(timenow.year, 1, 1);
    endDate = endDate ??
        DateTime(timenow.year, timenow.month + 1, 1)
            .subtract(Duration(days: 1));

    /// Return variable
    ///
    List<TypedResult> a;

    // int max = await ;
    if (idBarang == null) {
      var ab = (select(stocks)
            ..orderBy([
              (tbl) =>
                  OrderingTerm(expression: tbl.dateAdd, mode: OrderingMode.asc)
            ])
            ..where((tbl) =>
                tbl.dateAdd.isBiggerOrEqualValue(startDate) &
                stocks.dateAdd.isSmallerOrEqualValue(endDate)))
          .join([
        leftOuterJoin(stockItems, stocks.idItem.equalsExp(stockItems.id)),
        leftOuterJoin(tempatBelis, stocks.idSupplier.equalsExp(tempatBelis.id)),
      ]);
      if (limit != null) {
        ab.limit(
          limit,
          offset: page! * limit,
        );
      }
      a = await ab.get();
      // ab.where((stocks.dateAdd.isBiggerThan())
    } else {
      var b = (select(stocks)
            ..where((tbl) =>
                tbl.dateAdd.isBiggerOrEqualValue(startDate) &
                stocks.dateAdd.isSmallerOrEqualValue(endDate)))
          .join([
        leftOuterJoin(stockItems, stocks.idItem.equalsExp(stockItems.id)),
        leftOuterJoin(tempatBelis, stocks.idSupplier.equalsExp(tempatBelis.id)),
      ]);
      b.where(stocks.idItem.equals(idBarang));
      if (limit != null) {
        b.limit(
          limit,
          offset: page! * limit,
        );
      }
      a = await b.get();

      //  a= (select(stocks)..where((tbl) => tbl.idItem.equals(idBarang))).get();
    }
    return a
        .map((e) => StockWithDetails(
              e.readTable(stocks),
              e.readTable(stockItems),
              e.readTable(tempatBelis),
            ))
        .toList();
  }

  ///====
  Future<List<Stock>> showInsideStock({int? idBarang}) => idBarang == null
      ? select(stocks).get()
      : (select(stocks)..where((tbl) => tbl.idItem.equals(idBarang))).get();

  ///========
  Future<List<TempatBeli>> datatempat([String? query]) => query == null
      ? select(tempatBelis).get()
      : (select(tempatBelis)..where((tbl) => tbl.nama.contains(query))).get();

  ///========
  Future<List<StockItem>> showInsideItems([String? nama]) => nama == null
      ? select(stockItems).get()
      : (select(stockItems)..where((tbl) => tbl.nama.contains(nama))).get();

  ///========
  Future addItems(List<ItemCards> datas) async {
    for (var data in datas) {
      int tempatId;
      int? itemId = data.productId;

      if (data.productId == null) {
        var a = await (select(stockItems)
              ..where((tbl) => tbl.nama.equals(data.namaBarang!)))
            .get();
        if (a.isEmpty) {
          itemId = await into(stockItems).insert(StockItemsCompanion(
            nama: Value(data.namaBarang!),
            barcode:
                data.barcode == null ? Value.absent() : Value(data.barcode),
          ));
        } else {
          itemId = a.single.id;
        }
      }
      //---------get tempat id
      var aa = await (select(tempatBelis)
            ..where((tbl) => tbl.nama.equals(data.tempatBeli)))
          .get();
      if (aa.isEmpty) {
        tempatId = await into(tempatBelis)
            .insert(TempatBelisCompanion(nama: Value(data.tempatBeli!)));
      } else {
        tempatId = aa.single.id;
      }
      await into(stocks).insert(StocksCompanion(
        idItem: Value(itemId),
        idSupplier: Value(tempatId),
        price: Value(data.hargaBeli!),
        qty: Value(data.pcs!),
        dateAdd: Value(data.ditambahkan),
      ));
    }

    // var namaitem = 'Rokok Surya 12';
    // int? barcode;
    // var a = await (select(stockItems)
    //       ..where((tbl) => tbl.nama.equals(namaitem)))
    //     .get();
    // print(a);
    // if (a.isEmpty) {
    //   into(stockItems).insert(StockItemsCompanion(
    //       nama: Value(namaitem),
    //       barcode: barcode == null ? Value.absent() : Value(barcode)));
    // }else{

    // }
    // into(stocks).insert(StocksCompanion())
  }

  Future tempatinsert() async {
    into(tempatBelis).insert(TempatBelisCompanion(nama: Value('TOP')));
  }

  Future updateItemProp(
      productId, String nama, int? harga, int? barcode) async {
    return await (update(stockItems)..where((tbl) => tbl.id.equals(productId)))
        .write(
      StockItemsCompanion(
          nama: Value(nama),
          barcode: barcode == null
              ? Value.absent()
              : Value(
                  barcode,
                )),
    );
  }
}
