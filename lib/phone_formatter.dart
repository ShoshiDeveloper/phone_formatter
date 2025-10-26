import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

// enum FFTPhoneCountryCodeVariant {
//   ru,
//   us,
//   pk,
//   ind;

//   const FFTPhoneCountryCodeVariant();

//   String get phoneMask => '$countryCode $mask';
//   // int get contryCodeOffset => mask.length - countryCode.length;

//   String get mask => switch (this) {
//     FFTPhoneCountryCodeVariant.ru => '(###) ### ##-##',
//     FFTPhoneCountryCodeVariant.us => '### ### ####',
//     FFTPhoneCountryCodeVariant.pk => '### #######',
//     FFTPhoneCountryCodeVariant.ind => '### ### ####',
//   };

//   String get countryCode => switch (this) {
//     FFTPhoneCountryCodeVariant.ru => '+7',
//     FFTPhoneCountryCodeVariant.us => '+1',
//     FFTPhoneCountryCodeVariant.pk => '+92',
//     FFTPhoneCountryCodeVariant.ind => '+91',
//   };
// }

class PhoneFormatterConfig {
  const PhoneFormatterConfig({required this.mask, required this.countryCode});

  /// Mask example: ### ### #### or (###) ### ##-## or etc
  final String mask;

  /// Example: +1 or +7 or etc
  final String countryCode;

  String get phoneMask => '$countryCode $mask';
  int get contryCodeOffset => mask.length - countryCode.length;
}

@protected
class PhoneFormatterMaskResult {
  const PhoneFormatterMaskResult({required this.result, required this.lastIndex});

  final int lastIndex;
  final String result;

  @override
  String toString() => 'result: $result index: $lastIndex';
}

class PhoneFormatter extends TextInputFormatter {
  PhoneFormatter({required this.config, this.emptySymbol = '_'}) : configVariants = const [];
  PhoneFormatter.array({this.configVariants = const [], this.emptySymbol = '_'}) : config = null;

  final PhoneFormatterConfig? config;
  final List<PhoneFormatterConfig> configVariants;
  final String emptySymbol;

  static final onlyServiceSymbolsRegex = RegExp(r'[()\-_ ]');
  static final negativeRegex = RegExp(r'[^0-9+()\-_ ]');
  static final numbersRegex = RegExp(r'[0-9]');

  int? oldOffset;
  String? oldValue;

  @override
  TextEditingValue formatEditUpdate(
    final TextEditingValue oldValue,
    final TextEditingValue newValue,
  ) {
    TextEditingValue value = newValue;

    //replace if number inserted in end
    //replace number from end to first emptySymbol
    final splitted = value.text.split('');
    final firstEmptyIndex = getFirstUnderline(value.text);

    if (value.text.isNotEmpty && numbersRegex.hasMatch(splitted.last) && firstEmptyIndex != -1) {
      splitted[firstEmptyIndex] = splitted.last;
      splitted[splitted.length - 1] = emptySymbol;

      value = value.copyWith(
        text: splitted.join(),
        selection: TextSelection.collapsed(offset: firstEmptyIndex + 1),
      );
    }

    // protection from deletion of country code when codeVariant isn`t null
    if (config != null && !newValue.text.contains(config!.countryCode)) {
      value = oldValue;
    }

    // removing extra pluses when pasting from the clipboard
    if ('+'.allMatches(value.text).length > 1) {
      value = value.copyWith(text: '+${value.text.replaceAll('+', '')}');
    }

    // we delete everything except the characters that are valid for us
    if (value.text.isNotEmpty && negativeRegex.hasMatch(value.text)) {
      value = value.copyWith(
        text: value.text.replaceAll(negativeRegex, ''),
        selection: TextSelection.collapsed(offset: value.selection.baseOffset - 1),
      );
    }

    // we process the value according to the mandatory country code principle
    if (config != null) return _formattingByCertainCountry(oldValue, value, config!);

    // we are looking for a suitable country code
    for (final variant in configVariants) {
      if (value.text.contains(variant.countryCode)) {
        return _formattingByDynamicCountry(oldValue, value, variant);
      }
    }

    final digits = value.text.replaceAll(onlyServiceSymbolsRegex, '').replaceAll(emptySymbol, '');
    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }

