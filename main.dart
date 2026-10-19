import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'stock_page.dart';
import 'sales_page.dart';
import 'clients_page.dart';
import 'expenses_page.dart';
import 'reports_page.dart';
import 'auth_model.dart';
import 'synthese_page.dart';
import 'caisse_tresorerie_model.dart';
import 'caisse_tresorerie_page.dart';
import 'magasin_model.dart';
import 'magasin_selection_page.dart';
import 'magasin_settings_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SStockApp());
}

class SStockApp extends StatefulWidget {
  const SStockApp({Key? key}) : super(key: key);

  @override
  State<SStockApp> createState() => SStockAppState();
}

class SStockAppState extends State<SStockApp> {
  Magasin? _magasinActif;
  bool _chargementEnCours = true;

  final List<Utilisateur> _administrateursApp = [
    Utilisateur(id: '1', nom: 'Propriétaire Principal', codePin: '2506', estAdmin: true),
  ];

  List<Magasin> _magasins = [
    Magasin(
      id: '1',
      nomMagasin: 'Magasin Principal',
      nomGerant: 'Gérant',
      codePin: '1234',
      produits: [
        Produit(id: '1', nom: 'Riz Oncle Sam 5kg', categorie: 'Alimentation', prixAchat: 3500, prixVente: 4500, quantite: 12, alerteQuantite: 5),
        Produit(id: '2', nom: 'Huile Dinor 1L', categorie: 'Alimentation', prixAchat: 1100, prixVente: 1300, quantite: 2, alerteQuantite: 5),
      ],
      clients: [],
      historiqueVentes: [],
      depenses: [],
      mouvementsCaisse: [],
      utilisateurs: [
        Utilisateur(id: '1', nom: 'Gérant', codePin: '1234', estAdmin: false),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    final prefs = await SharedPreferences.getInstance();
    final String? magasinsJson = prefs.getString('s_stock_magasins_data');
    
    if (magasinsJson != null) {
      try {
        final List<dynamic> decodedList = jsonDecode(magasinsJson);
        setState(() {
          _magasins = decodedList.map((m) => Magasin.fromJson(m)).toList();
          _chargementEnCours = false;
        });
      } catch (e) {
        setState(() => _chargementEnCours = false);
      }
    } else {
      setState(() => _chargementEnCours = false);
    }
  }

  Future<void> sauvegarderDonnees() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(_magasins.map((m) => m.toJson()).toList());
    await prefs.setString('s_stock_magasins_data', encodedData);
  }

  @override
  Widget build(BuildContext context) {
    if (_chargementEnCours) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      title: 'S-Stock - Multi-Magasins',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
      home: _magasinActif != null
          ? DashboardPage(
              magasin: _magasinActif!,
              onChangerMagasin: () => setState(() => _magasinActif = null),
              onDonneesModifiees: sauvegarderDonnees,
            )
          : MagasinSelectionPage(
              magasins: _magasins,
              administrateursApp: _administrateursApp,
              onMagasinSelectionne: (mag) => setState(() => _magasinActif = mag),
              onMagasinAjoute: (nouveauMag) {
                setState(() {
                  _magasins.add(nouveauMag);
                  _magasinActif = nouveauMag;
                });
                sauvegarderDonnees();
              },
            ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  final Magasin magasin;
  final VoidCallback onChangerMagasin;
  final VoidCallback onDonneesModifiees;

  const DashboardPage({
    Key? key,
    required this.magasin,
    required this.onChangerMagasin,
    required this.onDonneesModifiees,
  }) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _sessionJourActive = true;
  final DateTime _dateSessionCourante = DateTime.now();

  double get chiffreAffairesJour {
    return widget.magasin.historiqueVentes.fold(0.0, (sum, v) => sum + v.total);
  }

  double get depensesTotal {
    return widget.magasin.depenses.fold(0.0, (sum, d) => sum + d.montant);
  }

  double get soldeTresorerieCumule {
    double totalEncaissements = widget.magasin.mouvementsCaisse
        .where((m) => m.type == 'Versement' || m.type == 'Entrée')
        .fold(0.0, (sum, m) => sum + m.montant);
    double totalRetraits = widget.magasin.mouvementsCaisse
        .where((m) => m.type == 'Retrait' || m.type == 'Sortie')
        .fold(0.0, (sum, m) => sum + m.montant);
    return totalEncaissements - totalRetraits;
  }

  void _confirmerClotureSessionDialog() {
    double totalVentes = chiffreAffairesJour;
    double totalDep = depensesTotal;
    double reliquatNet = totalVentes - totalDep;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation - Clôture de la Journée'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total des ventes : ${totalVentes.toStringAsFixed(0)} FCFA'),
            Text('Total des dépenses : ${totalDep.toStringAsFixed(0)} FCFA'),
            const Divider(),
            Text(
              'Reliquat versé automatiquement en caisse : ${reliquatNet.toStringAsFixed(0)} FCFA',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blue),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() {
                widget.magasin.mouvementsCaisse.add(
                  MouvementCaisse(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    date: DateTime.now(),
                    type: 'Versement',
                    montant: reliquatNet,
                    motif: 'Clôture session du ${_dateSessionCourante.day}/${_dateSessionCourante.month}/${_dateSessionCourante.year}',
                    auteur: widget.magasin.nomGerant,
                  ),
                );
                _sessionJourActive = false;
              });
              widget.onDonneesModifiees();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Session clôturée et reliquat versé en caisse avec succès !')),
              );
            },
            child: const Text('Valider la Clôture'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int produitsEnAlerte = widget.magasin.produits.where((p) => p.quantite <= p.alerteQuantite).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.magasin.nomMagasin} - Gérant : ${widget.magasin.nomGerant}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            tooltip: 'Paramètres Magasin & Facture',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MagasinSettingsPage(
                    magasin: widget.magasin,
                    onMagasinModifie: () {
                      setState(() {});
                      widget.onDonneesModifiees();
                    },
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.store, color: Colors.white),
            tooltip: 'Changer de Magasin',
            onPressed: widget.onChangerMagasin,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bienvenue au ${widget.magasin.nomMagasin}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Clôture de session avec versement automatique dans la caisse principale
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _sessionJourActive ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _sessionJourActive ? Colors.green : Colors.orange,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _sessionJourActive ? Icons.check_circle : Icons.lock,
                        color: _sessionJourActive ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _sessionJourActive ? 'Session de vente ouverte' : 'Session clôturée',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _sessionJourActive ? Colors.green.shade800 : Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                  if (_sessionJourActive)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.lock_clock),
                      label: const Text('Clôturer la Journée'),
                      onPressed: _confirmerClotureSessionDialog,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // Rappels (Vente du jour, Solde trésorerie, Alerte Stock)
            LayoutBuilder(
              builder: (context, constraints) {
                bool isWide = constraints.maxWidth > 600;
                return Flex(
                  direction: isWide ? Axis.horizontal : Axis.vertical,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSummaryCard('Ventes du Jour', '$chiffreAffairesJour FCFA', Icons.point_of_sale, Colors.green),
                    SizedBox(height: isWide ? 0 : 10, width: isWide ? 10 : 0),
                    _buildSummaryCard('Solde Trésorerie', '$soldeTresorerieCumule FCFA', Icons.account_balance_wallet, Colors.blue),
                    SizedBox(height: isWide ? 0 : 10, width: isWide ? 10 : 0),
                    _buildSummaryCard('Alerte Stock', '$produitsEnAlerte produits', Icons.warning_amber_rounded, Colors.red),
                  ],
                );
              },
            ),
            const SizedBox(height: 30),
            const Text('Modules du Magasin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            // Grille des modules
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildMenuCard(
                  context,
                  title: 'Caisse / Ventes',
                  icon: Icons.shopping_cart,
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SalesPage(
                          produits: widget.magasin.produits,
                          clients: widget.magasin.clients,
                          historiqueVentes: widget.magasin.historiqueVentes,
                          magasin: widget.magasin,
                          onNouvelleVente: (vente) {
                            setState(() => widget.magasin.historiqueVentes.add(vente));
                            widget.onDonneesModifiees();
                          },
                          onSupprimerVente: (id) {
                            setState(() => widget.magasin.historiqueVentes.removeWhere((v) => v.id == id));
                            widget.onDonneesModifiees();
                          },
                          onNouveauClientAuto: (client) {
                            setState(() => widget.magasin.clients.add(client));
                            widget.onDonneesModifiees();
                          },
                        ),
                      ),
                    );
                  },
                ),
                _buildMenuCard(
                  context,
                  title: 'Trésorerie & Caisse',
                  icon: Icons.account_balance_wallet,
                  color: Colors.blueGrey,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CaisseTresoreriePage(
                          mouvements: widget.magasin.mouvementsCaisse,
                          onMouvementAjoute: (m) {
                            setState(() => widget.magasin.mouvementsCaisse.add(m));
                            widget.onDonneesModifiees();
                          },
                          utilisateurActif: widget.magasin.utilisateurs.first,
                        ),
                      ),
                    );
                  },
                ),
                _buildMenuCard(
                  context,
                  title: 'Gestion des Stocks',
                  icon: Icons.inventory_2,
                  color: Colors.indigo,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StockPage(
                          produits: widget.magasin.produits,
                          onProduitAjoute: (p) {
                            setState(() => widget.magasin.produits.add(p));
                            widget.onDonneesModifiees();
                          },
                          onProduitModifie: (p) {
                            setState(() {});
                            widget.onDonneesModifiees();
                          },
                          onProduitSupprime: (id) {
                            setState(() => widget.magasin.produits.removeWhere((p) => p.id == id));
                            widget.onDonneesModifiees();
                          },
                        ),
                      ),
                    );
                  },
                ),
                _buildMenuCard(
                  context,
                  title: 'Gestion Clients',
                  icon: Icons.people,
                  color: Colors.teal,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClientsPage(
                          clients: widget.magasin.clients,
                          onClientAjoute: (c) {
                            setState(() => widget.magasin.clients.add(c));
                            widget.onDonneesModifiees();
                          },
                          onClientModifie: (c) {
                            setState(() {});
                            widget.onDonneesModifiees();
                          },
                          onClientSupprime: (id) {
                            setState(() => widget.magasin.clients.removeWhere((c) => c.id == id));
                            widget.onDonneesModifiees();
                          },
                        ),
                      ),
                    );
                  },
                ),
                _buildMenuCard(
                  context,
                  title: 'Dépenses',
                  icon: Icons.receipt_long,
                  color: Colors.deepOrange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ExpensesPage(
                          depenses: widget.magasin.depenses,
                          onDepenseAjoutee: (d) {
                            setState(() => widget.magasin.depenses.add(d));
                            widget.onDonneesModifiees();
                          },
                          onDepenseSupprimee: (id) {
                            setState(() => widget.magasin.depenses.removeWhere((item) => item.id == id));
                            widget.onDonneesModifiees();
                          },
                        ),
                      ),
                    );
                  },
                ),
                _buildMenuCard(
                  context,
                  title: 'Rapports & Synthèse',
                  icon: Icons.bar_chart,
                  color: Colors.cyan.shade800,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReportsPage(
                          historiqueVentes: widget.magasin.historiqueVentes,
                          depenses: widget.magasin.depenses,
                          produits: widget.magasin.produits,
                        ),
                      ),
                    );
                  },
                ),
                _buildMenuCard(
                  context,
                  title: 'Synthèse Ventes',
                  icon: Icons.analytics,
                  color: Colors.brown,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SynthesePage(
                          historiqueVentes: widget.magasin.historiqueVentes,
                          onVenteSupprimee: () {
                            setState(() {});
                            widget.onDonneesModifiees();
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 5),
                  Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}