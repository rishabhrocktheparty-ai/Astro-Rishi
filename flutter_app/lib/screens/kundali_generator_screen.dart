import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/kundali_provider.dart';
import '../models/models.dart';
import '../theme/cosmic_theme.dart';

class KundaliGeneratorScreen extends StatefulWidget {
  const KundaliGeneratorScreen({super.key});
  @override
  State<KundaliGeneratorScreen> createState() => _KundaliGeneratorScreenState();
}

class _KundaliGeneratorScreenState extends State<KundaliGeneratorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _birthData = BirthData();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _selectedAyanamsa = 'lahiri';
  final _nameCtrl = TextEditingController();
  final _placeCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lonCtrl = TextEditingController();

  final _commonPlaces = <Map<String, dynamic>>[
    {'name': 'New Delhi, India', 'lat': 28.6139, 'lon': 77.2090, 'tz': 'Asia/Kolkata', 'country': 'India'},
    {'name': 'Mumbai, India', 'lat': 19.0760, 'lon': 72.8777, 'tz': 'Asia/Kolkata', 'country': 'India'},
    {'name': 'Chennai, India', 'lat': 13.0827, 'lon': 80.2707, 'tz': 'Asia/Kolkata', 'country': 'India'},
    {'name': 'Kolkata, India', 'lat': 22.5726, 'lon': 88.3639, 'tz': 'Asia/Kolkata', 'country': 'India'},
    {'name': 'Bangalore, India', 'lat': 12.9716, 'lon': 77.5946, 'tz': 'Asia/Kolkata', 'country': 'India'},
    {'name': 'Hyderabad, India', 'lat': 17.3850, 'lon': 78.4867, 'tz': 'Asia/Kolkata', 'country': 'India'},
    {'name': 'Jaipur, India', 'lat': 26.9124, 'lon': 75.7873, 'tz': 'Asia/Kolkata', 'country': 'India'},
    {'name': 'Varanasi, India', 'lat': 25.3176, 'lon': 82.9739, 'tz': 'Asia/Kolkata', 'country': 'India'},
    {'name': 'London, UK', 'lat': 51.5074, 'lon': -0.1278, 'tz': 'Europe/London', 'country': 'UK'},
    {'name': 'New York, USA', 'lat': 40.7128, 'lon': -74.0060, 'tz': 'America/New_York', 'country': 'USA'},
    {'name': 'Los Angeles, USA', 'lat': 34.0522, 'lon': -118.2437, 'tz': 'America/Los_Angeles', 'country': 'USA'},
    {'name': 'Dubai, UAE', 'lat': 25.2048, 'lon': 55.2708, 'tz': 'Asia/Dubai', 'country': 'UAE'},
    {'name': 'Singapore', 'lat': 1.3521, 'lon': 103.8198, 'tz': 'Asia/Singapore', 'country': 'Singapore'},
    {'name': 'Sydney, Australia', 'lat': -33.8688, 'lon': 151.2093, 'tz': 'Australia/Sydney', 'country': 'Australia'},
    {'name': 'Toronto, Canada', 'lat': 43.6532, 'lon': -79.3832, 'tz': 'America/Toronto', 'country': 'Canada'},
  ];

  void _selectPlace(Map<String, dynamic> place) {
    setState(() {
      _placeCtrl.text = place['name'];
      _latCtrl.text = place['lat'].toString();
      _lonCtrl.text = place['lon'].toString();
      _birthData.placeName = place['name'];
      _birthData.latitude = place['lat'];
      _birthData.longitude = place['lon'];
      _birthData.timezone = place['tz'];
      _birthData.country = place['country'];
    });
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(1990, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: CosmicTheme.starGold,
            surface: CosmicTheme.cardBg,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
        _birthData.dateOfBirth = DateFormat('yyyy-MM-dd').format(date);
      });
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 12, minute: 0),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: CosmicTheme.starGold,
            surface: CosmicTheme.cardBg,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
        _birthData.timeOfBirth = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
      });
    }
  }

  Future<void> _generate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time of birth')));
      return;
    }
    if (_birthData.latitude == 0 && _birthData.longitude == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a birth place')));
      return;
    }

    _birthData.name = _nameCtrl.text.trim().isEmpty ? 'My Kundali' : _nameCtrl.text.trim();
    _birthData.ayanamsa = _selectedAyanamsa;

    if (_latCtrl.text.isNotEmpty) _birthData.latitude = double.tryParse(_latCtrl.text) ?? _birthData.latitude;
    if (_lonCtrl.text.isNotEmpty) _birthData.longitude = double.tryParse(_lonCtrl.text) ?? _birthData.longitude;

    final provider = context.read<KundaliProvider>();
    final result = await provider.generateKundali(_birthData);

    if (result != null && mounted) {
      Navigator.pushReplacementNamed(context, '/kundali/dashboard');
    } else if (provider.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${provider.error}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KundaliProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Generate Kundali')),
      body: Container(
        decoration: const BoxDecoration(gradient: CosmicTheme.cosmicGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [CosmicTheme.starGold.withOpacity(0.12), Colors.transparent],
                      ),
                      border: Border.all(color: CosmicTheme.starGold.withOpacity(0.25)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.info_outline, color: CosmicTheme.starGold, size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Text(
                        'Accurate birth time is essential for precise predictions. Even a few minutes can change the ascendant.',
                        style: TextStyle(color: CosmicTheme.moonSilver.withOpacity(0.8), fontSize: 12, height: 1.4),
                      )),
                    ]),
                  ),
                  const SizedBox(height: 28),

                  // Name
                  Text('Name', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(hintText: 'Enter name for this chart', prefixIcon: Icon(Icons.person_outline, size: 20)),
                  ),
                  const SizedBox(height: 20),

                  // Date & Time row
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Date of Birth *', style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: CosmicTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: CosmicTheme.borderGlow),
                          ),
                          child: Row(children: [
                            const Icon(Icons.calendar_today, size: 18, color: CosmicTheme.rahuSmoke),
                            const SizedBox(width: 10),
                            Text(
                              _selectedDate != null ? DateFormat('dd MMM yyyy').format(_selectedDate!) : 'Select date',
                              style: TextStyle(color: _selectedDate != null ? Colors.white : CosmicTheme.rahuSmoke),
                            ),
                          ]),
                        ),
                      ),
                    ])),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Time of Birth *', style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: CosmicTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: CosmicTheme.borderGlow),
                          ),
                          child: Row(children: [
                            const Icon(Icons.access_time, size: 18, color: CosmicTheme.rahuSmoke),
                            const SizedBox(width: 10),
                            Text(
                              _selectedTime != null ? _selectedTime!.format(context) : 'Select time',
                              style: TextStyle(color: _selectedTime != null ? Colors.white : CosmicTheme.rahuSmoke),
                            ),
                          ]),
                        ),
                      ),
                    ])),
                  ]),
                  const SizedBox(height: 20),

                  // Place of Birth
                  Text('Place of Birth *', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _placeCtrl,
                    decoration: const InputDecoration(hintText: 'Search or select city', prefixIcon: Icon(Icons.location_on_outlined, size: 20)),
                    onChanged: (v) => setState(() {}),
                  ),
                  if (_placeCtrl.text.isNotEmpty && _birthData.latitude == 0) ...[
                    const SizedBox(height: 4),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: CosmicTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: CosmicTheme.borderGlow),
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        children: _commonPlaces
                            .where((p) => p['name'].toString().toLowerCase().contains(_placeCtrl.text.toLowerCase()))
                            .map((p) => ListTile(
                              dense: true,
                              title: Text(p['name'], style: const TextStyle(color: Colors.white, fontSize: 13)),
                              onTap: () => _selectPlace(p),
                            ))
                            .toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Quick city picks
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _commonPlaces.take(6).map((p) => GestureDetector(
                      onTap: () => _selectPlace(p),
                      child: Chip(
                        label: Text(p['name'].toString().split(',')[0], style: const TextStyle(fontSize: 11)),
                        backgroundColor: _birthData.placeName == p['name']
                            ? CosmicTheme.starGold.withOpacity(0.2) : CosmicTheme.surfaceDark,
                        side: BorderSide(color: _birthData.placeName == p['name']
                            ? CosmicTheme.starGold : CosmicTheme.borderGlow),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Coordinates (advanced)
                  ExpansionTile(
                    title: Text('Advanced: Manual Coordinates', style: TextStyle(color: CosmicTheme.moonSilver.withOpacity(0.7), fontSize: 13)),
                    tilePadding: EdgeInsets.zero,
                    iconColor: CosmicTheme.rahuSmoke,
                    children: [
                      Row(children: [
                        Expanded(child: TextFormField(
                          controller: _latCtrl,
                          decoration: const InputDecoration(labelText: 'Latitude', hintText: '28.6139'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: TextFormField(
                          controller: _lonCtrl,
                          decoration: const InputDecoration(labelText: 'Longitude', hintText: '77.2090'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        )),
                      ]),
                      const SizedBox(height: 12),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Ayanamsa
                  Text('Ayanamsa System', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: [
                      {'value': 'lahiri', 'label': 'Lahiri (Chitrapaksha)'},
                      {'value': 'raman', 'label': 'Raman'},
                      {'value': 'krishnamurti', 'label': 'KP (Krishnamurti)'},
                    ].map((a) => ChoiceChip(
                      label: Text(a['label']!, style: TextStyle(
                        fontSize: 12,
                        color: _selectedAyanamsa == a['value'] ? CosmicTheme.deepSpace : CosmicTheme.moonSilver,
                      )),
                      selected: _selectedAyanamsa == a['value']!,
                      selectedColor: CosmicTheme.starGold,
                      onSelected: (sel) { if (sel) setState(() => _selectedAyanamsa = a['value']!); },
                    )).toList(),
                  ),
                  const SizedBox(height: 36),

                  // Generate button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: provider.isLoading ? null : _generate,
                      icon: provider.isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: CosmicTheme.deepSpace))
                          : const Icon(Icons.auto_awesome),
                      label: Text(provider.isLoading ? 'Computing Chart...' : 'Generate Kundali'),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
