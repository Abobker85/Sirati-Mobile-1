import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sirati/features/cv_builder/data/cv_repository.dart';

/// Storage for builder CVs; tests override it with an in-memory engine.
final cvRepositoryProvider =
    Provider<CvRepository>((ref) => LocalCvRepository());
