import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, String>>> _plantEvents = {};

  final List<String> _plantas = ['Planta A', 'Planta B', 'Planta C'];
  final List<Map<String, dynamic>> _acciones = [
    {'label': 'Riego', 'icon': Icons.water_drop},
    {'label': 'Cambio de agua', 'icon': Icons.swap_horiz},
    {'label': 'Medición de pH', 'icon': Icons.science},
    {'label': 'Cambio de lugar', 'icon': Icons.move_to_inbox},
  ];

  Set<String> _selectedAcciones = {};

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedEvents = _plantEvents.map((key, value) {
      final dateKey = key.toIso8601String();
      return MapEntry(dateKey, value);
    });
    prefs.setString('plant_events', jsonEncode(encodedEvents));
  }

  Future<void> _loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedEvents = prefs.getString('plant_events');
    if (encodedEvents != null) {
      final decoded = Map<String, dynamic>.from(jsonDecode(encodedEvents));
      final loadedEvents = <DateTime, List<Map<String, String>>>{};

      decoded.forEach((key, value) {
        final date = DateTime.parse(key);
        final list = List<Map<String, dynamic>>.from(value);
        loadedEvents[date] =
            list.map((e) => Map<String, String>.from(e)).toList();
      });

      setState(() {
        _plantEvents = loadedEvents;
      });
    }
  }

  void _showAddActionSheet() {
    String? selectedPlant;
    _selectedAcciones = {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Registrar acción',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Selecciona una planta",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items:
                        _plantas.map((plant) {
                          return DropdownMenuItem(
                            value: plant,
                            child: Text(plant),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setModalState(() {
                        selectedPlant = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children:
                        _acciones.map((accion) {
                          final isSelected = _selectedAcciones.contains(
                            accion['label'],
                          );
                          return ChoiceChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(accion['icon'], size: 18),
                                const SizedBox(width: 6),
                                Text(accion['label']),
                              ],
                            ),
                            selected: isSelected,
                            selectedColor: Colors.green[100],
                            onSelected: (_) {
                              setModalState(() {
                                if (isSelected) {
                                  _selectedAcciones.remove(accion['label']);
                                } else {
                                  _selectedAcciones.add(accion['label']);
                                }
                              });
                            },
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (selectedPlant != null &&
                          _selectedAcciones.isNotEmpty) {
                        final date = DateTime(
                          (_selectedDay ?? _focusedDay).year,
                          (_selectedDay ?? _focusedDay).month,
                          (_selectedDay ?? _focusedDay).day,
                        );
                        setState(() {
                          _plantEvents.putIfAbsent(date, () => []);
                          for (var accion in _selectedAcciones) {
                            _plantEvents[date]!.add({
                              'planta': selectedPlant!,
                              'accion': accion,
                            });
                          }
                          _saveEvents();
                        });
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.save),
                    label: const Text("Guardar acción"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<Map<String, String>> _getEventsForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _plantEvents[date] ?? [];
  }

  void _showDeleteConfirmation(int index, DateTime date) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.redAccent,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  "¿Eliminar acción?",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Estás a punto de eliminar esta acción. ¿Estás seguro?",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancelar"),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _plantEvents[date]?.removeAt(index);
                          if (_plantEvents[date]?.isEmpty ?? false) {
                            _plantEvents.remove(date);
                          }
                          _saveEvents();
                        });
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text("Eliminar"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = DateTime(
      (_selectedDay ?? _focusedDay).year,
      (_selectedDay ?? _focusedDay).month,
      (_selectedDay ?? _focusedDay).day,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: const Text(
          "Calendario",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.green[600],
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2050, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
              },
              eventLoader: (day) => _getEventsForDay(day),
              calendarStyle: const CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Color(0xFF4C9A2A),
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Color(0xFFB6E2A1),
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  _getEventsForDay(selectedDate).isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.event_busy,
                              color: Colors.grey,
                              size: 50,
                            ),
                            SizedBox(height: 12),
                            Text(
                              "No hay acciones registradas.",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        itemCount: _getEventsForDay(selectedDate).length,
                        itemBuilder: (context, index) {
                          final evento = _getEventsForDay(selectedDate)[index];
                          return GestureDetector(
                            onLongPress:
                                () => _showDeleteConfirmation(
                                  index,
                                  selectedDate,
                                ),
                            child: Card(
                              elevation: 3,
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: Icon(
                                  Icons.eco_rounded,
                                  color: Colors.green[600],
                                ),
                                title: Text(evento['accion'] ?? ''),
                                subtitle: Text("Planta: ${evento['planta']}"),
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        onPressed: _showAddActionSheet,
        child: const Icon(Icons.add),
      ),
    );
  }
}
