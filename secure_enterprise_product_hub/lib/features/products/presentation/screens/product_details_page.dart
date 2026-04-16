import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/state/app_cubit.dart';
import '../../../../core/widgets/app_panel.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../domain/entities/product.dart';
import '../cubit/products_cubit.dart';
import '../cubit/products_state.dart';
import 'product_form_page.dart';

class ProductDetailsPage extends StatelessWidget {
  const ProductDetailsPage({
    required this.product,
    required this.user,
    required this.productsCubit,
    super.key,
  });

  final Product product;
  final AppUser user;
  final ProductsCubit productsCubit;

  @override
  Widget build(BuildContext context) {
    return CubitBuilder<ProductsCubit, ProductsState>(
      cubit: productsCubit,
      builder: (context, state) {
        final current = _currentProduct(state);
        return Scaffold(
          appBar: AppBar(
            title: Text(current.name),
            actions: [
              if (user.isAdmin)
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () async {
                    final changed = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => ProductFormPage(
                          productsCubit: productsCubit,
                          product: current,
                        ),
                      ),
                    );
                    if (changed == true) {
                      await productsCubit.loadDetails(current.id);
                    }
                  },
                ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ProductImageFrame(
                    imageUrl: current.imageUrl,
                    iconSize: 72,
                  ),
                ),
                const SizedBox(height: 16),
                AppPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        current.name,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _InfoPill(
                            icon: Icons.category_outlined,
                            label: current.category,
                          ),
                          _InfoPill(
                            icon: Icons.payments_outlined,
                            label: current.currency,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        current.priceLabel,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
                if (user.isAdmin) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => _upload(context, current),
                    icon: const Icon(Icons.cloud_upload_outlined),
                    label: const Text('Upload image'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _upload(BuildContext context, Product current) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );
    if (picked != null) {
      await productsCubit.uploadImage(current.id, File(picked.path));
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Image uploaded')));
      }
    }
  }

  Product _currentProduct(ProductsState state) {
    if (state.selected?.id == product.id) {
      return state.selected!;
    }
    for (final item in state.products) {
      if (item.id == product.id) {
        return item;
      }
    }
    return product;
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF475467)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF344054),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
