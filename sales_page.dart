import 'package:flutter/material.dart';
import 'stock_page.dart';
import 'clients_page.dart';
import 'magasin_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ArticleVendu {
  String produitId;
  String nomProduit;
  double prixVente;
  int quantite;

  ArticleVendu({
    required this.produitId,
    required this.nomProduit,
    required this.prixVente,
    required this.quantite,
  });

  double get total => prixVente * quantite;

  Map<String, dynamic> toJson() {
    return {
      'produitId': produitId,
      'nomProduit': nomProduit,
      'prixVente': prixVente,
      'quantite': quantite,
    };
  }

  factory ArticleVendu.fromJson(Map<String, dynamic> json) {
    return ArticleVendu(
      produitId: json['produitId'] ?? '',
      nomProduit: json['nomProduit'] ?? '',
      prixVente: (json['prixVente'] ?? 0).toDouble(),
      quantite: json['quantite'] ?? 0,
    );
  }
}

class Vente {
  String id;
  DateTime date;
  List<ArticleVendu> articles;
  double total;
  String nomClient;
  String modePaiement;

  Vente({
    required this.id,
    required this.date,
    required this.articles,
    required this.total,
    required this.nomClient,
    required this.modePaiement,
  });

  String? get clientNom => nomClient;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'articles': articles.map((a) => a.toJson()).toList(),
      'total': total,
      'nomClient': nomClient,
      'modePaiement': modePaiement,
    };
  }

  factory Vente.fromJson(Map<String, dynamic> json) {
    return Vente(
      id: json['id'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      articles: (json['articles'] as List? ?? []).map((a) => ArticleVendu.fromJson(a)).toList(),
      total: (json['total'] ?? 0).toDouble(),
      nomClient: json['nomClient'] ?? json['clientNom'] ?? 'Client Divers',
      modePaiement: json['modePaiement'] ?? 'Espèces',
    );
  }
}

class SalesPage extends StatefulWidget {
  final List<Produit> produits;
  final List<Client> clients;
  final List<Vente> historiqueVentes;
  final Magasin magasin;
  final Function(Vente) onNouvelleVente;
  final Function(String) onSupprimerVente;
  final Function(Client) onNouveauClientAuto;

  const SalesPage({
    Key? key,
    required this.produits,
    required this.clients,
    required this.historiqueVentes,
    required this.magasin,
    required this.onNouvelleVente,
    required this.onSupprimerVente,
    required this.onNouveauClientAuto,
  }) : super(key: key);

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  final List<ArticleVendu> _panier = [];
  String _rechercheArticle = '';
  
  // Contrôleur pour la suggestion de clients (Autocomplete)
  final TextEditingController _clientController = TextEditingController();
  Client? _clientSelectionne;

  DateTime? _dateDebutHistorique;
  DateTime? _dateFinHistorique;

