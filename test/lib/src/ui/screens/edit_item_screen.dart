import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../widgets/chatbot/chatbot_wrapper.dart';
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
      return ChatbotWrapper(
        child: Scaffold(
          appBar: AppBar(title: const Text('Edit Item')),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final preview = _preview();

    return ChatbotWrapper(
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Edit Item', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
          elevation: 2,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Professional Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade700, Colors.green.shade900],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.edit, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Update Item Details',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Modify your item information',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Item Photo Section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.image, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Item Photo',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.green, width: 3),
                            color: Colors.grey[100],
                          ),
                          child: preview != null
                              ? ClipOval(
                                  child: Image(
                                    image: preview,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo, size: 40, color: Colors.green),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tap to change',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Basic Information Section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Basic Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _title,
                        decoration: InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Enter a title' : null,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _desc,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Enter a description' : null,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _address,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Pickup Address (Optional)',
                          hintText: 'Where can seekers pick up this item?',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[50],
                          prefixIcon: const Icon(Icons.location_on),
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
                              decoration: InputDecoration(
                                labelText: 'Category',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.grey[50],
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
                              decoration: InputDecoration(
                                labelText: 'Condition',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.grey[50],
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
                        tileColor: Colors.grey[50],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.check),
                  label: const Text('Save Changes', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
