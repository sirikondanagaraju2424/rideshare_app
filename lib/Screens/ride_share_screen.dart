import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:rideshare_app/models/ride_model.dart'; // CORRECTED
class RideShareScreen extends StatefulWidget {
  final String currentUserName;
  const RideShareScreen({super.key, required this.currentUserName});

  @override
  State<RideShareScreen> createState() => _RideShareScreenState();
}

// --- ALL YOUR ORIGINAL CODE REMAINS UNCHANGED FROM HERE ---
// (The rest of your provided code for RideShareScreen goes here)
class _RideShareScreenState extends State<RideShareScreen> {
  late Future<List<Ride>> _ridesFuture;
  int _selectedToggleIndex = 0;
  static const String _baseUrl = 'https://69slj1azc3.execute-api.us-east-1.amazonaws.com/dev';
  String? _searchStartLocation;
  String? _searchEndLocation;
  final Map<String, bool> _expandedCardMap = {};

  String get currentUserName => widget.currentUserName;
  bool get _isSearchActive => (_searchStartLocation != null && _searchStartLocation!.isNotEmpty) ||
                            (_searchEndLocation != null && _searchEndLocation!.isNotEmpty);

  @override
  void initState() {
    super.initState();
    _ridesFuture = _fetchRides();
  }

  Future<List<Ride>> _fetchRides() async {
    final String rideTypeToFetch = _selectedToggleIndex == 0 ? 'AVAILABLE' : 'NEEDED';
    final queryParams = <String, String>{'rideType': rideTypeToFetch};

    if (_searchStartLocation != null && _searchStartLocation!.isNotEmpty) {
      queryParams['startLocation'] = _searchStartLocation!;
    }
    if (_searchEndLocation != null && _searchEndLocation!.isNotEmpty) {
      queryParams['endLocation'] = _searchEndLocation!;
    }

    final uri = Uri.parse('$_baseUrl/rides').replace(queryParameters: queryParams);
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> rideDataList = json.decode(response.body);
        return rideDataList.map((data) => Ride.fromJson(data)).toList();
      } else {
        throw Exception('Failed to load rides. Server returned status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to process server response: $e');
    }
  }

  void _refreshRides() {
    setState(() {
      _expandedCardMap.clear();
      _ridesFuture = _fetchRides();
    });
  }

  Future<void> _deleteRide(Ride rideToDelete) async {
    final uri = Uri.parse('$_baseUrl/rides/${rideToDelete.rideId}')
      .replace(queryParameters: {'userId': currentUserName});
    try {
      final response = await http.delete(uri);
      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        throw Exception('Failed to delete ride: ${errorBody['error']}');
      }
    } catch (e) {
      throw Exception('Failed to send delete request: $e');
    }
  }

  void _showDeleteConfirmationDialog(Ride ride) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Ride'),
          content: const Text('Are you sure you want to permanently delete this ride?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog first
                try {
                  await _deleteRide(ride);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ride deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                  _refreshRides();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showSearchDialog() {
    final startLocationController = TextEditingController(text: _searchStartLocation);
    final endLocationController = TextEditingController(text: _searchEndLocation);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Search Rides'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: startLocationController,
                    decoration: const InputDecoration(
                      hintText: 'Pickup Location',
                      icon: Icon(Icons.my_location),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.swap_vert),
                    onPressed: () {
                      setDialogState(() {
                        final temp = startLocationController.text;
                        startLocationController.text = endLocationController.text;
                        endLocationController.text = temp;
                      });
                    },
                  ),
                  TextField(
                    controller: endLocationController,
                    decoration: const InputDecoration(
                      hintText: 'Destination',
                      icon: Icon(Icons.flag),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _searchStartLocation = null;
                      _searchEndLocation = null;
                    });
                    _refreshRides();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Clear Filter'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _searchStartLocation = startLocationController.text;
                      _searchEndLocation = endLocationController.text;
                    });
                    _refreshRides();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Search'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: _buildToggleButtons(),
          ),
          if (_isSearchActive) _buildFilterIndicator(),
          Expanded(
            child: FutureBuilder<List<Ride>>(
              future: _ridesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('An error occurred: ${snapshot.error}'),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _refreshRides,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  );
                }
                if (snapshot.hasData) {
                  final rides = snapshot.data!;
                  if (rides.isEmpty) {
                    return _isSearchActive ? _buildNoResultsState() : _buildEmptyState();
                  }
                  return RefreshIndicator(
                    onRefresh: () async => _refreshRides(),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: rides.length,
                      itemBuilder: (context, index) => _buildRideCard(rides[index]),
                    ),
                  );
                }
                return _buildEmptyState();
              },
            ),
          ),
          _buildPostRideButton(),
        ],
      ),
    );
  }

  Widget _buildFilterIndicator() {
    String filterText = 'Filtering by: ';
    if (_searchStartLocation != null && _searchStartLocation!.isNotEmpty) {
      filterText += 'From "${_searchStartLocation!}" ';
    }
    if (_searchEndLocation != null && _searchEndLocation!.isNotEmpty) {
      filterText += 'To "${_searchEndLocation!}"';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Colors.blue.shade50,
      child: Row(
        children: [
          Expanded(
            child: Text(
              filterText,
              style: TextStyle(color: Colors.blue.shade800),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.blue.shade800),
            onPressed: () {
              setState(() {
                _searchStartLocation = null;
                _searchEndLocation = null;
              });
              _refreshRides();
            },
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange.withOpacity(0.6),
              Colors.orange.withOpacity(0.2),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () {
          if (_isSearchActive) {
            setState(() {
              _searchStartLocation = null;
              _searchEndLocation = null;
            });
            _refreshRides();
          } else {
            context.pop();
          }
        },
      ),
      title: const Text(
        'Ride Share',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.black),
          onPressed: _showSearchDialog,
        ),
      ],
    );
  }

  Widget _buildToggleButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildToggleButton(text: 'Available', index: 0),
        const SizedBox(width: 15),
        _buildToggleButton(text: 'Need', index: 1),
      ],
    );
  }

  Widget _buildToggleButton({required String text, required int index}) {
    final bool isSelected = _selectedToggleIndex == index;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedToggleIndex = index;
        });
        _refreshRides();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.black : Colors.grey.shade200,
        foregroundColor: isSelected ? Colors.white : Colors.black,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.normal),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No Rides Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to post one, or pull down to refresh.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Results Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search terms or clearing the filter.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildRideCard(Ride ride) {
    final bool isExpanded = _expandedCardMap[ride.rideId] ?? false;

    // Parse and format date and time
    String month = "";
    String day = "";
    // String year = ""; // No longer needed
    String formattedTime = "N/A";

    try {
      if (ride.rideDate != null && ride.rideDate!.isNotEmpty) {
        final dateParts = ride.rideDate!.split('/');
        if (dateParts.length == 3) {
          // Assuming format is MM/DD/YYYY
          month = DateFormat('MMM').format(DateTime(
            int.parse(dateParts[2]),
            int.parse(dateParts[0]),
            int.parse(dateParts[1]),
          )).toUpperCase();
          day = dateParts[1];
          // year = dateParts[2]; // No longer needed
        }
      }

      if (ride.rideTime != null && ride.rideTime!.isNotEmpty) {
        // This part handles both "10:30 PM" and "10:30"
        final time = TimeOfDay(
          hour: int.parse(ride.rideTime!.split(':')[0]),
          minute: int.parse(ride.rideTime!.split(':')[1].split(' ')[0]),
        );
        formattedTime = time.format(context);
      }
    } catch (e) {
      // Handles parsing errors gracefully
      month = "ERR";
      day = "!";
      // year = "!"; // No longer needed
      formattedTime = "Invalid";
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: () {
          setState(() {
            _expandedCardMap[ride.rideId] = !isExpanded;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.orange.shade100,
                    child: Text(
                      ride.userId.isNotEmpty ? ride.userId[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    ride.userId,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.event_seat_outlined, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          ride.seatsAvailable ?? '0',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (ride.userId == currentUserName)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.black87),
                      onSelected: (value) async {
                        if (value == 'edit') {
                          final rideWasUpdated = await context.push<bool>(
                            '/post_ride',
                            extra: {
                              'rideToEdit': ride,
                              'currentUserName': currentUserName,
                            },
                          );
                          if (rideWasUpdated == true && mounted) {
                            _refreshRides();
                          }
                        } else if (value == 'delete') {
                          _showDeleteConfirmationDialog(ride);
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: Colors.black87),
                  const SizedBox(width: 4),
                  Expanded( // Use Expanded to prevent overflow
                    child: Text(
                      '${ride.startLocation} → ${ride.endLocation}',
                      style: const TextStyle(
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              if (isExpanded && ride.moreInfo != null && ride.moreInfo!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    ride.moreInfo!,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 12,
                    ),
                  ),
                ),

              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Compact Calendar Widget
                      Container(
                        width: 70, // Keep width for consistent spacing
                        height: 70, // Adjusted height
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(7),
                                  topRight: Radius.circular(7),
                                ),
                              ),
                              child: Text(
                                month.isNotEmpty ? month : 'MON',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              day.isNotEmpty ? day : '--',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            // Removed the year text widget
                            const Spacer(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Compact Clock Widget
                      Container(
                        width: 60, // Decreased width
                        height: 60, // Decreased height
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.access_time, size: 18, color: Colors.orange), // Decreased icon size
                            const SizedBox(height: 2), // Decreased spacing
                            Text(
                              formattedTime,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12, // Decreased font size
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline, color: Colors.black87),
                    onPressed: () => context.push('/chat', extra: ride),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostRideButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () async {
            final rideWasPosted = await context.push<bool>(
              '/post_ride',
              extra: {'currentUserName': currentUserName},
            );
            if (rideWasPosted == true && mounted) {
              _refreshRides();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Post Ride',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}