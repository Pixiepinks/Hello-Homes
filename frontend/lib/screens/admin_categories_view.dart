import '../utils/constants.dart';
import '../utils/supabase_storage_upload_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_theme.dart';
import '../models/category.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';

class AdminCategoriesView extends StatefulWidget {
  const AdminCategoriesView({super.key});

  @override
  State<AdminCategoriesView> createState() => _AdminCategoriesViewState();
}

class _AdminCategoriesViewState extends State<AdminCategoriesView> {
  bool _isAdding = false;
  bool _isManagingSubcategories = false;
  Category? _editingCategory;
  Category? _selectedParentCategory;
  Subcategory? _editingSubcategory;
  bool _isLoading = true;
  List<Category> _categories = [];
  
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _subcategoryNameController = TextEditingController();
  final _subcategoryImageUrlController = TextEditingController();
  bool _subcategoryIsActive = true;

  bool _isSubmitting = false;
  bool _isUploadingImage = false;
  final ImagePicker _imagePicker = ImagePicker();
  final SupabaseStorageUploadService _uploadService = SupabaseStorageUploadService();

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(Uri.parse('${AppConstants.apiUrl}/categories'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _categories = data.map((item) => Category(
              id: item['id'].toString(),
              title: item['title'] ?? '',
              subtitle: '',
              imageUrl: item['image_url'] ?? '',
              subcategories: item['subcategories'] is List
                  ? (item['subcategories'] as List).map((sub) => Subcategory.fromJson(sub)).toList()
                  : const [],
            )).toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading categories: $e')));
      }
    }
  }

  void _showUploadMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickAndUploadCategoryImage() async {
    setState(() => _isUploadingImage = true);
    try {
      final file = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (file == null) return;

      final url = await _uploadService.uploadImage(
        file: file,
        bucket: AppConstants.supabaseCategoryBucket,
        folder: 'categories',
      );
      if (url == null) {
        _showUploadMessage('Image upload is not configured. Please configure Supabase storage.');
        return;
      }

      setState(() => _imageUrlController.text = url);
      _showUploadMessage('Category image uploaded.');
    } catch (e) {
      _showUploadMessage('Image upload failed: $e');
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _submitCategory() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      final bodyData = json.encode({
        'title': _titleController.text,
        'image_url': _imageUrlController.text,
      });

      final token = context.read<AuthProvider>().token;
      http.Response response;
      if (_editingCategory != null) {
        response = await http.put(
          Uri.parse('${AppConstants.apiUrl}/categories/${_editingCategory!.id}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: bodyData,
        );
      } else {
        response = await http.post(
          Uri.parse('${AppConstants.apiUrl}/categories'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: bodyData,
        );
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_editingCategory != null ? 'Category updated successfully!' : 'Category added successfully!')),
        );
        _clearForm();
        _fetchCategories();
      } else {
        throw Exception('Failed to save category');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deleteCategory(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this category?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token;
      final response = await http.delete(
        Uri.parse('${AppConstants.apiUrl}/categories/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category deleted successfully!')));
        _fetchCategories();
      } else {
        throw Exception('Failed to delete category');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _clearForm() {
    setState(() {
      _isAdding = false;
      _editingCategory = null;
      _titleController.clear();
      _imageUrlController.clear();
      _isManagingSubcategories = false;
      _selectedParentCategory = null;
      _clearSubcategoryForm(updateState: false);
    });
  }

  void _populateForm(Category category) {
    _editingCategory = category;
    _titleController.text = category.title;
    _imageUrlController.text = category.imageUrl;
    
    setState(() => _isAdding = true);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (_isAdding) {
      return _buildAddCategoryForm();
    }
    if (_isManagingSubcategories && _selectedParentCategory != null) {
      return _buildManageSubcategoriesView();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        isMobile 
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Manage Categories', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _clearForm();
                      setState(() => _isAdding = true);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add New Category'),
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Manage Categories', style: Theme.of(context).textTheme.displaySmall),
                ElevatedButton.icon(
                  onPressed: () {
                    _clearForm();
                    setState(() => _isAdding = true);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Category'),
                ),
              ],
            ),
        const SizedBox(height: 32),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _categories.isEmpty
                ? const Center(child: Text('No categories available. Add one!'))
                : ListView.separated(
                    itemCount: _categories.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            image: category.imageUrl.isNotEmpty
                                ? DecorationImage(image: NetworkImage(category.imageUrl), fit: BoxFit.cover)
                                : null,
                          ),
                          child: category.imageUrl.isEmpty ? const Icon(Icons.category, color: Colors.grey) : null,
                        ),
                        title: Text(category.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${category.subcategories.length} subcategor${category.subcategories.length == 1 ? 'y' : 'ies'}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.account_tree_outlined),
                              label: const Text('Manage Subcategories'),
                              onPressed: () => _showSubcategories(category),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: AppTheme.primaryBlue),
                              onPressed: () => _populateForm(category),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteCategory(category.id),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }


  void _showSubcategories(Category category) {
    setState(() {
      _selectedParentCategory = category;
      _isManagingSubcategories = true;
      _clearSubcategoryForm(updateState: false);
    });
  }

  void _clearSubcategoryForm({bool updateState = true}) {
    void clear() {
      _editingSubcategory = null;
      _subcategoryNameController.clear();
      _subcategoryImageUrlController.clear();
      _subcategoryIsActive = true;
    }
    if (updateState) {
      setState(clear);
    } else {
      clear();
    }
  }

  void _populateSubcategoryForm(Subcategory subcategory) {
    setState(() {
      _editingSubcategory = subcategory;
      _subcategoryNameController.text = subcategory.name;
      _subcategoryImageUrlController.text = subcategory.imageUrl;
      _subcategoryIsActive = subcategory.isActive;
    });
  }

  Future<void> _submitSubcategory() async {
    if (_selectedParentCategory == null || _subcategoryNameController.text.trim().isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      final token = context.read<AuthProvider>().token;
      final bodyData = json.encode({
        'category_id': int.tryParse(_selectedParentCategory!.id),
        'name': _subcategoryNameController.text.trim(),
        'image_url': _subcategoryImageUrlController.text.trim(),
        'is_active': _subcategoryIsActive,
      });
      final uri = _editingSubcategory == null
          ? Uri.parse('${AppConstants.apiUrl}/subcategories')
          : Uri.parse('${AppConstants.apiUrl}/subcategories/${_editingSubcategory!.id}');
      final response = _editingSubcategory == null
          ? await http.post(uri, headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}, body: bodyData)
          : await http.put(uri, headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}, body: bodyData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_editingSubcategory == null ? 'Subcategory added successfully!' : 'Subcategory updated successfully!')));
        await _fetchCategories();
        final refreshed = _categories.firstWhere((c) => c.id == _selectedParentCategory!.id, orElse: () => _selectedParentCategory!);
        setState(() => _selectedParentCategory = refreshed);
        _clearSubcategoryForm();
      } else {
        throw Exception('Failed to save subcategory');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deleteSubcategory(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this subcategory?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final token = context.read<AuthProvider>().token;
      final response = await http.delete(Uri.parse('${AppConstants.apiUrl}/subcategories/$id'), headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        await _fetchCategories();
        final refreshed = _categories.firstWhere((c) => c.id == _selectedParentCategory!.id, orElse: () => _selectedParentCategory!);
        setState(() => _selectedParentCategory = refreshed);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subcategory deleted successfully!')));
      } else {
        throw Exception('Failed to delete subcategory');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildManageSubcategoriesView() {
    final category = _selectedParentCategory!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _isManagingSubcategories = false)),
              Expanded(child: Text('Manage Subcategories: ${category.title}', style: Theme.of(context).textTheme.headlineMedium)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderLight)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_editingSubcategory == null ? 'Add Subcategory' : 'Edit Subcategory', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 16),
                TextFormField(controller: _subcategoryNameController, decoration: const InputDecoration(labelText: 'Subcategory name')),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: category.id,
                  decoration: const InputDecoration(labelText: 'Parent category'),
                  items: _categories.map((c) => DropdownMenuItem<String>(value: c.id, child: Text(c.title))).toList(),
                  onChanged: (value) {
                    final selected = _categories.firstWhere((c) => c.id == value, orElse: () => category);
                    setState(() => _selectedParentCategory = selected);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(controller: _subcategoryImageUrlController, decoration: const InputDecoration(labelText: 'Optional image URL')),
                const SizedBox(height: 8),
                SwitchListTile(value: _subcategoryIsActive, title: const Text('Active'), onChanged: (value) => setState(() => _subcategoryIsActive = value)),
                const SizedBox(height: 16),
                Wrap(spacing: 12, children: [
                  ElevatedButton(onPressed: _isSubmitting ? null : _submitSubcategory, child: Text(_editingSubcategory == null ? 'Save Subcategory' : 'Update Subcategory')),
                  TextButton(onPressed: () => _clearSubcategoryForm(), child: const Text('Clear')),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderLight)),
            child: category.subcategories.isEmpty
                ? const Padding(padding: EdgeInsets.all(24), child: Text('No subcategories available.'))
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: category.subcategories.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final subcategory = category.subcategories[index];
                      return ListTile(
                        leading: Icon(subcategory.isActive ? Icons.check_circle : Icons.pause_circle, color: subcategory.isActive ? Colors.green : Colors.grey),
                        title: Text(subcategory.name),
                        subtitle: Text(subcategory.isActive ? 'Active' : 'Inactive'),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(icon: const Icon(Icons.edit, color: AppTheme.primaryBlue), onPressed: () => _populateSubcategoryForm(subcategory)),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteSubcategory(subcategory.id)),
                        ]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(String url) {
    return Container(
      width: 160,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: url.trim().isEmpty
          ? const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_outlined, color: Colors.grey, size: 36),
                SizedBox(height: 8),
                Text('Image preview', style: TextStyle(color: Colors.grey)),
              ],
            )
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: Colors.grey),
            ),
    );
  }

  Widget _buildSupabaseConfigurationNotice() {
    final urlConfigured = AppConstants.supabaseUrl.isNotEmpty;
    final anonKeyConfigured = AppConstants.supabaseAnonKey.isNotEmpty;
    final isConfigured = AppConstants.isSupabaseStorageConfigured;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isConfigured ? Colors.green.shade50 : Colors.amber.shade50,
        border: Border.all(color: isConfigured ? Colors.green.shade200 : Colors.amber.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isConfigured) ...[
            const Text(
              'Image upload is not configured. Configure Supabase before uploading category images.',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
          ],
          const Text('Supabase upload configuration', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Supabase URL configured: ${urlConfigured ? 'yes' : 'no'}'),
          Text('Anon key configured: ${anonKeyConfigured ? 'yes' : 'no'}'),
          Text('Bucket name: ${AppConstants.supabaseCategoryBucket}'),
        ],
      ),
    );
  }

  Widget _buildCategoryImageUploader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSupabaseConfigurationNotice(),
        const Text('Category image', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _imageUrlController,
              builder: (_, value, __) => _buildImagePreview(value.text),
            ),
            ElevatedButton.icon(
              onPressed: _isUploadingImage ? null : _pickAndUploadCategoryImage,
              icon: _isUploadingImage
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text(_isUploadingImage ? 'Uploading...' : 'Upload Category Image'),
            ),
          ],
        ),
        if (_isUploadingImage) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
        ],
        const SizedBox(height: 8),
        const Text('Accepted formats: JPG, JPEG, PNG, WEBP. Maximum size: 5MB.', style: TextStyle(color: AppTheme.textMuted)),
      ],
    );
  }

  Widget _buildAddCategoryForm() {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_editingCategory != null ? 'Edit Category' : 'Add New Category', style: Theme.of(context).textTheme.headlineMedium),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _clearForm,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Category Title'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildCategoryImageUploader(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitCategory,
                  child: _isSubmitting 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_editingCategory != null ? 'Update Category' : 'Save Category'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
