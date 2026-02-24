import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hire_craft/models/template_config.dart';

final availableTemplatesProvider = Provider<List<TemplateConfig>>((ref) {
  return TemplateConfig.defaults;
});

final selectedTemplateProvider =
    NotifierProvider<SelectedTemplateNotifier, TemplateConfig>(
  SelectedTemplateNotifier.new,
);

class SelectedTemplateNotifier extends Notifier<TemplateConfig> {
  @override
  TemplateConfig build() => TemplateConfig.defaults.first;

  void selectTemplate(TemplateConfig config) {
    state = config;
  }
}
