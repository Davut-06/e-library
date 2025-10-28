import 'package:e_library/design/colors.dart';
import 'package:flutter/material.dart';

class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  bool _horrorChecked = false;
  bool _detectiveChecked = false;
  bool _ebookChecked = false;
  bool _newspaperChecked = false;
  bool _romanceChecked = false;
  bool _actionChecked = false;
  bool _magazineChecked = false;
  bool _bookChecked = false;

  void _resetFilters() {
    setState(() {
      _romanceChecked = false;
      _horrorChecked = false;
      _actionChecked = false;
      _detectiveChecked = false;
      _ebookChecked = false;
      _magazineChecked = false;
      _newspaperChecked = false;
      _bookChecked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Filter',
          selectionColor: secondaryColor,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: iconColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                const Text(
                  'Genre',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: secondaryColor,
                  ),
                ),

                _buildCheckboxTile(
                  'Romance',
                  _romanceChecked,
                  (val) => _romanceChecked = val,
                ),
                _buildCheckboxTile(
                  'Horror',
                  _horrorChecked,
                  (val) => _horrorChecked = val,
                ),
                _buildCheckboxTile(
                  'Action',
                  _actionChecked,
                  (val) => _actionChecked = val,
                ),
                _buildCheckboxTile(
                  'Detective',
                  _detectiveChecked,
                  (val) => _detectiveChecked = val,
                ),
                const SizedBox(height: 20),

                const Text(
                  'Year',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: secondaryColor,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'From',
                          hintStyle: TextStyle(
                            color: textPrimaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide(color: searchColor),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '—',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'To',
                          hintStyle: TextStyle(
                            color: textPrimaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide(color: searchColor),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                const Text(
                  'Type',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: secondaryColor,
                  ),
                ),
                _buildCheckboxTile(
                  'Book',
                  _bookChecked,
                  (val) => _bookChecked = val,
                ),
                _buildCheckboxTile(
                  'E-book',
                  _ebookChecked,
                  (val) => _ebookChecked = val,
                ),
                _buildCheckboxTile(
                  'Magazine',
                  _magazineChecked,
                  (val) => _magazineChecked = val,
                ),
                _buildCheckboxTile(
                  'Newspaper',
                  _newspaperChecked,
                  (val) => _newspaperChecked = val,
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetFilters, // Вызываем функцию сброса
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      side: const BorderSide(color: Colors.grey),
                    ),
                    child: const Text(
                      'Reset',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxTile(
    String title,
    bool value,
    Function(bool) onChanged,
  ) {
    const Color activeColor = Color(0xFF5D87FF);
    const Color inactiveBorderColor = Color(0xFFC8D7F1);

    return CheckboxListTile(
      title: Text(
        title,
        style: const TextStyle(
          color: secondaryColor,
          fontWeight: FontWeight.w400,
        ),
      ),
      value: value,
      onChanged: (val) {
        setState(() {
          onChanged(val ?? false);
        });
      },
      controlAffinity: ListTileControlAffinity.leading,

      fillColor: WidgetStateProperty.resolveWith<Color>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.selected)) {
          return activeColor;
        }
        return Colors.transparent;
      }),

      checkboxShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(
          color: value ? activeColor : inactiveBorderColor,
          width: 1.5,
        ),
      ),

      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
    );
  }
}
