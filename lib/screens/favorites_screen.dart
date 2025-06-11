import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/team.dart';
import '../models/player.dart';
import 'team_detail.dart';
import 'player_detail.dart';

/// Écran des favoris
/// Affiche et gère les équipes et joueurs favoris de l'utilisateur
class FavoritesScreen extends StatefulWidget {
  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

/// État de l'écran des favoris
/// Gère la récupération et l'affichage des favoris
class _FavoritesScreenState extends State<FavoritesScreen> with SingleTickerProviderStateMixin {
  /// Service de base de données pour accéder aux favoris
  final DatabaseService _databaseService = DatabaseService();
  /// Contrôleur pour la gestion des onglets
  late TabController _tabController;
  /// Liste des équipes favorites
  List<Team> _favoriteTeams = [];
  /// Liste des joueurs favoris
  List<Player> _favoritePlayers = [];
  /// Indique si le chargement est en cours
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFavorites();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Charge les équipes et joueurs favoris depuis la base de données
  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final teams = await _databaseService.getFavoriteTeams();
      final players = await _databaseService.getFavoritePlayers();
      setState(() {
        _favoriteTeams = teams;
        _favoritePlayers = players;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Erreur lors du chargement des favoris');
    }
  }

  /// Supprime une équipe des favoris
  Future<void> _removeTeam(Team team) async {
    try {
      await _databaseService.removeTeam(team.id);
      setState(() {
        _favoriteTeams.removeWhere((t) => t.id == team.id);
      });
      _showSuccessSnackBar('Équipe retirée des favoris');
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la suppression');
    }
  }

  /// Supprime un joueur des favoris
  Future<void> _removePlayer(Player player) async {
    try {
      await _databaseService.removePlayer(player.id);
      setState(() {
        _favoritePlayers.removeWhere((p) => p.id == player.id);
      });
      _showSuccessSnackBar('Joueur retiré des favoris');
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la suppression');
    }
  }

  /// Affiche un message d'erreur
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Affiche un message de succès
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// Barre d'onglets pour naviguer entre équipes et joueurs
      appBar: AppBar(
        title: Text('Favoris'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Équipes'),
            Tab(text: 'Joueurs'),
          ],
        ),
      ),
      /// Contenu principal avec les listes de favoris
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                /// Liste des équipes favorites
                _favoriteTeams.isEmpty
                    ? Center(child: Text('Aucune équipe favorite'))
                    : ListView.builder(
                        itemCount: _favoriteTeams.length,
                        itemBuilder: (context, index) {
                          final team = _favoriteTeams[index];
                          return ListTile(
                            leading: team.logo.isNotEmpty
                                ? Image.network(
                                    team.logo,
                                    width: 40,
                                    height: 40,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Icon(Icons.sports_soccer),
                                  )
                                : Icon(Icons.sports_soccer),
                            title: Text(team.name),
                            subtitle: Text(team.country),
                            trailing: IconButton(
                              icon: Icon(Icons.favorite, color: Colors.red),
                              onPressed: () => _removeTeam(team),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TeamDetail(team: team),
                                ),
                              );
                            },
                          );
                        },
                      ),
                /// Liste des joueurs favoris
                _favoritePlayers.isEmpty
                    ? Center(child: Text('Aucun joueur favori'))
                    : ListView.builder(
                        itemCount: _favoritePlayers.length,
                        itemBuilder: (context, index) {
                          final player = _favoritePlayers[index];
                          return ListTile(
                            leading: player.photo.isNotEmpty
                                ? CircleAvatar(
                                    backgroundImage: NetworkImage(player.photo),
                                  )
                                : CircleAvatar(
                                    child: Text(player.name[0]),
                                  ),
                            title: Text(player.name),
                            subtitle: Text(player.position),
                            trailing: IconButton(
                              icon: Icon(Icons.favorite, color: Colors.red),
                              onPressed: () => _removePlayer(player),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PlayerDetail(player: player),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ],
            ),
    );
  }
}