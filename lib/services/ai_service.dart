import 'dart:convert';
import 'package:http/http.dart' as http;

enum AiProvider {
  openai,
  anthropic,
  gemini,
  ollama,
  openRouter,
  custom,
}

class AiService {
  static const String _openAiBaseUrl = 'https://api.openai.com/v1';
  static const String _geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  static const String _openRouterBaseUrl = 'https://openrouter.ai/api/v1';

  Future<List<String>> getModels(
    AiProvider provider, {
    String? apiKey,
    String? baseUrl,
  }) async {
    try {
      switch (provider) {
        case AiProvider.openai:
          return _fetchOpenAiModels(apiKey!);
        case AiProvider.anthropic:
          // Anthropic does not provide a public list models endpoint in the same way.
          // Returning a curated list of recent models.
          return [
            'claude-3-5-sonnet-20240620',
            'claude-3-opus-20240229',
            'claude-3-sonnet-20240229',
            'claude-3-haiku-20240307',
          ];
        case AiProvider.gemini:
          return _fetchGeminiModels(apiKey!);
        case AiProvider.ollama:
          return _fetchOllamaModels(baseUrl ?? 'http://localhost:11434');
        case AiProvider.openRouter:
          return _fetchOpenRouterModels(apiKey!);
        case AiProvider.custom:
          return _fetchCustomModels(baseUrl!, apiKey);
      }
    } catch (e) {
      print('Error fetching models for $provider: $e');
      throw e;
    }
  }

