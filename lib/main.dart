import 'package:flutter/material.dart';
import 'package:multinova/presentation/home_screen.dart';
import 'package:multinova/presentation/bluetooth_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:multinova/presentation/plants_list_screen.dart';
import 'package:multinova/presentation/plant_detail_screen.dart';
import 'package:multinova/presentation/my_garden_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => BluetoothProvider())],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Multinova',
      theme: ThemeData(primarySwatch: Colors.green),
      //home: PlantsListScreen(),
      home: HomeScreen(),
      //home:MyGardenScreen(), // Cambia esto para mostrar la pantalla de mi jardín
      //home: AddPlantScreen(), // Cambia esto para mostrar la pantalla de agregar planta
    );
  }
}
