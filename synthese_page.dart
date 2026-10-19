import 'package:flutter/material.dart';
import 'sales_page.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class SynthesePage extends StatefulWidget {
  final List<Vente> historiqueVentes;
  final VoidCallback onVenteSupprimee;

  const SynthesePage({
    Key? key,
    required this.historiqueVentes,
    required this.onVenteSupprimee,
  }) : super(key: key);

  @override
  State<SynthesePage> createState() => _SynthesePageState();
}

class _SynthesePageState extends State<SynthesePage> {
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

  List<Vente> get _ventesFiltrees {
    return widget.historiqueVentes.where((v) {
      if (_dateDebut != null && _dateFin != null) {
        final debut = DateTime(_dateDebut!.year, _dateDebut!.month, _dateDebut!.day);
        final fin = DateTime(_dateFin!.year, _dateFin!.month, _dateFin!.day, 23, 59, 59);
        return v.date.isAfter(debut.subtract(const Duration(seconds: 1))) &&
            v.date.isBefore(fin.add(const Duration(seconds: 1)));
      }
      return true;
    }).toList();
  }

  Future<void> _imprimerSyntheseVentes(double totalCA) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('SYNTHÈSE DES VENTES', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),
            pw.Text('Chiffre d\'Affaires Période : $totalCA FCFA', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.brown)),
            pw.SizedBox(height: 15),
            pw.Text('Détail des ventes :', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            ..._ventesFiltrees.expand((vente) {
              return vente.articles.map((item) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2.0),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('${item.nomProduit} (${vente.date.day}/${vente.date.month}/${vente.date.year} - Qté: ${item.quantite})'),
                      pw.Text('${item.total} FCFA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                );
              });
            }),
          ],
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    double totalCA = _ventesFiltrees.fold(0, (sum, v) => sum + v.total);

    String periodeTexte = (_dateDebut != null && _dateFin != null)
        ? 'Du ${_dateDebut!.day}/${_dateDebut!.month}/${_dateDebut!.year} au ${_dateFin!.day}/${_dateFin!.month}/${_dateFin!.year}'
        : 'Toutes les périodes';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Synthèse des Ventes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.brown,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white),
            tooltip: 'Imprimer la synthèse des ventes',
            onPressed: () => _imprimerSyntheseVentes(totalCA),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barre de sélection manuelle de date
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.brown.shade50, borderRadius: BorderRadius.circular(10)),
              child: Column(
                children: [
                  const Text('Chiffre d\'Affaires Période', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 5),
                  Text('$totalCA FCFA', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.brown)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Historique détaillé des ventes :', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: _ventesFiltrees.isEmpty
                  ? const Center(child: Text('Aucune vente enregistrée pour cette période.', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: _ventesFiltrees.length,
                      itemBuilder: (context, index) {
                        final vente = _ventesFiltrees.reversed.toList()[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ExpansionTile(
                            title: Text('Vente du ${vente.date.day}/${vente.date.month}/${vente.date.year} à ${vente.date.hour}:${vente.date.minute.toString().padLeft(2, '0')} - Client : ${vente.nomClient}'),
                            subtitle: Text('Total : ${vente.total} FCFA'),
                            children: vente.articles.map((item) {
                              return ListTile(
                                dense: true,
                                title: Text(item.nomProduit, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Date : ${vente.date.day}/${vente.date.month}/${vente.date.year} | Qté : ${item.quantite} | Prix unitaire : ${item.prixVente} FCFA'),
                                trailing: Text('Prix total : ${item.total} FCFA', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                              );
                            }).toList(),
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