import 'package:flutter/material.dart';

import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/shared/models/generated_cv.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/shared/services/cv_api_service.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/empty_state.dart';
import 'package:sirati/shared/widgets/loading/branded_loader.dart';
import 'package:sirati/features/cv_builder/presentation/generated_cv_screen.dart';

/// Deep-link entry for `/cv/:id` — loads the CV then shows the real screen.
class GeneratedCvLoaderScreen extends StatefulWidget {
  final int cvId;

  const GeneratedCvLoaderScreen({super.key, required this.cvId});

  @override
  State<GeneratedCvLoaderScreen> createState() =>
      _GeneratedCvLoaderScreenState();
}

class _GeneratedCvLoaderScreenState extends State<GeneratedCvLoaderScreen> {
  late Future<GeneratedCv> _future;

  @override
  void initState() {
    super.initState();
    _future = CvApiService().getGeneratedCv(widget.cvId);
  }

  @override
  Widget build(BuildContext context) {
    final english = AppLocale.isEnglish(context);
    return FutureBuilder<GeneratedCv>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return GeneratedCvScreen(generatedCv: snapshot.data!);
        }
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: context.sirati.background,
            appBar: AppBar(),
            body: AppErrorState(
              english: english,
              message: snapshot.error is ApiException
                  ? (snapshot.error as ApiException).displayMessage
                  : (english
                      ? 'Could not open this CV.'
                      : 'تعذر فتح هذه السيرة.'),
              onRetry: () {
                setState(() {
                  _future = CvApiService().getGeneratedCv(widget.cvId);
                });
              },
            ),
          );
        }
        return const Scaffold(
          body: Center(child: BrandedLoader()),
        );
      },
    );
  }
}
