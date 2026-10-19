import 'stock_page.dart';
import 'clients_page.dart';
import 'expenses_page.dart';
import 'caisse_tresorerie_model.dart';
import 'auth_model.dart';
import 'sales_page.dart';

class Magasin {
  String id;
  String nomMagasin;
  String nomGerant;
  String codePin;
  String contact;
  String adresse;
  List<Produit> produits;
  List<Client> clients;
  List<Vente> historiqueVentes;
  List<Depense> depenses;
  List<MouvementCaisse> mouvementsCaisse;
  List<Utilisateur> utilisateurs;

  Magasin({
    required this.id,
    required this.nomMagasin,
    required this.nomGerant,
    required this.codePin,
    this.contact = '07 07 07 07 07',
    this.adresse = 'ABIDJAN',
    required this.produits,
    required this.clients,
    required this.historiqueVentes,
    required this.depenses,
    required this.mouvementsCaisse,
    required this.utilisateurs,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nomMagasin': nomMagasin,
      'nomGerant': nomGerant,
      'codePin': codePin,
      'contact': contact,
      'adresse': adresse,
      'produits': produits.map((p) => p.toJson()).toList(),
      'clients': clients.map((c) => c.toJson()).toList(),
      'historiqueVentes': historiqueVentes.map((v) => v.toJson()).toList(),
      'depenses': depenses.map((d) => d.toJson()).toList(),
      'mouvementsCaisse': mouvementsCaisse.map((m) => m.toJson()).toList(),
      'utilisateurs': utilisateurs.map((u) => u.toJson()).toList(),
    };
  }

  factory Magasin.fromJson(Map<String, dynamic> json) {
    return Magasin(
      id: json['id'] ?? '',
      nomMagasin: json['nomMagasin'] ?? '',
      nomGerant: json['nomGerant'] ?? '',
      codePin: json['codePin'] ?? '',
      contact: json['contact'] ?? '07 07 07 07 07',
      adresse: json['adresse'] ?? 'ABIDJAN',
      produits: (json['produits'] as List? ?? []).map((p) => Produit.fromJson(p)).toList(),
      clients: (json['clients'] as List? ?? []).map((c) => Client.fromJson(c)).toList(),
      historiqueVentes: (json['historiqueVentes'] as List? ?? []).map((v) => Vente.fromJson(v)).toList(),
      depenses: (json['depenses'] as List? ?? []).map((d) => Depense.fromJson(d)).toList(),
      mouvementsCaisse: (json['mouvementsCaisse'] as List? ?? []).map((m) => MouvementCaisse.fromJson(m)).toList(),
      utilisateurs: (json['utilisateurs'] as List? ?? []).map((u) => Utilisateur.fromJson(u)).toList(),
    );
  }
}