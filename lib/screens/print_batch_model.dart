class PrintBatch {
  final String fileName;
  final int totalPages;
  final String printType;
  final String colorOption;
  final String bindingOption;
  final String stapleOption;
  final String punchOption;
  final int numberOfPrints;
  final int totalPrice;

  PrintBatch({
    required this.fileName,
    required this.totalPages,
    required this.printType,
    required this.colorOption,
    required this.bindingOption,
    required this.stapleOption,
    required this.punchOption,
    required this.numberOfPrints,
    required this.totalPrice,
  });
}