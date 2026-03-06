import 'package:telegraph/core/module_interface.dart';
import 'package:telegraph/core/utils/command_parser.dart';
import 'package:telegraph/core/utils/response_formatter.dart';
import 'package:telegraph/core/utils/response_codes.dart';

abstract class BaseCommandHandler implements FeatureCommandHandler {
  final DateTime Function() clock;

  BaseCommandHandler({DateTime Function()? clock})
    : clock = clock ?? (() => DateTime.now());

  @override
  bool canHandle(String input) =>
      input.toLowerCase().trim().startsWith("$moduleKey ");

  /// Helper to handle the repetitive 'delete' logic
  Future<String> performDelete(
    String input,
    Future<int> Function(int id) deleteCall,
  ) async {
    final id = int.tryParse(
      ParsedCommand.getArgument(input, "$moduleKey delete"),
    );
    if (id == null) {
      return ResponseFormatter.error(
        "Provide ID.",
        errorCode: ErrorCode.invalidFormat,
      );
    }
    final count = await deleteCall(id);
    return count > 0
        ? ResponseFormatter.success(
            "Deleted",
            successCode: SuccessCode.deleted,
            data: {"id": id},
          )
        : ResponseFormatter.error("Not found.", errorCode: ErrorCode.notFound);
  }

  /// Standard error for unknown sub-commands
  String unknownSubCommand() => ResponseFormatter.error(
    'Unknown $moduleKey Command.',
    errorCode: ErrorCode.invalidFormat,
  );
}
