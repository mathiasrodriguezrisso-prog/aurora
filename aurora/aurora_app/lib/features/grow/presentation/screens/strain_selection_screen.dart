
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_theme.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/aurora_text_field.dart';

class StrainSelectionScreen extends StatefulWidget {
  const StrainSelectionScreen({super.key});

  @override
  State<StrainSelectionScreen> createState() => _StrainSelectionScreenState();
}

class _StrainSelectionScreenState extends State<StrainSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  final List<Map<String, String>> _allStrains = [
    {'name': 'Blue Dream', 'type': 'Hybrid', 'flower_weeks': '9-10'},
    {'name': 'OG Kush', 'type': 'Hybrid', 'flower_weeks': '8-9'},
    {'name': 'White Widow', 'type': 'Hybrid', 'flower_weeks': '8-9'},
    {'name': 'Northern Lights', 'type': 'Indica', 'flower_weeks': '7-8'},
    {'name': 'Girl Scout Cookies', 'type': 'Hybrid', 'flower_weeks': '9-10'},
    {'name': 'Gorilla Glue', 'type': 'Hybrid', 'flower_weeks': '8-9'},
    {'name': 'Gelato', 'type': 'Hybrid', 'flower_weeks': '8-9'},
    {'name': 'Amnesia Haze', 'type': 'Sativa', 'flower_weeks': '10-12'},
    {'name': 'Sour Diesel', 'type': 'Sativa', 'flower_weeks': '10-11'},
    {'name': 'Jack Herer', 'type': 'Sativa', 'flower_weeks': '8-10'},
    {'name': 'Purple Punch', 'type': 'Indica', 'flower_weeks': '7-8'},
    {'name': 'Wedding Cake', 'type': 'Hybrid', 'flower_weeks': '8-9'},
    {'name': 'Zkittlez', 'type': 'Indica', 'flower_weeks': '8-9'},
    {'name': 'Critical Mass', 'type': 'Indica', 'flower_weeks': '7-8'},
    {'name': 'AK-47', 'type': 'Hybrid', 'flower_weeks': '8-9'},
  ];

  List<Map<String, String>> _filteredStrains = [];

  @override
  void initState() {
    super.initState();
    _filteredStrains = _allStrains;
  }

  void _filterStrains(String query) {
    setState(() {
      _filteredStrains = _allStrains
          .where((strain) => strain['name']!.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text("Select Your Strain")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AuroraTextField(
              hint: 'Search strain...',
              prefixIcon: Icons.search,
              controller: _searchController,
              onChanged: _filterStrains,
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: _filteredStrains.length,
              itemBuilder: (context, index) {
                final strain = _filteredStrains[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: GestureDetector(
                    onTap: () {
                      context.push('/grow/config', extra: {'strain': strain['name']});
                    },
                    child: GlassContainer(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black26, 
                            ),
                            child: const Icon(Icons.eco, color: AppTheme.primary, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  strain['name']!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${strain['type']} • ${strain['flower_weeks']} weeks',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white24),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
