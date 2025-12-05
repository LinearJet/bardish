import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/note.dart';
import 'ai_service.dart';

class RagService {
  static const int _largeNoteThreshold = 20000; // Characters
  static const int _chunkSize = 1000;
  static const int _chunkOverlap = 200;
  static const int _topK = 5;

  final AiService _aiService = AiService();
  Box? _ragCacheBox;

  Future<Box> _getBox() async {
    if (_ragCacheBox != null && _ragCacheBox!.isOpen) {
      return _ragCacheBox!;
    }
    _ragCacheBox = await Hive.openBox('rag_cache');
    return _ragCacheBox!;
  }

  Future<String> getRelevantContext(
    Note note,
    String query, {
    required AiProvider provider,
    String? apiKey,
    String? baseUrl,
    String? modelName,
  }) async {
    // 1. Simple case: Small note
    if (note.content.length <= _largeNoteThreshold) {
      return note.content;
    }

    // 2. Check capabilities
    // Only OpenAI, Gemini, Ollama support embeddings in our implementation
    if (!_supportsEmbeddings(provider)) {
      return note.content; // Fallback to full content if embeddings not supported
    }

    try {
      // 3. Ensure embeddings are ready
      await _ensureEmbeddings(note, provider, apiKey, baseUrl, modelName);

      // 4. Retrieve relevant chunks
      return await _retrieveChunks(note, query, provider, apiKey, baseUrl, modelName);
    } catch (e) {
      print('RAG Error: $e');
      // Fallback to full content on error (or maybe truncated)
      // Returning full content might be risky if it's HUGE, but better than nothing.
      // Or maybe return a truncated version.
      if (note.content.length > 100000) {
        return note.content.substring(0, 100000) + "\n...(truncated)";
      }
      return note.content;
    }
  }

  bool _supportsEmbeddings(AiProvider provider) {
    return provider == AiProvider.openai || 
           provider == AiProvider.gemini || 
           provider == AiProvider.ollama;
  }

  Future<void> _ensureEmbeddings(
    Note note,
    AiProvider provider,
    String? apiKey,
    String? baseUrl,
    String? modelName,
  ) async {
    final box = await _getBox();
    final cached = box.get(note.id);
    
    // Check if cache is valid
    if (cached != null) {
      final DateTime cachedTime = DateTime.parse(cached['updatedAt']);
      // If note hasn't changed, we are good.
      // Note: We compare with note.updatedAt. 
      // Also technically if provider/model changes, embeddings might be invalid (different dimension).
      // For simplicity, we assume user sticks to one embedding provider or we invalidate if dimension mismatch.
      // Let's just check timestamp for now.
      if (cachedTime.isAtSameMomentAs(note.updatedAt)) {
        return;
      }
    }

    // Generate new embeddings
    final chunks = _splitText(note.content);
    final List<Map<String, dynamic>> embeddedChunks = [];

    for (var chunk in chunks) {
      // Rate limiting might be needed here for OpenAI/Gemini
      await Future.delayed(const Duration(milliseconds: 100)); 
      
      try {
        final vector = await _aiService.getEmbedding(
          chunk,
          provider,
          apiKey: apiKey,
          baseUrl: baseUrl,
          modelName: modelName,
        );
        embeddedChunks.add({
          'text': chunk,
          'vector': vector,
        });
      } catch (e) {
        print('Error embedding chunk: $e');
        // Continue? or fail?
      }
    }

    await box.put(note.id, {
      'updatedAt': note.updatedAt.toIso8601String(),
      'chunks': embeddedChunks,
      'provider': provider.name, // Store provider to potentially invalidate later
    });
  }

  Future<String> _retrieveChunks(
    Note note,
    String query,
    AiProvider provider,
    String? apiKey,
    String? baseUrl,
    String? modelName,
  ) async {
    final box = await _getBox();
    final queryVector = await _aiService.getEmbedding(
      query,
      provider,
      apiKey: apiKey,
      baseUrl: baseUrl,
      modelName: modelName,
    );

    final cached = box.get(note.id);
    final List<dynamic> storedChunks = cached['chunks'];

    // Calculate similarities
    final List<Map<String, dynamic>> scoredChunks = [];

    for (var chunkData in storedChunks) {
      final List<double> chunkVector = List<double>.from(chunkData['vector']);
      final score = _cosineSimilarity(queryVector, chunkVector);
      scoredChunks.add({
        'text': chunkData['text'],
        'score': score,
      });
    }

    // Sort by score descending
    scoredChunks.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

    // Take top K
    final topChunks = scoredChunks.take(_topK).map((c) => c['text'] as String).toList();

    return topChunks.join('\n\n... (context gap) ...\n\n');
  }

  List<String> _splitText(String text) {
    final List<String> chunks = [];
    int start = 0;
    
    while (start < text.length) {
      int end = start + _chunkSize;
      if (end > text.length) {
        end = text.length;
      } else {
        // Try to find a space to break at
        final lastSpace = text.lastIndexOf(' ', end);
        if (lastSpace != -1 && lastSpace > start) {
          end = lastSpace;
        }
      }
      
      chunks.add(text.substring(start, end).trim());
      
      start = end - _chunkOverlap;
      if (start >= text.length) break;
    }
    return chunks;
  }

  double _cosineSimilarity(List<double> v1, List<double> v2) {
    if (v1.length != v2.length) return 0.0;

    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;

    for (int i = 0; i < v1.length; i++) {
      dotProduct += v1[i] * v2[i];
      norm1 += v1[i] * v1[i];
      norm2 += v2[i] * v2[i];
    }

    norm1 = sqrt(norm1);
    norm2 = sqrt(norm2);

    if (norm1 == 0 || norm2 == 0) return 0.0;

    return dotProduct / (norm1 * norm2);
  }
}