  Future<void> _selectionnerIntervalleDateHistorique(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      initialDateRange: _dateDebutHistorique != null && _dateFinHistorique != null
          ? DateTimeRange(start: _dateDebutHistorique!, end: _dateFinHistorique!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _dateDebutHistorique = picked.start;
        _dateFinHistorique = picked.end;
      });
    }
  }

  List<Vente> get _historiqueVentesFiltre {
    return widget.historiqueVentes.where((v) {
      if (_dateDebutHistorique != null && _dateFinHistorique != null) {
        final debut = DateTime(_dateDebutHistorique!.year, _dateDebutHistorique!.month, _dateDebutHistorique!.day);
        final fin = DateTime(_dateFinHistorique!.year, _dateFinHistorique!.month, _dateFinHistorique!.day, 23, 59, 59);
        return v.date.isAfter(debut.subtract(const Duration(seconds: 1))) &&
            v.date.isBefore(fin.add(const Duration(seconds: 1)));
      }
      return true;
    }).toList();
  }

  Future<void> _imprimerFacture(Vente vente) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 160,
                    height: 75,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.black),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text(widget.magasin.nomMagasin, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 2),
                        pw.Text('Magasin N° : ${widget.magasin.id}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                        pw.Text('Tél : ${widget.magasin.contact}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                        pw.Spacer(),
                        pw.Text('[ Logo / Enseigne ]', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500)),
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('N° FACTURE : ${vente.id.substring(vente.id.length > 5 ? vente.id.length - 5 : 0)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                      pw.Text('DATE : ${vente.date.day}/${vente.date.month}/${vente.date.year}', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('HEURE : ${vente.date.hour}:${vente.date.minute.toString().padLeft(2, '0')}', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('SAISIE : ${widget.magasin.nomGerant}', style: const pw.TextStyle(fontSize: 9)),
                      pw.SizedBox(height: 6),
                      pw.Text('NOM DU CLIENT : ${vente.nomClient}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      pw.Text('ADRESSE : ${widget.magasin.adresse}', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 15),
              pw.Center(child: pw.Text('LISTE DES ARTICLES', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline))),
              pw.SizedBox(height: 8),
              pw.Table.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
                headerAlignment: pw.Alignment.centerLeft,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headers: ['DESIGNATION', 'QTE', 'P. UNIT', 'P. TOTAL'],
                data: vente.articles.map((article) {
                  return [
                    article.nomProduit,
                    article.quantite.toString(),
                    '${article.prixVente.toStringAsFixed(0)}',
                    '${article.total.toStringAsFixed(0)}',
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 15),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 100,
                    height: 60,
                    decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, style: pw.BorderStyle.dashed)),
                    alignment: pw.Alignment.center,
                    child: pw.Text('CACHET MAGASIN', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 1.2), borderRadius: pw.BorderRadius.circular(4)),
                    child: pw.Row(
                      children: [
                        pw.Text('MONTANT NET : ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                        pw.Text('${vente.total.toStringAsFixed(0)} FCFA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColors.blue800)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  void _ajouterArticlePersonnalise(Produit p) {
    final prixController = TextEditingController(text: p.prixVente.toString());
    final qteController = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ajouter : ${p.nom} (Stock dispo: ${p.quantite})'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: prixController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Prix de vente (modifiable)')),
            TextField(controller: qteController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantité')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              double prix = double.tryParse(prixController.text) ?? p.prixVente;
              int qte = int.tryParse(qteController.text) ?? 1;
              if (qte > 0) {
                if (qte > p.quantite) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Attention : Quantité supérieure au stock disponible !'), backgroundColor: Colors.orange),
                  );
                }
                setState(() {
                  _panier.add(ArticleVendu(produitId: p.id, nomProduit: p.nom, prixVente: prix, quantite: qte));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Ajouter au Panier'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalPanier = _panier.fold(0, (sum, item) => sum + item.total);
    final produitsFiltres = widget.produits.where((p) => p.nom.toLowerCase().contains(_rechercheArticle.toLowerCase())).toList();

    String periodeTexteHistorique = (_dateDebutHistorique != null && _dateFinHistorique != null)
        ? 'Du ${_dateDebutHistorique!.day}/${_dateDebutHistorique!.month}/${_dateDebutHistorique!.year} au ${_dateFinHistorique!.day}/${_dateFinHistorique!.month}/${_dateFinHistorique!.year}'
        : 'Toutes les dates';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Caisse & Historique Ventes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.blue,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Nouvelle Vente (Caisse)', icon: Icon(Icons.point_of_sale)),
              Tab(text: 'Historique des Ventes', icon: Icon(Icons.history)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          onChanged: (val) => setState(() => _rechercheArticle = val),
                          decoration: const InputDecoration(
                            labelText: 'Rechercher un article...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: produitsFiltres.length,
                          itemBuilder: (context, index) {
                            final p = produitsFiltres[index];
                            bool enAlerte = p.quantite <= p.alerteQuantite;
                            return Card(
                              color: enAlerte ? Colors.red.shade50 : Colors.white,
                              child: ListTile(
                                title: Text(p.nom),
                                subtitle: Text('Prix : ${p.prixVente} FCFA | Stock : ${p.quantite}'),
                                trailing: ElevatedButton(
                                  child: const Text('Sélectionner'),
                                  onPressed: () => _ajouterArticlePersonnalise(p),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.grey.shade100,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Client (Suggestions automatiques)', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        // Widget Autocomplete pour suggérer les clients dès la première lettre
                        Autocomplete<Client>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return const Iterable<Client>.empty();
                            }
                            return widget.clients.where((Client client) {
                              return client.nom.toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                                  client.telephone.contains(textEditingValue.text);
                            });
                          },
                          displayStringForOption: (Client option) => option.nom,
                          onSelected: (Client selection) {
                            setState(() {
                              _clientSelectionne = selection;
                            });
                          },
                          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                hintText: 'Entrez le nom ou téléphone...',
                                prefixIcon: const Icon(Icons.search, size: 18),
                                isDense: true,
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                                suffixIcon: _clientSelectionne != null
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () {
                                          setState(() {
                                            _clientSelectionne = null;
                                            controller.clear();
                                          });
                                        },
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                        if (_clientSelectionne != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text('Sélectionné : ${_clientSelectionne!.nom}', style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                          ),
                        const Divider(),
                        const Text('Panier Actuel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _panier.length,
                            itemBuilder: (context, index) {
                              final item = _panier[index];
                              return ListTile(
                                title: Text(item.nomProduit),
                                subtitle: Text('${item.quantite} x ${item.prixVente} FCFA'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => setState(() => _panier.removeAt(index)),
                                ),
                              );
                            },
                          ),
                        ),
                        const Divider(),
                        Text('Total : ${totalPanier.toStringAsFixed(0)} FCFA', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                            onPressed: _panier.isEmpty ? null : () {
                              // DÉDUCTION AUTOMATIQUE DU STOCK INITIAL
                              for (var item in _panier) {
                                final produitAssocie = widget.produits.firstWhere(
                                  (p) => p.id == item.produitId,
                                  orElse: () => Produit(id: '', nom: '', categorie: '', prixAchat: 0, prixVente: 0, quantite: 0, alerteQuantite: 0),
                                );
                                if (produitAssocie.id.isNotEmpty) {
                                  produitAssocie.quantite -= item.quantite;
                                  if (produitAssocie.quantite < 0) produitAssocie.quantite = 0;
                                }
                              }

                              final nouvelleVente = Vente(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                date: DateTime.now(),
                                articles: List.from(_panier),
                                total: totalPanier,
                                nomClient: _clientSelectionne?.nom ?? 'Client Divers',
                                modePaiement: 'Espèces',
                              );
                              widget.onNouvelleVente(nouvelleVente);
                              setState(() {
                                _panier.clear();
                                _clientSelectionne = null;
                              });

                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Vente validée !'),
                                  content: const Text('Le stock a été mis à jour. Souhaitez-vous imprimer la facture ?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _imprimerFacture(nouvelleVente);
                                      },
                                      child: const Text('Imprimer'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: const Text('Valider la Vente'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            // HISTORIQUE
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text('Période : $periodeTexteHistorique', style: const TextStyle(fontWeight: FontWeight.bold))),
                      ElevatedButton.icon(
                        onPressed: () => _selectionnerIntervalleDateHistorique(context),
                        icon: const Icon(Icons.date_range, size: 16),
                        label: const Text('Sélectionner dates'),
                      ),
                      if (_dateDebutHistorique != null)
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.red),
                          onPressed: () => setState(() { _dateDebutHistorique = null; _dateFinHistorique = null; }),
                          tooltip: 'Réinitialiser filtre',
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _historiqueVentesFiltre.isEmpty
                        ? const Center(child: Text('Aucune vente enregistrée pour cette période.', style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            itemCount: _historiqueVentesFiltre.length,
                            itemBuilder: (context, index) {
                              final v = _historiqueVentesFiltre.reversed.toList()[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ExpansionTile(
                                  title: Text('Facture #${v.id.substring(v.id.length > 5 ? v.id.length - 5 : 0)} - Client : ${v.nomClient}'),
                                  subtitle: Text('Date : ${v.date.day}/${v.date.month}/${v.date.year} | Total : ${v.total} FCFA'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.print, color: Colors.blue),
                                        tooltip: 'Imprimer la facture',
                                        onPressed: () => _imprimerFacture(v),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        tooltip: 'Supprimer la vente',
                                        onPressed: () {
                                          widget.onSupprimerVente(v.id);
                                          setState(() {});
                                        },
                                      ),
                                    ],
                                  ),
                                  children: v.articles.map((art) => ListTile(
                                    title: Text(art.nomProduit),
                                    subtitle: Text('Quantité : ${art.quantite} x ${art.prixVente} FCFA'),
                                    trailing: Text('Total : ${art.total} FCFA', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  )).toList(),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
