import 'package:sqflite/sqflite.dart';
import 'package:telegraph/models/session.dart';
import 'package:telegraph/models/finance_transaction.dart';

abstract class IBaseDatabase<T> {
  Future<Database> get database;
  Future<void> reinitialize();
  Future<int> create(T model);
  Future<T?> get(int id);
  Future<List<T>> getAll();
  Future<int> update(T model);
  Future<int> delete(int id);
  Future<void> close();
}
