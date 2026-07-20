import 'package:http/http.dart' as http;

import '../models/cv_analysis.dart';
import '../models/cv_template.dart';
import '../models/generated_cv.dart';
import 'api_client.dart';
import 'auth_token_store.dart';

class CvApiService {
  CvApiService({ApiClient? apiClient})
      : _apiClient = apiClient ??
            ApiClient(tokenProvider: const AuthTokenStore().readToken);

  final ApiClient _apiClient;

  Future<CvAnalysis> submitAnalysis({
    required String targetJobTitle,
    required String resumeText,
    http.MultipartFile? resumeFile,
  }) async {
    final response = await _apiClient.postMultipart(
      '/cv-analyses',
      fields: {
        'target_job_title': targetJobTitle,
        if (resumeText.trim().isNotEmpty) 'resume_text': resumeText.trim(),
      },
      file: resumeFile,
    );

    return CvAnalysis.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<CvAnalysis> getAnalysis(int id) async {
    final response = await _apiClient.getJson('/cv-analyses/$id');
    return CvAnalysis.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<List<CvAnalysis>> listAnalyses() async {
    final response = await _apiClient.getJson('/cv-analyses');
    return (response['data'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(CvAnalysis.fromJson)
        .toList();
  }

  Future<GeneratedCv> generateCv(Map<String, dynamic> payload) async {
    final response = await _apiClient.postJson('/generated-cvs', payload);
    return GeneratedCv.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> enhanceJobDescription({
    required String targetJobTitle,
    required String jobDescription,
    required String language,
  }) async {
    final response = await _apiClient.postJson(
      '/generated-cvs/enhance-job-description',
      {
        'target_job_title': targetJobTitle,
        'job_description': jobDescription,
        'language': language,
      },
    );

    final data = response['data'];
    return data is Map<String, dynamic> ? data : const {};
  }

  Future<GeneratedCv> updateGeneratedCv(
    int id,
    Map<String, dynamic> payload,
  ) async {
    final response = await _apiClient.putJson('/generated-cvs/$id', payload);
    return GeneratedCv.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> deleteGeneratedCv(int id) async {
    await _apiClient.deleteJson('/generated-cvs/$id');
  }

  Future<GeneratedCv> generateCvFromAnalysis({
    required int analysisId,
    required Map<String, dynamic> overrides,
  }) async {
    final response = await _apiClient.postJson(
      '/cv-analyses/$analysisId/generated-cv',
      overrides,
    );

    return GeneratedCv.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<GeneratedCv> getGeneratedCv(int id) async {
    final response = await _apiClient.getJson('/generated-cvs/$id');
    return GeneratedCv.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<List<GeneratedCv>> listGeneratedCvs() async {
    final response = await _apiClient.getJson('/generated-cvs');
    return (response['data'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(GeneratedCv.fromJson)
        .toList();
  }

  Future<List<CvTemplate>> listCvTemplates({required bool english}) async {
    final response = await _apiClient.getJson(
      '/mobile/cv-templates?lang=${english ? 'en' : 'ar'}',
    );
    final data = response['data'];
    final items = data is Map<String, dynamic> ? data['items'] : null;

    return (items as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(CvTemplate.fromJson)
        .where((template) => template.slug.isNotEmpty)
        .toList();
  }

  String pdfUrlForTemplate(GeneratedCv cv, String? templateSlug) {
    final templateBaseUrl = cv.templatePdfUrl ?? '';
    if (templateSlug == null ||
        templateSlug.isEmpty ||
        templateBaseUrl.isEmpty) {
      return templateBaseUrl.isNotEmpty ? templateBaseUrl : cv.pdfUrl ?? '';
    }

    final uri = Uri.parse(templateBaseUrl);
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      'template': templateSlug,
    }).toString();
  }
}
