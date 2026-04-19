import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DiscoveryPage extends StatelessWidget {
  const DiscoveryPage({super.key});

  static const routeName = 'discovery';
  static const routePath = '/discovery';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EduConnect')),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(-6.200000, 106.816666),
                zoom: 12,
              ),
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),
          ),
          Expanded(
            flex: 2,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                _SectionTitle(title: 'Week 1 Foundation Ready'),
                SizedBox(height: 8),
                _ItemTile(label: 'Flutter structure: app/core/features'),
                _ItemTile(label: 'Supabase bootstrap integrated'),
                _ItemTile(label: 'Google Maps widget initialized'),
                _ItemTile(label: 'Ready for auth and role in Week 2'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.check_circle_outline),
        title: Text(label),
      ),
    );
  }
}

