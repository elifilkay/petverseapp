import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../widgets/place_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class Place {
  final String id;
  final String name;
  final String address;
  final String type;
  final String phone;
  final String imageUrl;
  final LatLng location;

  Place({
    required this.id,
    required this.name,
    required this.address,
    required this.type,
    required this.phone,
    required this.imageUrl,
    required this.location,
  });

  factory Place.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final GeoPoint geoPoint = data['location'] as GeoPoint;
    
    return Place(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      type: data['type'] ?? '',
      phone: data['phone'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      location: LatLng(geoPoint.latitude, geoPoint.longitude),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'type': type,
      'phone': phone,
      'imageUrl': imageUrl,
      'location': GeoPoint(location.latitude, location.longitude),
    };
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  final Set<Marker> _markers = {};
  LatLng? _currentLocation;
  final List<String> _selectedFilters = ['Veterinary'];
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<Place> _places = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _loadPlaces();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      _getCurrentLocation();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konum izni gerekli'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _updateMarkers();
      });
      _animateToCurrentLocation();
    } catch (e) {
      debugPrint('Konum alınamadı: $e');
    }
  }

  void _animateToCurrentLocation() {
    if (_currentLocation != null) {
      mapController.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation!, 14),
      );
    }
  }

  Future<void> _loadPlaces() async {
    try {
      final placesSnapshot = await FirebaseFirestore.instance
          .collection('places')
          .where('type', whereIn: _selectedFilters)
          .get();

      setState(() {
        _places = placesSnapshot.docs
            .map((doc) => Place.fromFirestore(doc))
            .toList();
        _isLoading = false;
        _updateMarkers();
      });
    } catch (e) {
      debugPrint('Mekanlar yüklenirken hata: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateMarkers() {
    _markers.clear();
    if (_currentLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Konumunuz'),
        ),
      );
    }

    for (var place in _places) {
      if (_selectedFilters.contains(place.type)) {
        _markers.add(
          Marker(
            markerId: MarkerId(place.id),
            position: place.location,
            infoWindow: InfoWindow(
              title: place.name,
              snippet: place.address,
            ),
            onTap: () => _showPlaceDetails(place),
          ),
        );
      }
    }
    setState(() {});
  }

  void _onSearch(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        _loadPlaces();
        return;
      }

      try {
        final searchResults = await FirebaseFirestore.instance
            .collection('places')
            .where('name', isGreaterThanOrEqualTo: query)
            .where('name', isLessThan: query + 'z')
            .get();

        setState(() {
          _places = searchResults.docs
              .map((doc) => Place.fromFirestore(doc))
              .toList();
          _updateMarkers();
        });
      } catch (e) {
        debugPrint('Arama yapılırken hata: $e');
      }
    });
  }

  void _showPlaceDetails(Place place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.3,
        maxChildSize: 0.7,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    place.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      place.type,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.location_on),
                    title: Text(place.address),
                    trailing: IconButton(
                      icon: const Icon(Icons.directions),
                      onPressed: () {
                        final url = 'https://www.google.com/maps/dir/?api=1&destination=${place.location.latitude},${place.location.longitude}';
                        launchUrl(Uri.parse(url));
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.phone),
                    title: Text(place.phone),
                    trailing: IconButton(
                      icon: const Icon(Icons.call),
                      onPressed: () {
                        final url = 'tel:${place.phone}';
                        launchUrl(Uri.parse(url));
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  onMapCreated: (controller) {
                    mapController = controller;
                    if (_currentLocation != null) {
                      _animateToCurrentLocation();
                    }
                  },
                  initialCameraPosition: CameraPosition(
                    target: _currentLocation ?? const LatLng(41.0082, 28.9784),
                    zoom: 14.0,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearch,
                      decoration: InputDecoration(
                        hintText: 'Veteriner, petshop, park ara...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.filter_list, color: Colors.white),
                      onPressed: () {
                        _showFilterBottomSheet(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'location',
            onPressed: _getCurrentLocation,
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () {
              // TODO: Implement add new place
            },
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filtrele',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Veteriner'),
                        selected: _selectedFilters.contains('Veterinary'),
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              _selectedFilters.add('Veterinary');
                            } else {
                              _selectedFilters.remove('Veterinary');
                            }
                          });
                        },
                      ),
                      FilterChip(
                        label: const Text('Pet Shop'),
                        selected: _selectedFilters.contains('Pet Shop'),
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              _selectedFilters.add('Pet Shop');
                            } else {
                              _selectedFilters.remove('Pet Shop');
                            }
                          });
                        },
                      ),
                      FilterChip(
                        label: const Text('Pet Oteli'),
                        selected: _selectedFilters.contains('Pet Hotel'),
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              _selectedFilters.add('Pet Hotel');
                            } else {
                              _selectedFilters.remove('Pet Hotel');
                            }
                          });
                        },
                      ),
                      FilterChip(
                        label: const Text('Pet Parkı'),
                        selected: _selectedFilters.contains('Pet Park'),
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              _selectedFilters.add('Pet Park');
                            } else {
                              _selectedFilters.remove('Pet Park');
                            }
                          });
                        },
                      ),
                      FilterChip(
                        label: const Text('Pet Cafe'),
                        selected: _selectedFilters.contains('Pet Cafe'),
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              _selectedFilters.add('Pet Cafe');
                            } else {
                              _selectedFilters.remove('Pet Cafe');
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedFilters.clear();
                              _selectedFilters.add('Veterinary');
                            });
                          },
                          child: const Text('Temizle'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _loadPlaces();
                            Navigator.pop(context);
                          },
                          child: const Text('Uygula'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
