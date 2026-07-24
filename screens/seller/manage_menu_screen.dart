import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/menu_model.dart';
import '../../providers/seller_menu_provider.dart';
import 'menu_form_screen.dart';

class ManageMenuScreen extends StatefulWidget {
  final String sellerId;

  const ManageMenuScreen({super.key, required this.sellerId});

  @override
  State<ManageMenuScreen> createState() => _ManageMenuScreenState();
}

class _ManageMenuScreenState extends State<ManageMenuScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SellerMenuProvider>().loadMenus(widget.sellerId);
    });
  }

  Future<void> _confirmDelete(MenuModel menu) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Menu'),
        content: Text(
          'Hapus "${menu.name}"? Jika menu ini pernah dipesan, gunakan tombol nonaktifkan saja agar riwayat pesanan lama tetap utuh.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<SellerMenuProvider>();
      final success = await provider.deleteMenu(widget.sellerId, menu.id);
      if (!mounted) return;
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage ?? 'Gagal menghapus')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Menu')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MenuFormScreen(sellerId: widget.sellerId),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Tambah Menu'),
      ),
      body: Consumer<SellerMenuProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.menus.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.menus.isEmpty) {
            return const Center(child: Text('Belum ada menu, tambahkan sekarang'));
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadMenus(widget.sellerId),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: provider.menus.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final menu = provider.menus[index];
                return _MenuTile(
                  menu: menu,
                  onEdit: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MenuFormScreen(
                          sellerId: widget.sellerId,
                          existingMenu: menu,
                        ),
                      ),
                    );
                  },
                  onToggleActive: (value) =>
                      provider.toggleActive(widget.sellerId, menu.id, value),
                  onDelete: () => _confirmDelete(menu),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final MenuModel menu;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onDelete;

  const _MenuTile({
    required this.menu,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: menu.imageUrl != null
                  ? Image.network(menu.imageUrl!, width: 64, height: 64, fit: BoxFit.cover)
                  : Container(
                      width: 64,
                      height: 64,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.fastfood_outlined),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(menu.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('Rp ${menu.price.toStringAsFixed(0)} · Stok ${menu.stock}'),
                  if (menu.categoryName != null)
                    Text(
                      menu.categoryName!,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                ],
              ),
            ),
            Column(
              children: [
                Switch(
                  value: menu.isActive,
                  onChanged: onToggleActive,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: onEdit,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
