import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/state/app_cubit.dart';
import '../../../../core/widgets/app_panel.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/entities/product.dart';
import '../cubit/products_cubit.dart';
import '../cubit/products_state.dart';
import 'product_details_page.dart';
import 'product_form_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    required this.authCubit,
    required this.productsCubit,
    required this.user,
    super.key,
  });

  final AuthCubit authCubit;
  final ProductsCubit productsCubit;
  final AppUser user;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _search = TextEditingController();
  String _category = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    scheduleMicrotask(() => widget.productsCubit.refresh());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Enterprise Catalog'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                widget.user.role.toUpperCase(),
                style: TextStyle(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: widget.authCubit.logout,
          ),
        ],
      ),
      floatingActionButton: widget.user.isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF101828),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              onPressed: () async {
                final created = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) =>
                        ProductFormPage(productsCubit: widget.productsCubit),
                  ),
                );
                if (created == true) {
                  _search.clear();
                  setState(() => _category = '');
                  await widget.productsCubit.refresh(search: '', category: '');
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            )
          : null,
      body: SafeArea(
        child: CubitBuilder<ProductsCubit, ProductsState>(
          cubit: widget.productsCubit,
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: () => widget.productsCubit.refresh(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                children: [
                  _DashboardSummary(user: widget.user, state: state),
                  const SizedBox(height: 16),
                  _Filters(
                    search: _search,
                    category: _category,
                    onSearchChanged: _filtersChanged,
                    onCategoryChanged: (value) {
                      setState(() => _category = value);
                      widget.productsCubit.refresh(
                        search: _search.text,
                        category: value,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  if (state.message != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        state.message!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  if (state.status == ProductsStatus.loading &&
                      state.products.isEmpty)
                    const AppStateBlock(
                      icon: Icons.sync,
                      title: 'Loading catalog',
                      message: 'Fetching the latest product records.',
                    )
                  else if (state.products.isEmpty)
                    AppStateBlock(
                      icon: Icons.search_off_outlined,
                      title: 'No products found',
                      message:
                          'Try a different name or switch back to all categories.',
                      action: OutlinedButton.icon(
                        onPressed: () {
                          _search.clear();
                          setState(() => _category = '');
                          widget.productsCubit.refresh(
                            search: '',
                            category: '',
                          );
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Clear filters'),
                      ),
                    )
                  else
                    ...state.products.map(
                      (product) => _ProductTile(
                        product: product,
                        isAdmin: widget.user.isAdmin,
                        onOpen: () => _openDetails(product),
                        onEdit: () => _editProduct(product),
                        onDelete: () => _confirmDelete(product),
                      ),
                    ),
                  if (state.hasMore)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: OutlinedButton(
                        onPressed: widget.productsCubit.loadMore,
                        child: const Text('Load more'),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _filtersChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      widget.productsCubit.refresh(search: _search.text, category: _category);
    });
  }

  void _openDetails(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailsPage(
          product: product,
          user: widget.user,
          productsCubit: widget.productsCubit,
        ),
      ),
    );
  }

  Future<void> _editProduct(Product product) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProductFormPage(
          productsCubit: widget.productsCubit,
          product: product,
        ),
      ),
    );
    if (changed == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Product updated')));
    }
  }

  Future<void> _confirmDelete(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text(product.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.productsCubit.remove(product.id);
    }
  }
}

class _DashboardSummary extends StatelessWidget {
  const _DashboardSummary({required this.user, required this.state});

  final AppUser user;
  final ProductsState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF101828),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33101828),
            blurRadius: 28,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SECURE ENTERPRISE HUB',
            style: TextStyle(
              color: const Color(0xFF84E1BC),
              fontSize: 12,
              letterSpacing: 0,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            user.isAdmin ? 'Admin workspace' : 'Product discovery',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            user.isAdmin
                ? 'Manage products, pricing, categories and catalog images.'
                : 'Search, filter and review the enterprise product catalog.',
            style: const TextStyle(color: Color(0xFFD0D5DD)),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricChip(label: 'Products', value: '${state.total}'),
              _MetricChip(label: 'Page', value: '${state.page}'),
              _MetricChip(label: 'Role', value: user.role),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Text(
          '$label: $value',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.search,
    required this.category,
    required this.onSearchChanged,
    required this.onCategoryChanged,
  });

  final TextEditingController search;
  final String category;
  final VoidCallback onSearchChanged;
  final ValueChanged<String> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width > 680;
    final fields = [
      TextField(
        controller: search,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
          labelText: 'Search by name',
        ),
        onChanged: (_) => onSearchChanged(),
      ),
      DropdownButtonFormField<String>(
        initialValue: category,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.tune),
          labelText: 'Filter category',
        ),
        items: [
          const DropdownMenuItem(value: '', child: Text('All categories')),
          ...ProductCategories.values.map(
            (category) =>
                DropdownMenuItem(value: category, child: Text(category)),
          ),
        ],
        onChanged: (value) => onCategoryChanged(value ?? ''),
      ),
    ];
    if (wide) {
      return AppPanel(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(child: fields[0]),
            const SizedBox(width: 12),
            Expanded(child: fields[1]),
          ],
        ),
      );
    }
    return AppPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [fields[0], const SizedBox(height: 12), fields[1]],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.isAdmin,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final Product product;
  final bool isAdmin;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppPanel(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                ProductImageFrame(
                  imageUrl: product.imageUrl,
                  height: 156,
                  width: double.infinity,
                  iconSize: 54,
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: _SoftTag(text: product.category),
                ),
                if (isAdmin)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A101828),
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: PopupMenuButton<String>(
                        onSelected: (value) =>
                            value == 'edit' ? onEdit() : onDelete(),
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF101828),
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          product.currency,
                          style: const TextStyle(
                            color: Color(0xFF667085),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        product.priceLabel,
                        style: const TextStyle(
                          color: Color(0xFF0F766E),
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        Icons.arrow_forward,
                        color: scheme.primary,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftTag extends StatelessWidget {
  const _SoftTag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF475467),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
