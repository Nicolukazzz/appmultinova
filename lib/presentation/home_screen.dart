import 'package:flutter/material.dart';
import 'my_plant_screen.dart';
import 'calendar_screen.dart';
import 'settings_screen.dart';
import 'plants_list_screen.dart'; // Asegúrate de importar tu nueva pantalla aquí

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    MyPlantScreen(),
    PlantsListScreen(), // <-- Este es el nuevo botón "Agregar"
    CalendarScreen(),
    SettingsScreen(),
  ];

  final List<IconData> _icons = [
    Icons.eco_outlined,
    Icons.add_circle_outline, // Icono para Agregar
    Icons.calendar_today_outlined,
    Icons.settings_outlined,
  ];

  final List<String> _labels = [
    'Mi Planta',
    'Agregar',
    'Calendario',
    'Ajustes',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: _screens[_currentIndex],
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_icons.length, (index) {
              final isSelected = index == _currentIndex;

              return GestureDetector(
                onTap: () => setState(() => _currentIndex = index),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 250),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? Color(0xFF4C9A2A).withOpacity(0.1)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _icons[index],
                        color:
                            isSelected ? Color(0xFF4C9A2A) : Colors.grey[500],
                        size: 26,
                      ),
                      SizedBox(height: 4),
                      Text(
                        _labels[index],
                        style: TextStyle(
                          color:
                              isSelected ? Color(0xFF4C9A2A) : Colors.grey[500],
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
