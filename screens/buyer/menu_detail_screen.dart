import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/menu_model.dart';
import '../../services/menu_service.dart';
import '../../providers/cart_provider.dart';

class MenuDetailScreen extends StatefulWidget {
  final String menuId;
  final String buyerId;

  const MenuDetailScreen({
    super.key,
    required this.menuId,
    required this.buyerId,
  });

  @override
  State<MenuDetailScreen> createState() => _MenuDetailScreenState();
}

class _MenuDetailScreenState extends State<MenuDetailScreen> {
  final MenuService _menuService = MenuService();
  MenuModel? _menu;
  int _quantity = 1;
  bool _isLoading = true;
  bool _isAdding = false;
  int? _liveStock;

  @override
  void initState() {
    super.initState();
    _loadMenu();
    _menuService.watchMenuStock(widget.menuId).listen((stock) {
      if (mounted) setState(() => _liveStock = stock);
    });
  }

  Future<void> _loadMenu() async {
    final menu = await _menuService.getMenuById(widget.menuId);
    if (!mounted) return;
    setState(() {
      _menu = menu;
      _liveStock = menu.stock;
      _isLoading = false;
    });
  }

  Future<void> _addToCart() async {
    setState(() => _isAdding = true);
    final cartProvider = context.read<CartProvider>();
    await cartProvider.addItem(widget.buyerId, widget.menuId, quantity: _quantity);
    if (!mounted) return;
    setState(() => _isAdding = false);

    if (cartProvider.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ditambahkan ke keranjang')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(cartProvider.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _menu == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final menu = _menu!;
    final stock = _liveStock ?? menu.stock;
    final isOutOfStock = stock <= 0;

    return Scaffold(
      appBar: AppBar(title: Text(menu.name)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.4,
              child: menu.imageUrl != null
                  ? Image.network(menu.imageUrl!, fit: BoxFit.cover)
                  : Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.fastfood_outlined, size: 64),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    menu.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  if (menu.categoryName != null) ...[
                    const SizedBox(height: 4),
                    Chip(
                      label: Text(menu.categoryName!),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Rp ${menu.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isOutOfStock ? 'Stok habis' : 'Stok tersedia: $stock',
                    style: TextStyle(color: isOutOfStock ? Colors.red : Colors.grey.shade700),
                  ),
                  if (menu.description != null) ...[
                    const SizedBox(height: 16),
                    const Text('Deskripsi', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(menu.description!),
                  ],
                  const SizedBox(height: 24),
                  if (!isOutOfStock) ...[
                    const Text('Jumlah', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton.outlined(
                          icon: const Icon(Icons.remove),
                          onPressed: _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('$_quantity', style: const TextStyle(fontSize: 16)),
                        ),
                        IconButton.outlined(
                          icon: const Icon(Icons.add),
                          onPressed: _quantity < stock
                              ? () => setState(() => _quantity++)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: isOutOfStock || _isAdding ? null : _addToCart,
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: _isAdding
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(isOutOfStock ? 'Stok Habis' : 'Tambah ke Keranjang'),
          ),
        ),
      ),
    );
  }
}