  TextEditingValue _formattingByCertainCountry(
    final TextEditingValue oldValue,
    final TextEditingValue newValue,
    final PhoneFormatterConfig config,
  ) {
    final mask = config.phoneMask;

    final text =
        newValue.text.length > mask.length
            ? newValue.text.substring(0, mask.length)
            : newValue.text;

    String digits = text
        .replaceAll(config.countryCode, '')
        .replaceAll(onlyServiceSymbolsRegex, '')
        .replaceAll(emptySymbol, '');

    String oldDigits = oldValue.text
        .replaceAll(config.countryCode, '')
        .replaceAll(onlyServiceSymbolsRegex, '')
        .replaceAll(emptySymbol, '');

    if ((digits.length - oldDigits.length) > 1) {
      final pastedValue = newValue.text
          .replaceAll(config.countryCode, '')
          .replaceAll(onlyServiceSymbolsRegex, '')
          .replaceAll(emptySymbol, '');

      digits = pastedValue;
    }

    final isRemoved = digits.length < oldDigits.length;
    final isAdded = digits.length > oldDigits.length;

    final newValueMasked = _applyMask(
      mask,
      digits,
      newValue.selection.baseOffset,
      isRemoved,
      config,
    );

    final resultWithoutCountryCode = newValueMasked.result.replaceAll(config.countryCode, '');
    final numbersCount =
        resultWithoutCountryCode.split('').where((final e) => RegExp('[0-9]').hasMatch(e)).length;

    final splitted = newValueMasked.result.split('');
    final firstUnderline = splitted.indexWhere((final e) => e == emptySymbol);
    final isOverLimits = numbersCount == 0;

    return TextEditingValue(
      text: newValueMasked.result,
      selection: TextSelection.collapsed(
        offset:
            isAdded && firstUnderline < newValueMasked.lastIndex
                ? firstUnderline
                : (isOverLimits ? firstUnderline : newValueMasked.lastIndex),
      ),
    );
  }

  TextEditingValue _formattingByDynamicCountry(
    final TextEditingValue oldValue,
    final TextEditingValue newValue,
    final PhoneFormatterConfig config,
  ) {
    final mask = config.phoneMask;

    final digits = newValue.text
        .replaceAll(config.countryCode, '')
        .replaceAll(onlyServiceSymbolsRegex, '')
        .replaceAll(emptySymbol, '');

    final oldDigits = oldValue.text
        .replaceAll(config.countryCode, '')
        .replaceAll(onlyServiceSymbolsRegex, '')
        .replaceAll(emptySymbol, '');

    final newValueMasked = _applyMask(
      mask,
      digits,
      newValue.selection.baseOffset,
      digits.length < oldDigits.length,
    );

    final isAdded = digits.length > oldDigits.length;

    if (newValueMasked.lastIndex == 0) {
      return TextEditingValue(
        text: newValueMasked.result,
        selection: TextSelection.collapsed(offset: config.countryCode.length),
      );
    }

    final splitted = newValueMasked.result.split('');
    final firstUnderline = splitted.indexWhere((final e) => e == emptySymbol);

    final index =
        newValueMasked.lastIndex < config.countryCode.length
            ? config.countryCode.length
            : newValueMasked.lastIndex;

    return TextEditingValue(
      text: newValueMasked.result,
      selection: TextSelection.collapsed(offset: isAdded ? firstUnderline : index),
    );
  }

  PhoneFormatterMaskResult _applyMask(
    final String mask,
    final String digits,
    final int position,
    final bool isRemoved, [

    /// Only for certain country
    final PhoneFormatterConfig? config,
  ]) {
    var buffer = StringBuffer();
    int cPos = position;
    int digitIndex = 0;

    final maskList = mask.split('');

    for (var i = 0; i < maskList.length; i++) {
      final symbol = maskList[i];

      if (symbol == '#') {
        if (digitIndex < digits.length) {
          buffer.write(digits[digitIndex]);
          digitIndex++;
        } else {
          buffer.write(emptySymbol);
        }
      } else {
        buffer.write(symbol);
      }

      if (i == position) {
        if (digitIndex < digits.length - 1) {}

        if (!isRemoved && i - 1 > 0) {
          if (maskList[i - 1] != '#') {
            //TODO: change to for (int j = i; i > maskList.length; i--)
            //for cases where the number of characters between the digits is unknown
            final upp = (maskList[i - 1] != '#' ? 1 : 0) + (maskList[i] != '#' ? 1 : 0);
            cPos = i + upp;
          }
        } else if (isRemoved) {
          if (maskList[i - 1] != '#') {
            final range = maskList.getRange(0, i).join().trim();

            // we don't let you go beyond the mask and move on to the country code
            if (config != null && range.contains(config.countryCode) && !range.contains('#')) {
              continue;
            }

            //TODO: change to for (int j = i; i > maskList.length; i--)
            //for cases where the number of characters between the digits is unknown
            final upp = (maskList[i - 1] != '#' ? -1 : 0) + (maskList[i - 2] != '#' ? -1 : 0);
            cPos = i + upp;
          }
        }
      }
    }

    return PhoneFormatterMaskResult(
      result: buffer.toString(),
      lastIndex: cPos.clamp(0, buffer.length),
    );
  }

  int getFirstUnderline(final String value) {
    final firstUnderline = value.split('').indexOf(emptySymbol);

    return firstUnderline;
  }
}
