import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/ai_service.dart';

class AiSettingsScreen extends StatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  State<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends State<AiSettingsScreen> {
  late Box _settingsBox;
  AiProvider _selectedProvider = AiProvider.openai;
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _baseUrlController = TextEditingController();
  String? _selectedModel;
  List<String> _availableModels = [];
  bool _isLoadingModels = false;
  final AiService _aiService = AiService();

  @override
  void initState() {
    super.initState();
    _settingsBox = Hive.box('settings');
    _loadSettings();
  }

  void _loadSettings() {
    final providerString = _settingsBox.get('ai_provider', defaultValue: 'openai');
    _selectedProvider = AiProvider.values.firstWhere(
      (e) => e.name == providerString,
      orElse: () => AiProvider.openai,
    );
    _apiKeyController.text = _settingsBox.get('ai_api_key', defaultValue: '');
    _baseUrlController.text = _settingsBox.get('ai_base_url', defaultValue: '');
    _selectedModel = _settingsBox.get('ai_model');
    
    // If we have a selected model but no list, we can't show it in the dropdown properly 
    // until we fetch, but we can show it as the selected value if we add it to the list temporarily
    if (_selectedModel != null) {
      _availableModels = [_selectedModel!];
    }
  }

  Future<void> _saveSettings() async {
    await _settingsBox.put('ai_provider', _selectedProvider.name);
    await _settingsBox.put('ai_api_key', _apiKeyController.text);
    await _settingsBox.put('ai_base_url', _baseUrlController.text);
    if (_selectedModel != null) {
      await _settingsBox.put('ai_model', _selectedModel!);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI Settings Saved')),
      );
    }
  }

  Future<void> _fetchModels() async {
    setState(() {
      _isLoadingModels = true;
    });

    try {
      final models = await _aiService.getModels(
        _selectedProvider,
        apiKey: _apiKeyController.text,
        baseUrl: _baseUrlController.text.isEmpty ? null : _baseUrlController.text,
      );
      
      setState(() {
        _availableModels = models;
        if (models.isNotEmpty) {
           // If previously selected model is in the new list, keep it. Otherwise select first.
           if (!_availableModels.contains(_selectedModel)) {
             _selectedModel = models.first;
           }
        } else {
          _selectedModel = null;
        }
      });
      
      if (models.isEmpty) {
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No models found')),
          );
        }
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching models: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoadingModels = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final surfaceColor = theme.colorScheme.surface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 30.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'AI Settings',
                      style: TextStyle(
                        fontSize: 32,
                        fontFamily: 'Serif',
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: primaryColor, size: 32),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    _buildSectionTitle('Provider'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<AiProvider>(
                          value: _selectedProvider,
                          dropdownColor: surfaceColor,
                          style: TextStyle(color: primaryColor, fontSize: 16),
                          icon: Icon(Icons.arrow_drop_down, color: primaryColor),
                          isExpanded: true,
                          items: AiProvider.values.map((AiProvider provider) {
                            return DropdownMenuItem<AiProvider>(
                              value: provider,
                              child: Text(provider.name.toUpperCase()),
                            );
                          }).toList(),
                          onChanged: (AiProvider? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedProvider = newValue;
                                _availableModels = [];
                                _selectedModel = null;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (_selectedProvider != AiProvider.ollama) ...[
                      _buildSectionTitle('API Key'),
                      TextField(
                        controller: _apiKeyController,
                        obscureText: true,
                        style: TextStyle(color: primaryColor),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: surfaceColor,
                          hintText: 'Enter your API Key',
                          hintStyle: TextStyle(color: primaryColor.withOpacity(0.5)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    if (_selectedProvider == AiProvider.ollama || 
                        _selectedProvider == AiProvider.custom) ...[
                      _buildSectionTitle('Base URL'),
                      TextField(
                        controller: _baseUrlController,
                        style: TextStyle(color: primaryColor),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: surfaceColor,
                          hintText: _selectedProvider == AiProvider.ollama 
                              ? 'http://localhost:11434' 
                              : 'https://api.example.com/v1',
                          hintStyle: TextStyle(color: primaryColor.withOpacity(0.5)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionTitle('Model'),
                        TextButton.icon(
                          onPressed: _isLoadingModels ? null : _fetchModels,
                          icon: _isLoadingModels 
                              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor))
                              : Icon(Icons.refresh, color: primaryColor, size: 18),
                          label: Text(
                            'Fetch Models',
                            style: TextStyle(color: primaryColor),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedModel,
                          hint: Text('Select a model', style: TextStyle(color: primaryColor.withOpacity(0.5))),
                          dropdownColor: surfaceColor,
                          style: TextStyle(color: primaryColor, fontSize: 16),
                          icon: Icon(Icons.arrow_drop_down, color: primaryColor),
                          isExpanded: true,
                          items: _availableModels.map((String model) {
                            return DropdownMenuItem<String>(
                              value: model,
                              child: Text(model),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedModel = newValue;
                            });
                          },
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Save Settings',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}
