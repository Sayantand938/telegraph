import 'package:telegraph/core/errors/result.dart';

class ToolParameter {
  final String name;
  final String type;
  final String description;
  final bool required;

  ToolParameter({
    required this.name,
    required this.type,
    required this.description,
    this.required = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'description': description,
      'required': required,
    };
  }
}

class Tool {
  final String name;
  final String description;
  final List<ToolParameter> parameters;
  final Future<Result<String>> Function(Map<String, dynamic> args) execute;

  Tool({
    required this.name,
    required this.description,
    required this.parameters,
    required this.execute,
  });

  Map<String, dynamic> toSchema() {
    return {
      'type': 'function',
      'function': {
        'name': name,
        'description': description,
        'parameters': {
          'type': 'object',
          'properties': {
            for (var param in parameters)
              param.name: {
                'type': param.type,
                'description': param.description,
              },
          },
          'required': parameters
              .where((p) => p.required)
              .map((p) => p.name)
              .toList(),
        },
      },
    };
  }
}
