import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/core/constants/endpoints.dart';
import 'metadata_model.dart';

final metadataRepositoryProvider = Provider<MetadataRepository>((ref) {
  return MetadataRepository(ref.watch(dioClientProvider));
});

class MetadataRepository {
  final DioClient _dioClient;

  MetadataRepository(this._dioClient);
  Future<MetadataModel> extractMetadata(String url) async {
    print("Calling metadata API: ${Endpoints.extractMetadata}");
    print("URL: $url");

    final response = await _dioClient.post(
      Endpoints.extractMetadata,
      data: {'url': url},
    );

    print("Metadata response: ${response.data}");

    return MetadataModel.fromJson(response.data as Map<String, dynamic>);
  }
}
