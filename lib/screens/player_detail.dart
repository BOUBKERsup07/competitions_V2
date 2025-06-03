import 'package:flutter/material.dart';
import '../models/player.dart';
import '../services/database_service.dart';

class PlayerDetail extends StatefulWidget {
  final Player player;

  const PlayerDetail({Key? key, required this.player}) : super(key: key);

  @override
  _PlayerDetailState createState() => _PlayerDetailState();
}

class _PlayerDetailState extends State<PlayerDetail> {
  final DatabaseService _dbService = DatabaseService();
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    try {
      final favoritePlayers = await _dbService.getFavoritePlayers();
      setState(() {
        _isFavorite = favoritePlayers.any((p) => p.id == widget.player.id);
      });
    } catch (e) {
      print('Erreur vérification favori joueur: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      if (_isFavorite) {
        await _dbService.removePlayer(widget.player.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Joueur retiré des favoris')),
        );
      } else {
        await _dbService.insertPlayer(widget.player);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Joueur ajouté aux favoris')),
        );
      }
      setState(() {
        _isFavorite = !_isFavorite;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.player;

    return Scaffold(
      appBar: AppBar(
        title: Text(player.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: player.photo.isNotEmpty
                  ? CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(player.photo),
              )
                  : CircleAvatar(
                radius: 50,
                child: Text(player.name[0]),
              ),
            ),
            SizedBox(height: 20),
            Text(player.name,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('Date de naissance : ${player.birthDate}',
                style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text('Position : ${player.position}',
                style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text('Nationalité : ${player.nationality}',
                style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text('Équipe : ${player.teamName}',
                style: TextStyle(fontSize: 18)),
            Spacer(),
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
          ],
        ),
      ),
    );
  }
}
