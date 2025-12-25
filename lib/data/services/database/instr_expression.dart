import 'package:drift/drift.dart';

final class InstrExpression extends Expression<int> {
  final Expression<String> string;
  final Expression<String> substring;

  InstrExpression({required this.string, required this.substring});

  @override
  Precedence get precedence => Precedence.primary;

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write("instr(");
    string.writeInto(context);
    context.buffer.write(",");
    substring.writeInto(context);
    context.buffer.write(")");
  }
}
