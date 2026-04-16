import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/state/app_cubit.dart';
import '../../../../core/widgets/app_panel.dart';
import '../../domain/entities/product.dart';
import '../cubit/products_cubit.dart';
import '../cubit/products_state.dart';

class ProductFormPage extends StatefulWidget {
  const ProductFormPage({required this.productsCubit, this.product, super.key});

  final ProductsCubit productsCubit;
  final Product? product;

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late String _currency;
  late String _category;
  File? _image;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _name = TextEditingController(text: product?.name ?? '');
    _price = TextEditingController(
      text: product?.price.toStringAsFixed(0) ?? '',
    );
    _currency = product?.currency ?? ProductCurrencies.values.first;
    _category = product?.category ?? ProductCategories.values.first;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.product != null;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Edit product' : 'Add product')),
      body: SafeArea(
        child: CubitBuilder<ProductsCubit, ProductsState>(
          cubit: widget.productsCubit,
          builder: (context, state) {
            final saving = state.status == ProductsStatus.saving;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: AppPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        editing ? 'Update product' : 'New product',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Keep pricing, category and product imagery ready for the catalog.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 22),
                      TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(labelText: 'Name'),
                        enabled: !saving,
                        validator: (value) =>
                            value == null || value.trim().length < 2
                            ? 'Enter a product name'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 116,
                            child: DropdownButtonFormField<String>(
                              initialValue: _currency,
                              decoration: const InputDecoration(
                                labelText: 'Currency',
                              ),
                              items: ProductCurrencies.values
                                  .map(
                                    (currency) => DropdownMenuItem(
                                      value: currency,
                                      child: Text(currency),
                                    ),
                                  )
                                  .toList(),
                              onChanged: saving
                                  ? null
                                  : (value) {
                                      if (value != null) {
                                        setState(() => _currency = value);
                                      }
                                    },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _price,
                              decoration: const InputDecoration(
                                labelText: 'Price',
                              ),
                              enabled: !saving,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                DecimalTextInputFormatter(decimalRange: 2),
                              ],
                              validator: (value) {
                                final price = double.tryParse(value ?? '');
                                return price == null || price <= 0
                                    ? 'Enter a valid price'
                                    : null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        items: _categoryItems
                            .map(
                              (category) => DropdownMenuItem(
                                value: category,
                                child: Text(_label(category)),
                              ),
                            )
                            .toList(),
                        onChanged: saving
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() => _category = value);
                                }
                              },
                      ),
                      const SizedBox(height: 18),
                      if (_image != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _image!,
                              height: 180,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      OutlinedButton.icon(
                        onPressed: saving ? null : _pickImage,
                        icon: const Icon(Icons.image_outlined),
                        label: Text(
                          _image == null
                              ? 'Choose product image'
                              : 'Image selected',
                        ),
                      ),
                      if (state.message != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          state.message!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: saving ? null : _save,
                        child: Text(
                          saving
                              ? 'Saving...'
                              : editing
                              ? 'Save changes'
                              : 'Create product',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );
    if (image != null) {
      setState(() => _image = File(image.path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final saved = await widget.productsCubit.save(
      id: widget.product?.id,
      name: _name.text,
      price: double.parse(_price.text),
      currency: _currency,
      category: _category,
      image: _image,
    );
    if (saved && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  List<String> get _categoryItems {
    if (ProductCategories.values.contains(_category)) {
      return ProductCategories.values;
    }
    return [_category, ...ProductCategories.values];
  }

  String _label(String value) {
    return value
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }
}

class DecimalTextInputFormatter extends TextInputFormatter {
  DecimalTextInputFormatter({required this.decimalRange})
    : assert(decimalRange >= 0);

  final int decimalRange;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) {
      return newValue;
    }

    final decimalPattern = decimalRange == 0
        ? RegExp(r'^\d+$')
        : RegExp('^\\d*\\.?\\d{0,$decimalRange}\$');
    if (decimalPattern.hasMatch(text)) {
      return newValue;
    }
    return oldValue;
  }
}
