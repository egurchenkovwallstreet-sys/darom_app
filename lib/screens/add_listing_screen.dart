import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/listing.dart';
import '../services/listings_api.dart';
import '../services/location_service.dart';
import '../widgets/super_donor_offer_dialog.dart';
import '../widgets/midnight_glow_screen.dart';
import '../widgets/listing_photo_image.dart';
import '../widgets/primary_action_button.dart';

class _PickedPhoto {
  final Uint8List bytes;
  final String name;

  const _PickedPhoto({required this.bytes, required this.name});
}

class AddListingScreen extends StatefulWidget {
  final String phoneNumber;
  final Listing? editingListing;
  final bool inShell;
  final VoidCallback? onPublished;
  final ValueChanged<Listing>? onSaved;

  const AddListingScreen({
    super.key,
    required this.phoneNumber,
    this.editingListing,
    this.inShell = false,
    this.onPublished,
    this.onSaved,
  });

  bool get isEditing => editingListing != null;

  @override
  State<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ListingsApi _listingsApi = ListingsApi();
  final LocationService _locationService = LocationService();

  String _selectedCategory = 'Одежда';
  String _selectedSubcategory = 'Мужская';
  bool _isPhotoPressed = false;
  bool _isPublishing = false;
  final ImagePicker _imagePicker = ImagePicker();
  final List<_PickedPhoto> _photos = [];
  List<String> _existingPhotoUrls = [];
  static const int _maxPhotos = 5;

  int get _totalPhotoCount => _existingPhotoUrls.length + _photos.length;

  bool get _isEditing => widget.editingListing != null;

  final Map<String, List<String>> _subcategories = {
    'Одежда': ['Мужская', 'Женская', 'Детская', 'Обувь', 'Аксессуары'],
    'Мебель': ['Гостиная', 'Спальня', 'Кухня', 'Офис', 'Детская'],
    'Детское': ['Коляски', 'Автокресла', 'Игрушки', 'Одежда', 'Книги'],
    'Электроника': ['Телефоны', 'Компьютеры', 'Планшеты', 'Аудио', 'Бытовая техника'],
    'Книги': ['Художественная', 'Учебная', 'Научная', 'Детская', 'Комиксы'],
    'Посуда': ['Кастрюли', 'Тарелки', 'Чашки', 'Столовые приборы', 'Контейнеры'],
    'Спорт': ['Велосипеды', 'Тренажеры', 'Инвентарь', 'Одежда', 'Туризм'],
    'Другое': ['Разное', 'Стройматериалы', 'Коллекционное', 'Товары для дома', 'Прочее'],
  };

