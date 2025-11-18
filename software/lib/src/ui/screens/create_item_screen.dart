import 'dart:typed_data';
import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../widgets/chatbot/chatbot_wrapper.dart';
import '../../services/item_service.dart';

class CreateItemScreen extends StatefulWidget {
  const CreateItemScreen({super.key});

  @override
  State<CreateItemScreen> createState() => _CreateItemScreenState();
}

class _CreateItemScreenState extends State<CreateItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _address = TextEditingController();
  final _price = TextEditingController();
  String? _category;
  String? _condition;
  bool _isSelling = false;  // Toggle for donation vs selling

  final _picker = ImagePicker();
  XFile? _picked;
  Uint8List? _webBytes;
  File? _file;
  bool _busy = false;

  final _service = ItemService();

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (picked == null) return;

    _picked = picked;
    if (kIsWeb) {
      _webBytes = await picked.readAsBytes();
      _file = null;
    } else {
      _file = File(picked.path);
      _webBytes = null;
    }
    setState(() {});
  }

  ImageProvider? _preview() {
    if (_webBytes != null) return MemoryImage(_webBytes!);
    if (_file != null) return FileImage(_file!);
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validate price if selling
    if (_isSelling) {
      if (_price.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a price for selling items')),
        );
        return;
      }
      final priceValue = double.tryParse(_price.text);
      if (priceValue == null || priceValue <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid price greater than 0')),
        );
        return;
      }
    }
    
    setState(() => _busy = true);

    try {
      final priceValue = _isSelling && _price.text.trim().isNotEmpty 
          ? double.tryParse(_price.text)
          : null;
          
      final id = await _service.createItem(
        title: _title.text,
        description: _desc.text,
        imageFile: _picked, // optional
        category: _category,
        condition: _condition,
        pickupAddress: _address.text.trim().isNotEmpty ? _address.text.trim() : null,
        price: priceValue,
        isSelling: _isSelling,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item created (id: $id)')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Create failed: $e')),
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
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview();

    return ChatbotWrapper(
      child: Scaffold(
        appBar: AppBar(title: const Text('Post a New Item')),
        body: SafeArea(
          child: _busy
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Image picker / preview
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
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Enter a brief description'
                    : null,
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

              DropdownButtonFormField<String>(
                value: _category,
                items: const [
                  DropdownMenuItem(value: 'Electronics', child: Text('📱 Electronics')),
                  DropdownMenuItem(value: 'Computers & Laptops', child: Text('💻 Computers & Laptops')),
                  DropdownMenuItem(value: 'Mobile Phones', child: Text('📱 Mobile Phones')),
                  DropdownMenuItem(value: 'Home & Furniture', child: Text('🏠 Home & Furniture')),
                  DropdownMenuItem(value: 'Appliances', child: Text('🔌 Appliances')),
                  DropdownMenuItem(value: 'Books & Education', child: Text('📚 Books & Education')),
                  DropdownMenuItem(value: 'Sports & Fitness', child: Text('⚽ Sports & Fitness')),
                  DropdownMenuItem(value: 'Clothing & Fashion', child: Text('👕 Clothing & Fashion')),
                  DropdownMenuItem(value: 'Toys & Games', child: Text('🎮 Toys & Games')),
                  DropdownMenuItem(value: 'Kitchen & Dining', child: Text('🍽️ Kitchen & Dining')),
                  DropdownMenuItem(value: 'Tools & Hardware', child: Text('🔧 Tools & Hardware')),
                  DropdownMenuItem(value: 'Garden & Outdoor', child: Text('🌿 Garden & Outdoor')),
                  DropdownMenuItem(value: 'Baby & Kids', child: Text('👶 Baby & Kids')),
                  DropdownMenuItem(value: 'Health & Beauty', child: Text('💄 Health & Beauty')),
                  DropdownMenuItem(value: 'Automotive', child: Text('🚗 Automotive')),
                  DropdownMenuItem(value: 'Pet Supplies', child: Text('🐾 Pet Supplies')),
                  DropdownMenuItem(value: 'Office Supplies', child: Text('📎 Office Supplies')),
                  DropdownMenuItem(value: 'Art & Crafts', child: Text('🎨 Art & Crafts')),
                  DropdownMenuItem(value: 'Musical Instruments', child: Text('🎸 Musical Instruments')),
                  DropdownMenuItem(value: 'Other', child: Text('📦 Other')),
                ],
                onChanged: (v) => setState(() => _category = v),
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  hintText: 'Select item category',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                validator: (v) => v == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _condition,
                items: const [
                  DropdownMenuItem(value: 'Brand New', child: Text('🌟 Brand New - Unopened/Unused')),
                  DropdownMenuItem(value: 'Like New', child: Text('✨ Like New - Barely Used')),
                  DropdownMenuItem(value: 'Excellent', child: Text('⭐ Excellent - Minimal Wear')),
                  DropdownMenuItem(value: 'Good', child: Text('👍 Good - Some Signs of Use')),
                  DropdownMenuItem(value: 'Fair', child: Text('👌 Fair - Moderate Wear')),
                  DropdownMenuItem(value: 'Used', child: Text('♻️ Used - Well Used')),
                  DropdownMenuItem(value: 'For Parts', child: Text('🔧 For Parts/Repair')),
                ],
                onChanged: (v) => setState(() => _condition = v),
                decoration: const InputDecoration(
                  labelText: 'Condition *',
                  hintText: 'Select item condition',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.star),
                ),
                validator: (v) => v == null ? 'Please select condition' : null,
              ),
              const SizedBox(height: 16),
              
              // Selling Toggle
              Card(
                color: _isSelling ? Colors.orange.shade50 : Colors.green.shade50,
                child: SwitchListTile(
                  title: Text(
                    _isSelling ? 'For Sale' : 'For Donation',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    _isSelling 
                        ? 'This item will be listed for sale' 
                        : 'This item will be donated for free',
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: _isSelling,
                  activeColor: Colors.orange,
                  onChanged: (val) => setState(() => _isSelling = val),
                  secondary: Icon(
                    _isSelling ? Icons.attach_money : Icons.volunteer_activism,
                    color: _isSelling ? Colors.orange : Colors.green,
                  ),
                ),
              ),
              
              // Price field (only shown when selling)
              if (_isSelling) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _price,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Price *',
                    hintText: 'Enter selling price',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.currency_exchange),
                    prefixText: '৳ ',
                    helperText: _condition == 'Brand New' 
                        ? '💡 Brand new items get a SPECIAL badge!' 
                        : null,
                    helperStyle: TextStyle(
                      color: Colors.amber.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  validator: (v) {
                    if (_isSelling && (v == null || v.trim().isEmpty)) {
                      return 'Price is required for selling items';
                    }
                    if (_isSelling) {
                      final price = double.tryParse(v!);
                      if (price == null || price <= 0) {
                        return 'Enter a valid price greater than 0';
                      }
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: Icon(_isSelling ? Icons.sell : Icons.volunteer_activism),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(_isSelling ? 'Post for Sale' : 'Post for Donation'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSelling ? Colors.orange : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
        ),
      ),
    );
  }
}
