import 'package:flutter/material.dart';
import '../models/team.dart';
import '../models/player.dart';
import '../models/competition.dart';
import '../services/api_service.dart';
import 'team_detail.dart';
import 'player_detail.dart';
import 'competition_detail.dart';

/// Écran de recherche des équipes
/// Permet aux utilisateurs de rechercher et filtrer les équipes
class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

/// État de l'écran de recherche
/// Gère la logique de recherche et l'affichage des résultats
class _SearchScreenState extends State<SearchScreen> {
  /// Service API pour récupérer les données
  final ApiService _apiService = ApiService();
  /// Contrôleur du champ de recherche
  final TextEditingController _searchController = TextEditingController();
  /// Liste des équipes filtrées par la recherche
  List<Team> _filteredTeams = [];
  /// Indique si la recherche est en cours
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Charge la liste initiale des équipes
  Future<void> _loadTeams() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final teams = await _apiService.fetchTeamsFromApi();
      setState(() {
        _filteredTeams = teams;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Erreur lors du chargement des équipes');
    }
  }

  /// Filtre les équipes en fonction du texte de recherche
  void _filterTeams(String query) async {
    if (query.isEmpty) {
      await _loadTeams();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final teams = await _apiService.searchTeams(query);
      setState(() {
        _filteredTeams = teams;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Erreur lors de la recherche');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          /// Barre de recherche
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher une équipe...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: _filterTeams,
            ),
          ),
          /// Liste des résultats
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredTeams.isEmpty
                    ? Center(child: Text('Aucune équipe trouvée'))
                    : ListView.builder(
                        itemCount: _filteredTeams.length,
                        itemBuilder: (context, index) {
                          final team = _filteredTeams[index];
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
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TeamDetailScreen(team: team),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}