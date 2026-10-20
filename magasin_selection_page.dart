import 'package:flutter/material.dart';
import 'magasin_model.dart';
import 'auth_model.dart';

class MagasinSelectionPage extends StatefulWidget {
  final List<Magasin> magasins;
  final List<Utilisateur> administrateursApp;
  final Function(Magasin) onMagasinSelectionne;
  final Function(Magasin) onMagasinAjoute;

  const MagasinSelectionPage({
    Key? key,
    required this.magasins,
    required this.administrateursApp,
    required this.onMagasinSelectionne,
    required this.onMagasinAjoute,
  }) : super(key: key);

  @override
  State<MagasinSelectionPage> createState() => _MagasinSelectionPageState();
}

class _MagasinSelectionPageState extends State<MagasinSelectionPage> {
  // Modal pour ajouter un nouveau magasin
  void _afficherModalAjoutMagasin(BuildContext context) {
    final nomMagasinController = TextEditingController();
    final idMagasinController = TextEditingController();
    final nomGerantController = TextEditingController();
    final codePinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Créer un Nouveau Magasin'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nomMagasinController, decoration: const InputDecoration(labelText: 'Nom du Magasin')),
              TextField(controller: idMagasinController, decoration: const InputDecoration(labelText: 'ID / Numéro du Magasin')),
              TextField(controller: nomGerantController, decoration: const InputDecoration(labelText: 'Nom du Gérant')),
              TextField(controller: codePinController, keyboardType: TextInputType.number, obscureText: true, decoration: const InputDecoration(labelText: 'Code PIN Connexion')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (nomMagasinController.text.isNotEmpty && nomGerantController.text.isNotEmpty) {
                final nouveauMagasin = Magasin(
                  id: idMagasinController.text.isNotEmpty ? idMagasinController.text : DateTime.now().millisecondsSinceEpoch.toString(),
                  nomMagasin: nomMagasinController.text,
                  nomGerant: nomGerantController.text,
                  codePin: codePinController.text,
                  produits: [],
                  clients: [],
                  historiqueVentes: [],
                  depenses: [],
                  mouvementsCaisse: [],
                  utilisateurs: [
                    Utilisateur(id: '1', nom: nomGerantController.text, codePin: codePinController.text, estAdmin: false),
                  ],
                );
                widget.onMagasinAjoute(nouveauMagasin);
                Navigator.pop(context);
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  // Modal pour modifier un magasin ou un gérant (Réservé Admin avec PIN 2506)
  void _verifierAdminPourAction(BuildContext context, Magasin magasin, String actionType) {
    final pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sécurité Admin : $actionType'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Veuillez entrer le Code PIN Administrateur (2506) :'),
            const SizedBox(height: 10),
            TextField(controller: pinController, obscureText: true, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'PIN Admin', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              if (pinController.text == '2506') {
                Navigator.pop(context);
                if (actionType == 'Modifier') {
                  _afficherModalModificationMagasin(context, magasin);
                } else if (actionType == 'Supprimer') {
                  _confirmerSuppressionMagasin(context, magasin);
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code PIN Administrateur incorrect !'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  void _afficherModalModificationMagasin(BuildContext context, Magasin magasin) {
    final nomMagasinController = TextEditingController(text: magasin.nomMagasin);
    final nomGerantController = TextEditingController(text: magasin.nomGerant);
    final codePinController = TextEditingController(text: magasin.codePin);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier : ${magasin.nomMagasin}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nomMagasinController, decoration: const InputDecoration(labelText: 'Nom du Magasin')),
              TextField(controller: nomGerantController, decoration: const InputDecoration(labelText: 'Nom du Gérant')),
              TextField(controller: codePinController, decoration: const InputDecoration(labelText: 'Code PIN')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                magasin.nomMagasin = nomMagasinController.text;
                magasin.nomGerant = nomGerantController.text;
                magasin.codePin = codePinController.text;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Modifications enregistrées !')));
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _confirmerSuppressionMagasin(BuildContext context, Magasin magasin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce Magasin ?'),
        content: Text('Voulez-vous vraiment supprimer définitivement ${magasin.nomMagasin} et toutes ses données ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              setState(() {
                widget.magasins.remove(magasin);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Magasin supprimé avec succès.')));
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sélectionnez votre Magasin - S-Stock', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Liste des Magasins Disponibles', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Expanded(
              child: widget.magasins.isEmpty
                  ? const Center(child: Text('Aucun magasin enregistré.', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: widget.magasins.length,
                      itemBuilder: (context, index) {
                        final mag = widget.magasins[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.store, color: Colors.white)),
                            title: Text(mag.nomMagasin, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            subtitle: Text('Gérant : ${mag.nomGerant.isNotEmpty ? mag.nomGerant : "Non assigné"} | ID : ${mag.id}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  tooltip: 'Modifier Magasin/Gérant (Admin)',
                                  onPressed: () => _verifierAdminPourAction(context, mag, 'Modifier'),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  tooltip: 'Supprimer Magasin (Admin)',
                                  onPressed: () => _verifierAdminPourAction(context, mag, 'Supprimer'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                  onPressed: () => widget.onMagasinSelectionne(mag),
                                  child: const Text('Ouvrir'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _afficherModalAjoutMagasin(context),
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nouveau Magasin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
