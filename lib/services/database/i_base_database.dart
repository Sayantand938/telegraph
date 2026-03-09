import 'package:sqflite/sqflite.dart';

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
