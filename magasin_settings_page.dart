import 'package:flutter/material.dart';
import 'magasin_model.dart';

class MagasinSettingsPage extends StatefulWidget {
  final Magasin magasin;
  final VoidCallback onMagasinModifie;

  const MagasinSettingsPage({
    Key? key,
    required this.magasin,
    required this.onMagasinModifie,
  }) : super(key: key);

  @override
  State<MagasinSettingsPage> createState() => _MagasinSettingsPageState();
}

class _MagasinSettingsPageState extends State<MagasinSettingsPage> {
  late TextEditingController _nomMagasinController;
  late TextEditingController _idMagasinController;
  late TextEditingController _contactController;
  late TextEditingController _adresseController;
  late TextEditingController _gerantController;

  @override
  void initState() {
    super.initState();
    _nomMagasinController = TextEditingController(text: widget.magasin.nomMagasin);
    _idMagasinController = TextEditingController(text: widget.magasin.id);
    _contactController = TextEditingController(text: widget.magasin.contact);
    _adresseController = TextEditingController(text: widget.magasin.adresse);
    _gerantController = TextEditingController(text: widget.magasin.nomGerant);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres du Magasin & Facture', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueGrey,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'Informations affichées sur les factures imprimées',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
            const Divider(),
            const SizedBox(height: 10),
            TextField(controller: _nomMagasinController, decoration: const InputDecoration(labelText: 'Nom du Magasin', border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: _idMagasinController, decoration: const InputDecoration(labelText: 'Numéro du Magasin (ID)', border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: _contactController, decoration: const InputDecoration(labelText: 'Contact / Téléphone sur facture', border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: _adresseController, decoration: const InputDecoration(labelText: 'Adresse du Magasin', border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: _gerantController, decoration: const InputDecoration(labelText: 'Nom du Gérant / Vendeur par défaut', border: OutlineInputBorder())),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
              icon: const Icon(Icons.save),
              label: const Text('Enregistrer les modifications', style: TextStyle(fontSize: 16)),
              onPressed: () {
                widget.magasin.nomMagasin = _nomMagasinController.text;
                widget.magasin.id = _idMagasinController.text;
                widget.magasin.contact = _contactController.text;
                widget.magasin.adresse = _adresseController.text;
                widget.magasin.nomGerant = _gerantController.text;
                widget.onMagasinModifie();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paramètres mis à jour avec succès !')));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}