# 📱 phone_formatter

A simple and flexible phone number formatter for Flutter, supporting mask and set of masks (dynamic country code detection).

---

## 🚀 Usecases

✅ Support for **dynamic masks** for different country codes  
✅ Ability to set a **fixed format** for a specific country  
✅ Input limited to digits and allowed characters  
✅ Protection against deleting the country code  
✅ Automatic insertion of digits into the first available position  
✅ Easy integration with `TextFormField` and `TextField`  

---

## 📦 Installation

Add the dependency in `pubspec.yaml`:

```yaml
dependencies:
  phone_formatter: ^1.0.0
```

## ⚙️ API

Mask configuration for one country.

### PhoneFormatterConfig
|Field|	Type|	Description|
|---|---|---|
|`mask`|`String`|Format mask, e.g. (###) ### ##-## or ### ### ####
|`countryCode`|`String`|Country code, e.g. +7 or +1|
|`phoneMask`|`String`|Combines countryCode and mask|
|`contryCodeOffset`|`int`|Length offset relative to the country code|

### PhoneFormatter

|Contructor|Description|
|---|---|
|`PhoneFormatter({required PhoneFormatterConfig config})`|Fixed mask|
|`PhoneFormatter.array({required List<PhoneFormatterConfig> configVariants})`|Set of allowed masks|

### Required methods for correct formatter operation
```dart
  @override
  void initState() {
    // Automatically sets the value with a mask. Required for the PhoneFormatter constructor variant.
    controller.value = formatter.formatEditUpdate(TextEditingValue.empty, TextEditingValue.empty);

    // Ensures the cursor moves to the first free cell on focus.
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        controller.selection = TextSelection.collapsed(
          offset: formatter.getFirstUnderline(controller.text),
        );
      }
    });
    super.initState();
  }
```

## 🧪 Formatter behavior
- When entering a digit at the end of the string, it is automatically inserted into the first free position (_)
- When pasting a number from the clipboard, the formatter removes extra characters and plus signs
- When a config is active, it is impossible to delete the country code
- All invalid characters (except +, (, ), -, _, space) are automatically removed

## 📸 Example usage

- `+7 (___) ___ __-__`  →  `+7 (999) 123 45-67`
- `+1 ___ ___ ____`     →  `+1 555 111 2222`
- `+92 ___ _______`     →  `+92 300 1234567`