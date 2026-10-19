import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class Depense {
  final String id;
  String motif;
  double montant;
  String categorie;
  DateTime date;

  Depense({
    required this.id,
    required this.motif,
    required this.montant,
    required this.categorie,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'motif': motif,
      'montant': montant,
      'categorie': categorie,
      'date': date.toIso8601String(),
    };
  }

  factory Depense.fromJson(Map<String, dynamic> json) {
    return Depense(
      id: json['id'] ?? '',
      motif: json['motif'] ?? '',
      montant: (json['montant'] ?? 0).toDouble(),
      categorie: json['categorie'] ?? 'Général',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
    );
  }
}

class ExpensesPage extends StatefulWidget {
  final List<Depense> depenses;
  final Function(Depense) onDepenseAjoutee;
  final Function(String) onDepenseSupprimee;

  const ExpensesPage({
    Key? key,
    required this.depenses,
    required this.onDepenseAjoutee,
    required this.onDepenseSupprimee,
  }) : super(key: key);

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  String _searchQuery = '';

  double get _totalDepenses {
    return widget.depenses.fold(0, (sum, item) => sum + item.montant);
  }

  Future<void> _imprimerDepenses(List<Depense> depensesFiltrees) async {
    final pdf = pw.Document();
    double totalFiltre = depensesFiltrees.fold(0, (sum, d) => sum + d.montant);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('ÉTAT DES DÉPENSES', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),
            pw.Text('Total des Dépenses : $totalFiltre FCFA', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.deepOrange)),
            pw.SizedBox(height: 15),
            pw.Table.fromTextArray(
              headers: ['Date', 'Motif / Description', 'Catégorie', 'Montant'],
              data: depensesFiltrees.map((d) => [
                '${d.date.day}/${d.date.month}/${d.date.year}',
                d.motif,
                d.categorie,
                '${d.montant} FCFA',
              ]).toList(),
            ),
          ],
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  void _afficherFormulaireAjout(BuildContext context) {
    final motifController = TextEditingController();
    final montantController = TextEditingController();
    String categorieSelectionnee = 'Transport';
    final categories = ['Transport', 'Loyer', 'Électricité/Eau', 'Nourriture', 'Salaire', 'Divers'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Enregistrer une Dépense'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: motifController, decoration: const InputDecoration(labelText: 'Motif / Description')),
                TextField(controller: montantController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Montant (FCFA)')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: categorieSelectionnee,
                  decoration: const InputDecoration(labelText: 'Catégorie'),
                  items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => categorieSelectionnee = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () {
                final double? montant = double.tryParse(montantController.text);
                if (motifController.text.isNotEmpty && montant != null && montant > 0) {
                  final nouvelle = Depense(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    motif: motifController.text,
                    montant: montant,
                    categorie: categorieSelectionnee,
                    date: DateTime.now(),
                  );
                  widget.onDepenseAjoutee(nouvelle);
                  setState(() {});
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
              child: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final depensesFiltrees = widget.depenses.where((d) {
      return d.motif.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          d.categorie.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Dépenses', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepOrange,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white),
            tooltip: 'Imprimer les dépenses',
            onPressed: () => _imprimerDepenses(depensesFiltrees),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.deepOrange.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.deepOrange.shade200),
              ),
              child: Column(
                children: [
                  const Text('Total des Dépenses', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 5),
                  Text('$_totalDepenses FCFA', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Rechercher une dépense ou catégorie...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: depensesFiltrees.isEmpty
                  ? const Center(child: Text('Aucune dépense trouvée', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: depensesFiltrees.length,
                      itemBuilder: (context, index) {
                        final depense = depensesFiltrees.reversed.toList()[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.deepOrange.shade100,
                              child: const Icon(Icons.receipt, color: Colors.deepOrange),
                            ),
                            title: Text(depense.motif, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Catégorie : ${depense.categorie} | ${depense.date.day}/${depense.date.month}/${depense.date.year}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('${depense.montant} FCFA', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.deepOrange)),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    widget.onDepenseSupprimee(depense.id);
                                    setState(() {});
                                  },
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
        onPressed: () => _afficherFormulaireAjout(context),
        backgroundColor: Colors.deepOrange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nouvelle Dépense', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}