  @override
  void initState() {
    super.initState();
    final existing = widget.editingListing;
    if (existing != null) {
      _titleController.text = existing.title;
      _descriptionController.text = existing.description;
      _selectedCategory = existing.category;
      _selectedSubcategory = existing.subcategory;
      _existingPhotoUrls = List<String>.from(existing.photoUrls);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _listingsApi.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (_isPublishing) return;

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Заполните все поля'),
          backgroundColor: Color(0xFFFF5722),
        ),
      );
      return;
    }

    setState(() => _isPublishing = true);

    try {
      if (_isEditing) {
        var updated = await _listingsApi.updateListing(
          listingId: widget.editingListing!.id,
          phone: widget.phoneNumber,
          title: title,
          description: description,
          category: _selectedCategory,
          subcategory: _selectedSubcategory,
        );

        for (final photo in _photos) {
          updated = await _listingsApi.uploadPhoto(
            listingId: widget.editingListing!.id,
            phone: widget.phoneNumber,
            bytes: photo.bytes,
            fileName: photo.name,
          );
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Изменения сохранены!'),
            backgroundColor: Color(0xFF00BFFF),
          ),
        );
        widget.onSaved?.call(updated);
        if (!widget.inShell) Navigator.pop(context, updated);
        return;
      }

      final position = await _locationService.getCurrentPosition();
      final lat = position?.lat ?? GeoPosition.moscow.lat;
      final lng = position?.lng ?? GeoPosition.moscow.lng;

      final listing = await _listingsApi.create(
        phone: widget.phoneNumber,
        title: title,
        description: description,
        category: _selectedCategory,
        subcategory: _selectedSubcategory,
        lat: lat,
        lng: lng,
      );

      for (final photo in _photos) {
        await _listingsApi.uploadPhoto(
          listingId: listing.id,
          phone: widget.phoneNumber,
          bytes: photo.bytes,
          fileName: photo.name,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Объявление опубликовано!'),
          backgroundColor: Color(0xFF00BFFF),
        ),
      );
      widget.onPublished?.call();
      if (widget.inShell) {
        _titleController.clear();
        _descriptionController.clear();
        setState(() {
          _photos.clear();
          _selectedCategory = 'Одежда';
          _selectedSubcategory = 'Мужская';
        });
      } else {
        Navigator.pop(context);
      }
    } catch (error) {
      if (!mounted) return;

      if (error is ListingLimitException) {
        setState(() => _isPublishing = false);
        final activated = await showSuperDonorOfferDialog(
          context,
          limitInfo: error.limitInfo,
          phoneNumber: widget.phoneNumber,
        );
        if (activated == true && mounted) {
          await _publish();
        }
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_publishErrorMessage(error)),
          backgroundColor: const Color(0xFFFF5722),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }

  String _publishErrorMessage(Object error) {
    if (error is http.ClientException) {
      return 'Сервер не отвечает. Проверьте Терминал 1: backend должен работать (npm run dev)';
    }
    if (error is ListingsApiException) {
      return error.message;
    }
    return 'Ошибка: $error';
  }

  Future<void> _pickPhotos() async {
    if (_totalPhotoCount >= _maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Максимум $_maxPhotos фото'),
          backgroundColor: const Color(0xFFFF5722),
        ),
      );
      return;
    }

    final picked = await _imagePicker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (picked.isEmpty || !mounted) return;

    final remaining = _maxPhotos - _totalPhotoCount;
    final toAdd = picked.take(remaining);

    final newPhotos = <_PickedPhoto>[];
    for (final file in toAdd) {
      final bytes = await file.readAsBytes();
      newPhotos.add(
        _PickedPhoto(
          bytes: bytes,
          name: _photoFileName(file),
        ),
      );
    }

    setState(() => _photos.addAll(newPhotos));
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  String _photoFileName(XFile file) {
    if (file.name.isNotEmpty) return file.name;
    final mime = file.mimeType ?? '';
    if (mime.contains('png')) return 'photo.png';
    if (mime.contains('webp')) return 'photo.webp';
    return 'photo.jpg';
  }

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(child: _buildContent());
    if (widget.inShell) return content;
    return MidnightGlowScreen(child: content);
  }

  Widget _buildContent() {
    return Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      children: [
                        if (!widget.inShell)
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: Color(0xFF001F3F).withOpacity(0.85),
                                shape: BoxShape.circle,
                                border: Border.all(color: Color(0xFF00BFFF), width: 2),
                              ),
                              child: Icon(Icons.arrow_back, color: Color(0xFF00BFFF)),
                            ),
                          )
                              .animate(
                                delay: Duration(milliseconds: 200),
                              )
                              .fadeIn(duration: Duration(milliseconds: 600))
                              .scale(begin: Offset(0.8, 0.8), end: Offset(1.0, 1.0)),
                        if (!widget.inShell) SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            _isEditing ? 'Редактировать' : 'Новое объявление',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFFFFFF),
                              shadows: [
                                Shadow(
                                  color: Color(0xFF00BFFF).withOpacity(0.6),
                                  offset: Offset(0, 4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          )
                              .animate(
                                delay: Duration(milliseconds: 300),
                              )
                              .fadeIn(duration: Duration(milliseconds: 800))
                              .slideX(begin: -0.3, end: 0),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Color(0xFF001F3F).withOpacity(0.85),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Color(0xFF00BFFF), width: 2),
                            ),
                            child: TextField(
                              controller: _titleController,
                              style: TextStyle(
                                fontSize: 18,
                                color: Color(0xFFFFFFFF),
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Название объявления',
                                hintStyle: TextStyle(
                                  color: Color(0xFFFFFFFF).withOpacity(0.4),
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                                prefixIcon: Icon(
                                  Icons.title,
                                  color: Color(0xFF00BFFF),
                                  size: 24,
                                ),
                              ),
                            ),
                          )
                              .animate(
                                delay: Duration(milliseconds: 400),
                              )
                              .fadeIn(duration: Duration(milliseconds: 800))
                              .slideY(begin: 0.3, end: 0),
                          
                          SizedBox(height: 15),

                          Container(
                            padding: EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Color(0xFF001F3F).withOpacity(0.85),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Color(0xFF00BFFF), width: 2),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.category, color: Color(0xFF00BFFF), size: 24),
                                SizedBox(width: 15),
                                Expanded(
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedCategory,
                                      dropdownColor: Color(0xFF001F3F),
                                      style: TextStyle(
                                        color: Color(0xFFFFFFFF),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      icon: Icon(Icons.arrow_drop_down, color: Color(0xFF00BFFF)),
                                      items: _subcategories.keys.map((String category) {
                                        return DropdownMenuItem<String>(
                                          value: category,
                                          child: Text(category),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        if (newValue != null) {
                                          setState(() {
                                            _selectedCategory = newValue;
                                            _selectedSubcategory = _subcategories[newValue]!.first;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                              .animate(
                                delay: Duration(milliseconds: 500),
                              )
                              .fadeIn(duration: Duration(milliseconds: 800))
                              .slideY(begin: 0.3, end: 0),
                          
                          SizedBox(height: 15),

                          Container(
                            padding: EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Color(0xFF001F3F).withOpacity(0.85),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Color(0xFF008C8C), width: 2),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.subdirectory_arrow_right, color: Color(0xFF008C8C), size: 24),
                                SizedBox(width: 15),
                                Expanded(
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedSubcategory,
                                      dropdownColor: Color(0xFF001F3F),
                                      style: TextStyle(
                                        color: Color(0xFFFFFFFF),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      icon: Icon(Icons.arrow_drop_down, color: Color(0xFF008C8C)),
                                      items: _subcategories[_selectedCategory]!.map((String subcategory) {
                                        return DropdownMenuItem<String>(
                                          value: subcategory,
                                          child: Text(subcategory),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        if (newValue != null) {
                                          setState(() {
                                            _selectedSubcategory = newValue;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                              .animate(
                                delay: Duration(milliseconds: 600),
                              )
                              .fadeIn(duration: Duration(milliseconds: 800))
                              .slideY(begin: 0.3, end: 0),
                          
                          SizedBox(height: 15),

                          Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Color(0xFF001F3F).withOpacity(0.85),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Color(0xFF00BFFF), width: 2),
                            ),
                            child: TextField(
                              controller: _descriptionController,
                              maxLines: 5,
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFFFFFFFF),
                              ),
                              decoration: InputDecoration(
                                hintText: 'Описание товара',
                                hintStyle: TextStyle(
                                  color: Color(0xFFFFFFFF).withOpacity(0.4),
                                  fontSize: 15,
                                ),
                                border: InputBorder.none,
                                prefixIcon: Icon(
                                  Icons.description,
                                  color: Color(0xFF00BFFF),
                                  size: 24,
                                ),
                              ),
                            ),
                          )
                              .animate(
                                delay: Duration(milliseconds: 700),
                              )
                              .fadeIn(duration: Duration(milliseconds: 800))
                              .slideY(begin: 0.3, end: 0),
                          
                          SizedBox(height: 15),

                          GestureDetector(
                            onTapDown: (_) => setState(() => _isPhotoPressed = true),
                            onTapUp: (_) => setState(() => _isPhotoPressed = false),
                            onTapCancel: () => setState(() => _isPhotoPressed = false),
                            onTap: _pickPhotos,
                            child: AnimatedScale(
                              scale: _isPhotoPressed ? 1.08 : 1.0,
                              duration: Duration(milliseconds: 150),
                              curve: Curves.easeOut,
                              child: Container(
                                constraints: const BoxConstraints(minHeight: 120),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Color(0xFF001F3F).withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: Color(0xFF00BFFF), width: 2, strokeAlign: BorderSide.strokeAlignOutside),
                                ),
                                child: _totalPhotoCount == 0
                                    ? Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          Icon(
                                            Icons.add_a_photo,
                                            size: 40,
                                            color: Color(0xFF00BFFF),
                                          ),
                                          SizedBox(height: 10),
                                          Text(
                                            'Добавить фото',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Color(0xFF00BFFF),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'До 5 фото (JPG, PNG)',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0x80FFFFFF),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Фото: $_totalPhotoCount/$_maxPhotos',
                                            style: const TextStyle(
                                              color: Color(0xFF00BFFF),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              ...List.generate(_existingPhotoUrls.length, (index) {
                                                return ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: ListingPhotoImage(
                                                    url: _existingPhotoUrls[index],
                                                    width: 72,
                                                    height: 72,
                                                    borderRadius: 8,
                                                  ),
                                                );
                                              }),
                                              ...List.generate(_photos.length, (index) {
                                                return Stack(
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius: BorderRadius.circular(8),
                                                      child: Image.memory(
                                                        _photos[index].bytes,
                                                        width: 72,
                                                        height: 72,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                    Positioned(
                                                      top: 0,
                                                      right: 0,
                                                      child: GestureDetector(
                                                        onTap: () => _removePhoto(index),
                                                        child: Container(
                                                          decoration: const BoxDecoration(
                                                            color: Color(0xFFFF5722),
                                                            shape: BoxShape.circle,
                                                          ),
                                                          child: const Icon(
                                                            Icons.close,
                                                            size: 16,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              }),
                                              if (_totalPhotoCount < _maxPhotos)
                                                Container(
                                                  width: 72,
                                                  height: 72,
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(color: const Color(0xFF00BFFF)),
                                                  ),
                                                  child: const Icon(
                                                    Icons.add,
                                                    color: Color(0xFF00BFFF),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          )
                              .animate(
                                delay: Duration(milliseconds: 800),
                              )
                              .fadeIn(duration: Duration(milliseconds: 800))
                              .slideY(begin: 0.3, end: 0),
                          
                          SizedBox(height: 30),

                          PrimaryActionButton(
                            label: _isEditing ? 'Сохранить' : 'Опубликовать',
                            loading: _isPublishing,
                            onPressed: _publish,
                          )
                              .animate(
                                delay: Duration(milliseconds: 900),
                              )
                              .fadeIn(duration: Duration(milliseconds: 800))
                              .slideY(begin: 0.3, end: 0),
                          
                          SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ],
    );
  }
}