import 'package:flutter/material.dart';
import '../models/team.dart';
import '../models/player.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';
import 'player_detail.dart';

class TeamDetail extends StatefulWidget {
  final Team team;

  const TeamDetail({required this.team});

  @override
  _TeamDetailState createState() => _TeamDetailState();
}

class _TeamDetailState extends State<TeamDetail> {
  final DatabaseService _dbService = DatabaseService();
  final ApiService _apiService = ApiService();

  bool _isFavorite = false;
  List<Player> _players = [];
  bool _isLoadingPlayers = true;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
    _loadPlayers();
  }

  Future<void> _checkIfFavorite() async {
    try {
      final favoriteTeams = await _dbService.getFavoriteTeams();
      if (mounted) {
        setState(() {
          _isFavorite = favoriteTeams.any((team) => team.id == widget.team.id);
        });
      }
    } catch (e) {
      print('Erreur vérification favori: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      if (_isFavorite) {
        await _dbService.removeTeam(widget.team.id);
      } else {
        await _dbService.insertTeam(widget.team);
      }
      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
        });
      }
    } catch (e) {
      print('Erreur toggle favori: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la mise à jour des favoris')),
      );
    }
  }

  Future<void> _loadPlayers() async {
    try {
      final players = await _apiService.fetchPlayersFromApi(widget.team);
      players.sort((a, b) => a.name.compareTo(b.name));
      if (mounted) {
        setState(() {
          _players = players;
          _isLoadingPlayers = false;
        });
      }
    } catch (e) {
      print('Erreur chargement joueurs: $e');
      if (mounted) {
        setState(() {
          _isLoadingPlayers = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.team.name),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
            tooltip: _isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: widget.team.logo.isNotEmpty
                  ? Image.network(
                widget.team.logo,
                height: 150,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.people, size: 150),
              )
                  : Icon(Icons.people, size: 150),
            ),
            SizedBox(height: 20),
            Text(
              widget.team.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 10),
            Text('Pays: ${widget.team.country}'),
            SizedBox(height: 10),
            Text('Année de fondation: ${widget.team.founded}'),
            SizedBox(height: 10),
            Text('Stade: ${widget.team.venue}'),
            SizedBox(height: 20),
            Text(
              'Informations',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 10),
            Text('Nom court: ${widget.team.shortName}'),
            SizedBox(height: 20),

            // 🔽 Bouton Favori
            Center(
              child: ElevatedButton.icon(
                onPressed: _toggleFavorite,
                icon: Icon(_isFavorite ? Icons.remove_circle : Icons.favorite),
                label: Text(
                  _isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFavorite ? Colors.red : Colors.green,
                ),
              ),
            ),

            SizedBox(height: 30),
            Text(
              'Joueurs',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 10),
            _isLoadingPlayers
                ? Center(child: CircularProgressIndicator())
                : _players.isEmpty
                ? Text("Aucun joueur trouvé.")
                : Column(
              children: _players.map((player) {
                return ListTile(
                  leading: player.photo?.isNotEmpty == true
                      ? Image.network(
                    player.photo!,
                    width: 40,
                    height: 40,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.person),
                  )
                      : Icon(Icons.person),
                  title: Text(player.name),
                  subtitle: Text(player.position ?? "Position inconnue"),
                  trailing: Text(player.nationality ?? ''),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PlayerDetail(player: player),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
