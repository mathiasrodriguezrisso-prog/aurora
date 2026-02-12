/// Implementación del repositorio de Climate Analytics.
library;

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/climate_analysis_entity.dart';
import '../../domain/entities/climate_current_entity.dart';
import '../../domain/entities/climate_history_entity.dart';
import '../../domain/entities/climate_reading_entity.dart';
import '../../domain/repositories/climate_repository.dart';
import '../datasources/climate_remote_datasource.dart';
import '../models/climate_analysis_model.dart';
import '../models/climate_current_model.dart';
import '../models/climate_history_model.dart';
import '../models/climate_reading_model.dart';

class ClimateRepositoryImpl implements ClimateRepository {
  final ClimateRemoteDataSource _dataSource;

  ClimateRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, ClimateReadingEntity>> addReading({
    required String growId,
    required double temperature,
    required double humidity,
    double? ph,
    double? ec,
    bool watered = false,
    String? notes,
  }) async {
    try {
      final data = {
        'grow_id': growId,
        'temperature': temperature,
        'humidity': humidity,
        if (ph != null) 'ph': ph,
        if (ec != null) 'ec': ec,
        'watered': watered,
        if (notes != null) 'notes': notes,
      };

      final response = await _dataSource.addReading(data);
      final model = ClimateReadingModel.fromJson(response);
      return Right(model);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ClimateCurrentEntity>> getCurrent(String growId) async {
    try {
      final response = await _dataSource.getCurrent(growId);
      final model = ClimateCurrentModel.fromJson(response);
      return Right(model);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ClimateHistoryEntity>> getHistory(
    String growId, {
    int days = 7,
  }) async {
    try {
      final response = await _dataSource.getHistory(growId, days: days);
      final model = ClimateHistoryModel.fromJson(response);
      return Right(model);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ClimateAnalysisEntity>> getAnalysis(String growId) async {
    try {
      final response = await _dataSource.getAnalysis(growId);
      final model = ClimateAnalysisModel.fromJson(response);
      return Right(model);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