  Future<List<String>> _fetchOpenAiModels(String apiKey) async {
    final response = await http.get(
      Uri.parse('$_openAiBaseUrl/models'),
      headers: {'Authorization': 'Bearer $apiKey'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> models = data['data'];
      return models.map((m) => m['id'] as String).toList()..sort();
    } else {
      throw Exception('Failed to load OpenAI models: ${response.statusCode} ${response.body}');
    }
  }

  Future<List<String>> _fetchGeminiModels(String apiKey) async {
    final response = await http.get(
      Uri.parse('$_geminiBaseUrl/models?key=$apiKey'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> models = data['models'];
      // Filter for generateContent supported models and remove 'models/' prefix
      return models
          .where((m) => (m['supportedGenerationMethods'] as List).contains('generateContent'))
          .map((m) => (m['name'] as String).replaceFirst('models/', ''))
          .toList()..sort();
    } else {
      throw Exception('Failed to load Gemini models: ${response.statusCode} ${response.body}');
    }
  }

  Future<List<String>> _fetchOllamaModels(String baseUrl) async {
    // Ensure no trailing slash
    final sanitizedUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final response = await http.get(Uri.parse('$sanitizedUrl/api/tags'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> models = data['models'];
      return models.map((m) => m['name'] as String).toList()..sort();
    } else {
      throw Exception('Failed to load Ollama models: ${response.statusCode} ${response.body}');
    }
  }

  Future<List<String>> _fetchOpenRouterModels(String apiKey) async {
    final response = await http.get(
      Uri.parse('$_openRouterBaseUrl/models'),
      headers: {'Authorization': 'Bearer $apiKey'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // OpenRouter API returns { data: [...] }
      final List<dynamic> models = data['data'];
      return models.map((m) => m['id'] as String).toList()..sort();
    } else {
      throw Exception('Failed to load OpenRouter models: ${response.statusCode} ${response.body}');
    }
  }

  Future<List<String>> _fetchCustomModels(String baseUrl, String? apiKey) async {
     // Ensure no trailing slash
    final sanitizedUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    
    final headers = <String, String>{};
    if (apiKey != null && apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer $apiKey';
    }

    final response = await http.get(
      Uri.parse('$sanitizedUrl/v1/models'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> models = data['data'];
      return models.map((m) => m['id'] as String).toList()..sort();
    } else {
      throw Exception('Failed to load Custom models: ${response.statusCode} ${response.body}');
    }
  }

  Future<List<double>> getEmbedding(
    String text,
    AiProvider provider, {
    String? apiKey,
    String? baseUrl,
    String? modelName,
  }) async {
    switch (provider) {
      case AiProvider.openai:
        return _getOpenAiEmbedding(text, apiKey!);
      case AiProvider.gemini:
        return _getGeminiEmbedding(text, apiKey!);
      case AiProvider.ollama:
        return _getOllamaEmbedding(text, baseUrl!, modelName!);
      default:
        throw UnsupportedError('Embeddings not supported for this provider yet.');
    }
  }

  Future<List<double>> _getOpenAiEmbedding(String text, String apiKey) async {
    final response = await http.post(
      Uri.parse('$_openAiBaseUrl/embeddings'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'input': text,
        'model': 'text-embedding-3-small',
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<double>.from(data['data'][0]['embedding']);
    } else {
      throw Exception('OpenAI Embedding Error: ${response.statusCode} ${response.body}');
    }
  }

  Future<List<double>> _getGeminiEmbedding(String text, String apiKey) async {
    final response = await http.post(
      Uri.parse('$_geminiBaseUrl/models/text-embedding-004:embedContent?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'content': {
          'parts': [
            {'text': text}
          ]
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<double>.from(data['embedding']['values']);
    } else {
      throw Exception('Gemini Embedding Error: ${response.statusCode} ${response.body}');
    }
  }

  Future<List<double>> _getOllamaEmbedding(String text, String baseUrl, String modelName) async {
    final sanitizedUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final response = await http.post(
      Uri.parse('$sanitizedUrl/api/embeddings'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'model': modelName,
        'prompt': text,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<double>.from(data['embedding']);
    } else {
      throw Exception('Ollama Embedding Error: ${response.statusCode} ${response.body}');
    }
  }

  Future<String> chat(
    List<Map<String, String>> messages,
    AiProvider provider, {
    String? apiKey,
    String? baseUrl,
    String? modelName,
  }) async {
    switch (provider) {
      case AiProvider.openai:
        return _chatOpenAi(messages, apiKey!, modelName ?? 'gpt-4o');
      case AiProvider.anthropic:
        return _chatAnthropic(messages, apiKey!, modelName ?? 'claude-3-5-sonnet-20240620');
      case AiProvider.gemini:
        return _chatGemini(messages, apiKey!, modelName ?? 'gemini-1.5-flash');
      case AiProvider.ollama:
        return _chatOllama(messages, baseUrl!, modelName!);
      case AiProvider.openRouter:
        return _chatOpenRouter(messages, apiKey!, modelName!);
      case AiProvider.custom:
        return _chatCustom(messages, baseUrl!, apiKey, modelName!);
    }
  }

  Future<String> _chatOpenAi(List<Map<String, String>> messages, String apiKey, String model) async {
    final response = await http.post(
      Uri.parse('$_openAiBaseUrl/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'model': model,
        'messages': messages,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('OpenAI Chat Error: ${response.statusCode} ${response.body}');
    }
  }

  Future<String> _chatAnthropic(List<Map<String, String>> messages, String apiKey, String model) async {
    // Convert OpenAI-style messages to Anthropic style
    // System message must be top-level parameter, not in messages list
    String? systemMessage;
    final anthropicMessages = <Map<String, String>>[];
    
    for (var m in messages) {
      if (m['role'] == 'system') {
        systemMessage = m['content'];
      } else {
        anthropicMessages.add({
          'role': m['role']!,
          'content': m['content']!,
        });
      }
    }

    final body = {
      'model': model,
      'messages': anthropicMessages,
      'max_tokens': 4096,
    };
    if (systemMessage != null) {
      body['system'] = systemMessage;
    }

    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['content'][0]['text'];
    } else {
      throw Exception('Anthropic Chat Error: ${response.statusCode} ${response.body}');
    }
  }

  Future<String> _chatGemini(List<Map<String, String>> messages, String apiKey, String model) async {
    // Gemini structure is different (contents: [{parts: [{text: ...}], role: ...}])
    final geminiContent = <Map<String, dynamic>>[];
    String? systemInstruction;

    for (var m in messages) {
      if (m['role'] == 'system') {
        systemInstruction = m['content'];
        continue; 
      }
      
      // Map 'assistant' -> 'model' for Gemini
      final role = m['role'] == 'assistant' ? 'model' : 'user';
      geminiContent.add({
        'role': role,
        'parts': [{'text': m['content']}]
      });
    }
    
    final url = '$_geminiBaseUrl/models/$model:generateContent?key=$apiKey';
    final body = <String, dynamic>{'contents': geminiContent};
    
    if (systemInstruction != null) {
      body['systemInstruction'] = {
        'parts': [{'text': systemInstruction}]
      };
    }

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Safety check
      if (data['candidates'] != null && (data['candidates'] as List).isNotEmpty) {
         final parts = data['candidates'][0]['content']['parts'] as List;
         if (parts.isNotEmpty) {
           return parts[0]['text'];
         }
      }
      return "No response generated.";
    } else {
      throw Exception('Gemini Chat Error: ${response.statusCode} ${response.body}');
    }
  }

  Future<String> _chatOllama(List<Map<String, String>> messages, String baseUrl, String model) async {
    final sanitizedUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final response = await http.post(
      Uri.parse('$sanitizedUrl/api/chat'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'model': model,
        'messages': messages,
        'stream': false,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['message']['content'];
    } else {
      throw Exception('Ollama Chat Error: ${response.statusCode} ${response.body}');
    }
  }

  Future<String> _chatOpenRouter(List<Map<String, String>> messages, String apiKey, String model) async {
    final response = await http.post(
      Uri.parse('$_openRouterBaseUrl/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        // OpenRouter specific headers
        'HTTP-Referer': 'https://bard-ish.app', 
        'X-Title': 'Bard-ish Note App',
      },
      body: json.encode({
        'model': model,
        'messages': messages,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('OpenRouter Chat Error: ${response.statusCode} ${response.body}');
    }
  }

  Future<String> _chatCustom(List<Map<String, String>> messages, String baseUrl, String? apiKey, String model) async {
    final sanitizedUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final headers = {'Content-Type': 'application/json'};
    if (apiKey != null && apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer $apiKey';
    }

    final response = await http.post(
      Uri.parse('$sanitizedUrl/v1/chat/completions'),
      headers: headers,
      body: json.encode({
        'model': model,
        'messages': messages,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('Custom Chat Error: ${response.statusCode} ${response.body}');
    }
  }
}
