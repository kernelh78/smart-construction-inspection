import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/site.dart';
import '../../providers/sites_provider.dart';
import 'site_detail_screen.dart';

class SitesMapScreen extends StatefulWidget {
  const SitesMapScreen({super.key});

  @override
  State<SitesMapScreen> createState() => _SitesMapScreenState();
}

class _SitesMapScreenState extends State<SitesMapScreen> {
  GoogleMapController? _mapController;

  static const LatLng _defaultCenter = LatLng(37.5665, 126.9780); // 서울 시청

  Set<Marker> _buildMarkers(List<Site> sites) {
    return {
      for (final site in sites)
        if (site.lat != null && site.lng != null)
          Marker(
            markerId: MarkerId(site.id),
            position: LatLng(site.lat!, site.lng!),
            infoWindow: InfoWindow(
              title: site.name,
              snippet: site.address,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SiteDetailScreen(site: site)),
              ),
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              site.status == 'active'
                  ? BitmapDescriptor.hueGreen
                  : site.status == 'completed'
                      ? BitmapDescriptor.hueBlue
                      : BitmapDescriptor.hueOrange,
            ),
          ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final sites = context.watch<SitesProvider>().sites;
    final markers = _buildMarkers(sites);

    return Scaffold(
      appBar: AppBar(
        title: const Text('현장 지도'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(target: _defaultCenter, zoom: 12),
        markers: markers,
        myLocationButtonEnabled: false,
        onMapCreated: (ctrl) {
          _mapController = ctrl;
          if (markers.isNotEmpty) {
            final first = markers.first.position;
            _mapController?.animateCamera(CameraUpdate.newLatLng(first));
          }
        },
      ),
      floatingActionButton: markers.isEmpty
          ? null
          : FloatingActionButton.small(
              backgroundColor: const Color(0xFF1565C0),
              onPressed: () {
                final first = markers.first.position;
                _mapController?.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(target: first, zoom: 13),
                  ),
                );
              },
              child: const Icon(Icons.center_focus_strong, color: Colors.white),
            ),
    );
  }
}
