import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

import '../models/team.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final ApiService _apiService = ApiService();
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  bool _isShowingFavorites = false;
  String? _errorMessage;
  List<Team> _searchResults = [];
  List<Marker> _markers = [];
  LatLng _center = LatLng(48.8566, 2.3522); // Paris

  @override
  void initState() {
    super.initState();
    _onSearchChanged(); // Charger toutes les équipes au départ
  }

  void _onSearchChanged() async {
    if (_isShowingFavorites) return; // Ne rien faire si on affiche les favoris
    final query = _searchController.text.trim();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _markers = [];
    });

    try {
      final results = query.isEmpty
          ? await _apiService.fetchTeamsFromApi()
          : await _apiService.searchTeams(query);

      _searchResults = results;
      await _buildMarkersFromTeams(_searchResults);
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de recherche : $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _buildMarkersFromTeams(List<Team> teams) async {
    List<Marker> markers = [];
    LatLng? firstTeamPosition;

    for (var team in teams) {
      LatLng position;

      try {
        if (team.venue != null && team.venue.isNotEmpty) {
          List<Location> locations = await locationFromAddress(team.venue);
          if (locations.isNotEmpty) {
            position = LatLng(locations[0].latitude, locations[0].longitude);
          } else {
            position = _simulatePosition(team.id);
          }
        } else {
          position = _simulatePosition(team.id);
        }
      } catch (e) {
        position = _simulatePosition(team.id);
      }

      firstTeamPosition ??= position;

      markers.add(Marker(
        width: 80,
        height: 80,
        point: position,
        builder: (ctx) => Tooltip(
          message: '${team.name}\n${team.venue ?? "Lieu inconnu"}',
          child: ClipOval(
            child: Image.network(
              team.logo,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image, size: 40),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const CircularProgressIndicator();
              },
            ),
          ),
        ),
      ));
    }

    setState(() {
      _markers = markers;
      _center = firstTeamPosition ?? _center;
    });
  }

  Future<void> _loadFavoriteTeams() async {
    setState(() {
      _isLoading = true;
      _isShowingFavorites = true;
      _markers = [];
    });

    try {
      final favorites = await _dbService.getFavoriteTeams(); // SQLite
      await _buildMarkersFromTeams(favorites);
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur chargement favoris : $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  LatLng _simulatePosition(int id) {
    double lat = 48.8566 + (id % 10) * 0.02 - 0.1;
    double lng = 2.3522 + (id % 10) * 0.02 - 0.1;
    return LatLng(lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isShowingFavorites
            ? 'Favoris sur la carte'
            : 'Carte des équipes'),
        actions: [
          if (_isShowingFavorites)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Retour à la recherche',
              onPressed: () {
                setState(() {
                  _isShowingFavorites = false;
                  _searchController.clear();
                });
                _onSearchChanged();
              },
            )
        ],
      ),
      body: Column(
        children: [
          if (!_isShowingFavorites)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => _onSearchChanged(),
                decoration: InputDecoration(
                  hintText: 'Rechercher une équipe...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0)),
                ),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : FlutterMap(
              options: MapOptions(
                center: _center,
                zoom: 5.5,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                  'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerLayer(markers: _markers),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Voir favoris',
        child: const Icon(Icons.favorite),
        onPressed: _loadFavoriteTeams,
      ),
    );
  }
}
