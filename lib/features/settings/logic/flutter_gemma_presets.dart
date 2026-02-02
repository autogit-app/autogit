import 'package:flutter_gemma/flutter_gemma.dart';

/// Preset on-device models supported by Flutter Gemma (no HuggingFace login).
/// See: https://pub.dev/packages/flutter_gemma
class FlutterGemmaPreset {
  const FlutterGemmaPreset({
    required this.name,
    required this.url,
    required this.modelType,
    this.size,
    this.note,
  });

  final String name;
  final String url;
  final ModelType modelType;
  final String? size;
  final String? note;

  String get label => size != null ? '$name ($size)' : name;
}

/// Curated list of public models that work without a HuggingFace token.
/// Mobile: .task or .bin; Desktop (Windows/Linux/macOS) needs .litertlm from the same repos.
final List<FlutterGemmaPreset> kFlutterGemmaPresets = [
  FlutterGemmaPreset(
    name: 'SmolLM 135M',
    url:
        'https://huggingface.co/litert-community/SmolLM-135M-Instruct/resolve/main/SmolLM-135M-Instruct_multi-prefill-seq_q8_ekv1280.task',
    modelType: ModelType.general,
    size: '~167MB',
    note: 'Phones & tablets',
  ),
  FlutterGemmaPreset(
    name: 'Qwen3 0.6B',
    url:
        'https://huggingface.co/litert-community/Qwen3-0.6B/resolve/main/Qwen3-0.6B-int4.bin',
    modelType: ModelType.qwen,
    size: '~586MB',
    note: 'Phones, tablets, web',
  ),
  FlutterGemmaPreset(
    name: 'Qwen 2.5 0.5B',
    url:
        'https://huggingface.co/litert-community/Qwen2.5-0.5B-Instruct/resolve/main/Qwen2.5-0.5B-Instruct-int4.bin',
    modelType: ModelType.qwen,
    size: '~0.5GB',
    note: 'Phones & tablets',
  ),
  FlutterGemmaPreset(
    name: 'Qwen 2.5 1.5B',
    url:
        'https://huggingface.co/litert-community/Qwen2.5-1.5B-Instruct/resolve/main/Qwen2.5-1.5B-Instruct-int4.bin',
    modelType: ModelType.qwen,
    size: '~1.6GB',
    note: 'Phones, tablets, desktop',
  ),
  FlutterGemmaPreset(
    name: 'DeepSeek R1 Distill',
    url:
        'https://huggingface.co/litert-community/DeepSeek-R1-Distill-Qwen-1.5B/resolve/main/DeepSeek-R1-Distill-Qwen-1.5B-int4.bin',
    modelType: ModelType.deepSeek,
    size: '~1.7GB',
    note: 'Thinking mode, phones & tablets',
  ),
  FlutterGemmaPreset(
    name: 'Phi-4 Mini',
    url:
        'https://huggingface.co/litert-community/Phi-4-mini-instruct/resolve/main/Phi-4-mini-instruct-int4.bin',
    modelType: ModelType.general,
    size: '~3.9GB',
    note: 'Phones, tablets, web',
  ),
  FlutterGemmaPreset(
    name: 'FunctionGemma 270M',
    url:
        'https://huggingface.co/sasha-denisov/function-gemma-270M-it/resolve/main/functiongemma-270M-it.task',
    modelType: ModelType.functionGemma,
    size: '~284MB',
    note: 'Function calling, phones & tablets',
  ),
];
