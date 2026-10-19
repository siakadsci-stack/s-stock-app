import 'package:flutter/material.dart';
import 'caisse_tresorerie_model.dart';
import 'auth_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CaisseTresoreriePage extends StatefulWidget {
  final List<MouvementCaisse> mouvements;
  final Function(MouvementCaisse) onMouvementAjoute;
  final Utilisateur utilisateurActif;

  const CaisseTresoreriePage({
    Key? key,
    required this.mouvements,
    required this.onMouvementAjoute,
    required this.utilisateurActif,
  }) : super(key: key);

  @override
  State<CaisseTresoreriePage> createState() => _CaisseTresoreriePageState();
}

class _CaisseTresoreriePageState extends State<CaisseTresoreriePage> {
  DateTime? _dateDebut;
  DateTime? _dateFin;

  Future<void> _selectionnerIntervalleDate(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      initialDateRange: _dateDebut != null && _dateFin != null
          ? DateTimeRange(start: _dateDebut!, end: _dateFin!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _dateDebut = picked.start;
        _dateFin = picked.end;
      });
    }
  }

  List<MouvementCaisse> get _mouvementsFiltres {
    return widget.mouvements.where((m) {
      if (_dateDebut != null && _dateFin != null) {
        final debut = DateTime(_dateDebut!.year, _dateDebut!.month, _dateDebut!.day);
        final fin = DateTime(_dateFin!.year, _dateFin!.month, _dateFin!.day, 23, 59, 59);
        return m.date.isAfter(debut.subtract(const Duration(seconds: 1))) &&
            m.date.isBefore(fin.add(const Duration(seconds: 1)));
      }
      return true;
    }).toList();
  }

  double get totalVersements => _mouvementsFiltres.where((m) => m.type == 'Versement').fold(0, (sum, m) => sum + m.montant);
  double get totalRetraits => _mouvementsFiltres.where((m) => m.type == 'Retrait').fold(0, (sum, m) => sum + m.montant);
  double get soldeCaisse => totalVersements - totalRetraits;

  Future<void> _imprimerRapportCaisse() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('RAPPORT DE CAISSE ET TRÉSORERIE', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text('Total Entrées (Versements) : $totalVersements FCFA'),
            pw.Text('Total Sorties (Retraits) : $totalRetraits FCFA'),
            pw.Text('Solde de Caisse : $soldeCaisse FCFA'),
            pw.SizedBox(height: 15),
            pw.Table.fromTextArray(
              headers: ['Date', 'Type', 'Montant', 'Motif', 'Auteur'],
              data: _mouvementsFiltres.map((m) => [
                '${m.date.day}/${m.date.month}/${m.date.year}',
                m.type,
                '${m.montant} FCFA',
                m.motif,
                m.auteur,
              ]).toList(),
            ),
          ],
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  void _afficherModalMouvement(BuildContext context, String type) {
    final motifController = TextEditingController();
    final montantController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(type == 'Versement' ? '💰 Nouveau Versement' : '💸 Nouveau Retrait'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: montantController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Montant (FCFA)', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: motifController, decoration: const InputDecoration(labelText: 'Motif / Description', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              final double? montant = double.tryParse(montantController.text);
              if (montant != null && montant > 0 && motifController.text.isNotEmpty) {
                widget.onMouvementAjoute(MouvementCaisse(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  date: DateTime.now(),
                  type: type,
                  montant: montant,
                  motif: motifController.text,
                  auteur: widget.utilisateurActif.nom,
                ));
                setState(() {});
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: type == 'Versement' ? Colors.green : Colors.deepOrange),
            child: const Text('Valider', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String periodeTexte = (_dateDebut != null && _dateFin != null)
        ? 'Du ${_dateDebut!.day}/${_dateDebut!.month}/${_dateDebut!.year} au ${_dateFin!.day}/${_dateFin!.month}/${_dateFin!.year}'
        : 'Tous les mouvements';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion de Caisse & Trésorerie', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueGrey,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white),
            tooltip: 'Imprimer le rapport de caisse',
            onPressed: _imprimerRapportCaisse,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Sélection manuelle de dates
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text('Période : $periodeTexte', style: const TextStyle(fontWeight: FontWeight.bold))),
                ElevatedButton.icon(
                  onPressed: () => _selectionnerIntervalleDate(context),
                  icon: const Icon(Icons.date_range, size: 16),
                  label: const Text('Sélectionner dates'),
                ),
                if (_dateDebut != null)
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.red),
                    onPressed: () => setState(() { _dateDebut = null; _dateFin = null; }),
                    tooltip: 'Réinitialiser filtre',
                  ),
              ],
            ),
            const SizedBox(height: 15),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.blueGrey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blueGrey.shade200)),
              child: Column(
                children: [
                  const Text('Solde Actuel en Caisse', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 5),
                  Text('$soldeCaisse FCFA', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Entrées : $totalVersements FCFA', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 20),
                      Text('Sorties : $totalRetraits FCFA', style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _afficherModalMouvement(context, 'Versement'),
                    icon: const Icon(Icons.add_circle, color: Colors.white),
                    label: const Text('Faire un Versement', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _afficherModalMouvement(context, 'Retrait'),
                    icon: const Icon(Icons.remove_circle, color: Colors.white),
                    label: const Text('Faire un Retrait', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, padding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Historique des Mouvements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _mouvementsFiltres.isEmpty
                  ? const Center(child: Text('Aucun mouvement enregistré.', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: _mouvementsFiltres.length,
                      itemBuilder: (context, index) {
                        final m = _mouvementsFiltres.reversed.toList()[index];
                        bool estVersement = m.type == 'Versement';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: estVersement ? Colors.green.shade100 : Colors.deepOrange.shade100,
                              child: Icon(estVersement ? Icons.arrow_downward : Icons.arrow_upward, color: estVersement ? Colors.green : Colors.deepOrange),
                            ),
                            title: Text('${m.type} : ${m.montant} FCFA', style: TextStyle(fontWeight: FontWeight.bold, color: estVersement ? Colors.green : Colors.deepOrange)),
                            subtitle: Text('Motif : ${m.motif} | Par : ${m.auteur} (${m.date.day}/${m.date.month}/${m.date.year})'),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}