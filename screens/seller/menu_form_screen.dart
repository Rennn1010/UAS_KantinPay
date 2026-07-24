import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/menu_model.dart';
import '../../models/category_model.dart';
import '../../services/menu_service.dart';
import '../../providers/seller_menu_provider.dart';

/// Dipakai untuk dua mode:
/// - Tambah menu baru: existingMenu = null
/// - Edit menu: existingMenu diisi, form otomatis terisi data lama
class MenuFormScreen extends StatefulWidget {
  final String sellerId;
  final MenuModel? existingMenu;

  const MenuFormScreen({
    super.key,
    required this.sellerId,
    this.existingMenu,
  });

  bool get isEditMode => existingMenu != null;

  @override
  State<MenuFormScreen> createState() => _MenuFormScreenState();
}

class _MenuFormScreenState extends State<MenuFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  final MenuService _menuService = MenuService();
  List<CategoryModel> _categories = [];
  String? _selectedCategoryId;
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    _loadCategories();

    final existing = widget.existingMenu;
    if (existing != null) {
      _nameController.text = existing.name;
      _descriptionController.text = existing.description ?? '';
      _priceController.text = existing.price.toStringAsFixed(0);
      _stockController.text = existing.stock.toString();
      _selectedCategoryId = existing.categoryId;
    }
  }

  Future<void> _loadCategories() async {
    final categories = await _menuService.getCategories();
    if (mounted) setState(() => _categories = categories);
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<SellerMenuProvider>();
    final price = double.parse(_priceController.text);
    final stock = int.parse(_stockController.text);

    bool success;
    if (widget.isEditMode) {
      success = await provider.updateMenu(
        menuId: widget.existingMenu!.id,
        sellerId: widget.sellerId,
        categoryId: _selectedCategoryId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: price,
        stock: stock,
        imageFile: _pickedImage,
        existingImageUrl: widget.existingMenu!.imageUrl,
      );
    } else {
      success = await provider.createMenu(
        sellerId: widget.sellerId,
        categoryId: _selectedCategoryId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: price,
        stock: stock,
        imageFile: _pickedImage,
      );
    }

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Gagal menyimpan menu')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existingMenu;

    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditMode ? 'Edit Menu' : 'Tambah Menu')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _pickedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_pickedImage!, fit: BoxFit.cover),
                        )
                      : (existing?.imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(existing!.imageUrl!, fit: BoxFit.cover),
                            )
                          : const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_outlined, size: 32),
                                  SizedBox(height: 8),
                                  Text('Tambah Foto Menu'),
                                ],
                              ),
                            )),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Menu'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: _categories
                    .map((cat) => DropdownMenuItem(value: cat.id, child: Text(cat.name)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedCategoryId = value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Harga (Rp)'),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Wajib diisi';
                        if (double.tryParse(value) == null) return 'Angka tidak valid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Stok'),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Wajib diisi';
                        if (int.tryParse(value) == null) return 'Angka tidak valid';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Consumer<SellerMenuProvider>(
                builder: (context, provider, _) {
                  return ElevatedButton(
                    onPressed: provider.isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    child: provider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.isEditMode ? 'Simpan Perubahan' : 'Tambah Menu'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
