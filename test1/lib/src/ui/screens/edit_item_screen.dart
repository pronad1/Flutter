import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/item_service.dart';

class EditItemScreen extends StatefulWidget {
  final String itemId;
  const EditItemScreen({super.key, required this.itemId});

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final _service = ItemService();
  final _formKey = GlobalKey<FormState>();

  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _address = TextEditingController();
  String? _category;
  String? _condition;
  bool _available = true;

  final _picker = ImagePicker();
  XFile? _picked;
  Uint8List? _webBytes;
  File? _file;

  bool _busy = true;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final item = await _service.getItemById(widget.itemId);
      if (!mounted) return;

      setState(() {
        _title.text = item.title;
        _desc.text = item.description;
        _address.text = item.pickupAddress ?? '';
        _category = item.category;
        _condition = item.condition;
        _available = item.available;
        _currentImageUrl = item.imageUrl;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load item: $e')),
      );
      Navigator.pop(context);
    }
  }

  ImageProvider? _preview() {
    if (_webBytes != null) return MemoryImage(_webBytes!);
    if (_file != null) return FileImage(_file!);
    if ((_currentImageUrl ?? '').isNotEmpty) return NetworkImage(_currentImageUrl!);
    return null;
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() {
      _picked = picked;
      if (kIsWeb) {
        picked.readAsBytes().then((bytes) {
          if (mounted) setState(() => _webBytes = bytes);
        });
        _file = null;
      } else {
        _file = File(picked.path);
        _webBytes = null;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    try {
      await _service.updateItem(
        itemId: widget.itemId,
        title: _title.text.trim(),
        description: _desc.text.trim(),
        category: _category,
        condition: _condition,
        pickupAddress: _address.text.trim().isNotEmpty ? _address.text.trim() : null,
        available: _available,
        newImageFile: _picked, // only if user picked new image
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item updated successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Item')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final preview = _preview();

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 56,
                  backgroundImage: preview,
                  child: preview == null
                      ? const Icon(Icons.add_a_photo, size: 40)
                      : null,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _title,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                v == null || v.trim().isEmpty ? 'Enter a title' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _desc,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                v == null || v.trim().isEmpty ? 'Enter a description' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _address,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Pickup Address (Optional)',
                  hintText: 'Where can seekers pick up this item?',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _category,
                      items: const [
                        DropdownMenuItem(value: 'Home', child: Text('Home')),
                        DropdownMenuItem(
                            value: 'Electronics', child: Text('Electronics')),
                        DropdownMenuItem(value: 'Books', child: Text('Books')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (v) => setState(() => _category = v),
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                      v == null ? 'Select a category' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _condition,
                      items: const [
                        DropdownMenuItem(value: 'New', child: Text('New')),
                        DropdownMenuItem(value: 'Good', child: Text('Good')),
                        DropdownMenuItem(value: 'Used', child: Text('Used')),
                      ],
                      onChanged: (v) => setState(() => _condition = v),
                      decoration: const InputDecoration(
                        labelText: 'Condition',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                      v == null ? 'Select condition' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              SwitchListTile(
                value: _available,
                onChanged: (v) => setState(() => _available = v),
                title: const Text('Available'),
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Save Changes'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
