import 'dart:async';

import 'package:educonnect/features/auth/application/auth_controller.dart';
import 'package:educonnect/features/auth/domain/models/app_user_profile.dart';
import 'package:educonnect/features/booking/application/booking_controller.dart';
import 'package:educonnect/features/chat/application/chat_controller.dart';
import 'package:educonnect/features/chat/presentation/pages/inbox_page.dart';
import 'package:educonnect/features/home/application/nearby_tutor_controller.dart';
import 'package:educonnect/features/home/application/tutor_controller.dart';
import 'package:educonnect/features/home/domain/models/tutor_summary.dart';
import 'package:educonnect/features/home/presentation/pages/tutor_list_page.dart';
import 'package:educonnect/features/booking/presentation/pages/student_bookings_page.dart';
import 'package:educonnect/features/tutor/presentation/pages/tutor_detail_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class StudentHomePage extends ConsumerStatefulWidget {
  const StudentHomePage({super.key});

  static const routeName = 'student-home';
  static const routePath = '/student/home';

  @override
  ConsumerState<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends ConsumerState<StudentHomePage> {
  final TextEditingController _searchController = TextEditingController();
  final Completer<GoogleMapController> _mapController = Completer();
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(nearbyTutorControllerProvider).refreshUserLocation(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final nearbyTutorsAsync = ref.watch(nearbyTutorsProvider);
    final fallbackTutorsAsync = ref.watch(activeTutorsProvider);
    final location = ref.watch(userLocationProvider);
    final isLocating = ref.watch(locationLoadingProvider);
    final locationError = ref.watch(locationErrorProvider);
    final radiusKm = ref.watch(searchRadiusKmProvider);
    final pendingPaymentCount = ref.watch(studentAwaitingPaymentCountProvider);
    final paidCount = ref.watch(studentPaidCountProvider);
    final unreadChatCount =
        ref.watch(unreadMessagesCountProvider).valueOrNull ?? 0;

    return profileAsync.when(
      data: (profile) {
        final sourceTutors = location == null
            ? fallbackTutorsAsync
            : nearbyTutorsAsync;

        return sourceTutors.when(
          data: (tutors) => _StudentHomeScaffold(
            profile: profile,
            tutors: tutors,
            selectedCategory: _selectedCategory,
            searchController: _searchController,
            location: location == null
                ? null
                : LatLng(location.latitude, location.longitude),
            isLocating: isLocating,
            locationError: locationError,
            radiusKm: radiusKm,
            mapController: _mapController,
            onSearchChanged: (_) => setState(() {}),
            onCategoryChanged: (category) {
              setState(() {
                _selectedCategory = category;
              });
            },
            onRadiusChanged: (value) {
              ref.read(nearbyTutorControllerProvider).setSearchRadius(value);
            },
            onRefreshLocation: () {
              ref.read(nearbyTutorControllerProvider).refreshUserLocation();
            },
            bookingNotificationCount: pendingPaymentCount + paidCount,
            pendingPaymentCount: pendingPaymentCount,
            paidCount: paidCount,
            onOpenBookings: () =>
                context.pushNamed(StudentBookingsPage.routeName),
            unreadChatCount: unreadChatCount,
            onOpenInbox: () => context.pushNamed(InboxPage.routeName),
            onLogout: () => ref.read(authControllerProvider).signOut(),
          ),
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, _) => Scaffold(
            body: _ErrorState(
              message: 'Gagal memuat daftar tutor. Coba beberapa saat lagi.',
              detail: error.toString(),
              onRetry: () {
                ref.invalidate(activeTutorsProvider);
                ref.invalidate(nearbyTutorsProvider);
                ref.read(nearbyTutorControllerProvider).refreshUserLocation();
              },
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        body: _ErrorState(
          message: 'Gagal memuat data akun.',
          detail: error.toString(),
          onRetry: () {
            ref.invalidate(currentUserProfileProvider);
          },
        ),
      ),
    );
  }
}

class _StudentHomeScaffold extends StatelessWidget {
  const _StudentHomeScaffold({
    required this.profile,
    required this.tutors,
    required this.selectedCategory,
    required this.searchController,
    required this.location,
    required this.isLocating,
    required this.locationError,
    required this.radiusKm,
    required this.mapController,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onRadiusChanged,
    required this.onRefreshLocation,
    required this.bookingNotificationCount,
    required this.pendingPaymentCount,
    required this.paidCount,
    required this.onOpenBookings,
    required this.unreadChatCount,
    required this.onOpenInbox,
    required this.onLogout,
  });

  final AppUserProfile? profile;
  final List<TutorSummary> tutors;
  final String selectedCategory;
  final TextEditingController searchController;
  final LatLng? location;
  final bool isLocating;
  final String? locationError;
  final double radiusKm;
  final Completer<GoogleMapController> mapController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<double> onRadiusChanged;
  final VoidCallback onRefreshLocation;
  final int bookingNotificationCount;
  final int pendingPaymentCount;
  final int paidCount;
  final VoidCallback onOpenBookings;
  final int unreadChatCount;
  final VoidCallback onOpenInbox;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final greetingName = profile?.displayName.isNotEmpty == true
        ? profile!.displayName
        : 'Sahabat Belajar';
    final categories = _buildCategories(tutors);
    final filteredTutors = _filterTutors(
      tutors: tutors,
      query: searchController.text,
      selectedCategory: selectedCategory,
    );
    const maxHomeList = 30;
    final visibleTutors = filteredTutors.take(maxHomeList).toList();

    final markers = _buildMarkers(filteredTutors, location);
    final initialCamera = location != null
        ? CameraPosition(target: location!, zoom: 13)
        : const CameraPosition(target: LatLng(-6.200000, 106.816666), zoom: 11);

    return Scaffold(
      appBar: AppBar(
        title: Text('Hello, $greetingName'),
        actions: [
          _BookingNotificationButton(
            icon: Icons.chat_bubble_outline,
            count: unreadChatCount,
            onTap: onOpenInbox,
          ),
          _BookingNotificationButton(
            icon: Icons.notifications_outlined,
            count: bookingNotificationCount,
            onTap: onOpenBookings,
          ),
          IconButton(onPressed: onLogout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SearchBar(controller: searchController, onChanged: onSearchChanged),
          const SizedBox(height: 12),
          if (pendingPaymentCount > 0 || paidCount > 0) ...[
            _BookingStatusBanner(
              pendingPaymentCount: pendingPaymentCount,
              paidCount: paidCount,
              onTap: onOpenBookings,
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              const Icon(Icons.place_outlined),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  location == null
                      ? 'Lokasi belum terdeteksi'
                      : 'Lokasi aktif (${location!.latitude.toStringAsFixed(4)}, ${location!.longitude.toStringAsFixed(4)})',
                ),
              ),
              IconButton(
                onPressed: () => _showManualLocationDialog(context),
                icon: const Icon(Icons.edit_location_alt_outlined),
              ),
              IconButton(
                onPressed: isLocating ? null : onRefreshLocation,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          if (locationError != null) ...[
            Text(
              locationError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 8),
          ],
          Text('Radius pencarian: ${radiusKm.toStringAsFixed(0)} km'),
          Slider(
            min: 1,
            max: 20,
            divisions: 19,
            value: radiusKm,
            label: '${radiusKm.toStringAsFixed(0)} km',
            onChanged: onRadiusChanged,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 240,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: kIsWeb
                  ? _WebMapFallback(location: location)
                  : GoogleMap(
                      initialCameraPosition: initialCamera,
                      myLocationButtonEnabled: true,
                      myLocationEnabled: location != null,
                      markers: markers,
                      onMapCreated: (controller) {
                        if (!mapController.isCompleted) {
                          mapController.complete(controller);
                        }
                      },
                    ),
            ),
          ),
          const SizedBox(height: 20),
          _SectionHeader(
            title: 'Tutor Terdekat',
            actionText: 'View All',
            onTapAction: () => context.pushNamed(TutorListPage.routeName),
          ),
          const SizedBox(height: 8),
          _CategoryChips(
            categories: categories,
            selected: selectedCategory,
            onSelected: onCategoryChanged,
          ),
          const SizedBox(height: 12),
          if (filteredTutors.isNotEmpty && filteredTutors.length > maxHomeList)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Menampilkan $maxHomeList tutor terdekat dari ${filteredTutors.length} hasil.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          if (filteredTutors.isEmpty)
            const _EmptyTutorState()
          else
            ...visibleTutors.map((tutor) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TutorListCard(
                  tutor: tutor,
                  onTap: () async {
                    if (!kIsWeb &&
                        mapController.isCompleted &&
                        (tutor.latitude != 0 || tutor.longitude != 0)) {
                      final controller = await mapController.future;
                      await controller.animateCamera(
                        CameraUpdate.newLatLngZoom(
                          LatLng(tutor.latitude, tutor.longitude),
                          14,
                        ),
                      );
                    }
                    if (context.mounted) {
                      context.pushNamed(
                        TutorDetailPage.routeName,
                        pathParameters: {'tutorId': tutor.uid},
                      );
                    }
                  },
                ),
              );
            }),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) {
            context.pushNamed(StudentBookingsPage.routeName);
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'Kelas'),
          NavigationDestination(
            icon: Icon(Icons.auto_stories),
            label: 'E-Book',
          ),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Future<void> _showManualLocationDialog(BuildContext context) async {
    final latController = TextEditingController();
    final lngController = TextEditingController();
    final result = await showDialog<(double, double)>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set Lokasi Manual'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: latController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: const InputDecoration(labelText: 'Latitude'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: lngController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: const InputDecoration(labelText: 'Longitude'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  latController.text = '-6.200000';
                  lngController.text = '106.816666';
                },
                child: const Text('Isi contoh: Jakarta Pusat'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final lat = double.tryParse(latController.text.trim());
                final lng = double.tryParse(lngController.text.trim());
                if (lat == null || lng == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Latitude/longitude tidak valid.'),
                    ),
                  );
                  return;
                }
                if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Rentang koordinat tidak valid. Cek nilai latitude/longitude.',
                      ),
                    ),
                  );
                  return;
                }
                Navigator.pop(context, (lat, lng));
              },
              child: const Text('Gunakan'),
            ),
          ],
        );
      },
    );

    if (result == null || !context.mounted) {
      return;
    }

    final (lat, lng) = result;
    final container = ProviderScope.containerOf(context, listen: false);
    await container
        .read(nearbyTutorControllerProvider)
        .setManualLocation(latitude: lat, longitude: lng);
  }

  Set<Marker> _buildMarkers(List<TutorSummary> tutors, LatLng? userLocation) {
    final markers = <Marker>{};
    const maxMarkers = 80;
    if (userLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('me'),
          position: userLocation,
          infoWindow: const InfoWindow(title: 'Lokasi Saya'),
        ),
      );
    }

    for (final tutor in tutors.take(maxMarkers)) {
      if (tutor.latitude == 0 && tutor.longitude == 0) {
        continue;
      }
      markers.add(
        Marker(
          markerId: MarkerId(tutor.uid),
          position: LatLng(tutor.latitude, tutor.longitude),
          infoWindow: InfoWindow(
            title: tutor.name,
            snippet: 'Rating ${tutor.rating.toStringAsFixed(1)}',
          ),
        ),
      );
    }
    return markers;
  }

  List<String> _buildCategories(List<TutorSummary> items) {
    final set = <String>{'All'};
    for (final tutor in items) {
      set.addAll(tutor.subjects);
    }
    return set.toList();
  }

  List<TutorSummary> _filterTutors({
    required List<TutorSummary> tutors,
    required String query,
    required String selectedCategory,
  }) {
    return tutors.where((tutor) {
      final matchQuery = tutor.matchesKeyword(query);
      final matchCategory =
          selectedCategory == 'All' ||
          tutor.subjects.contains(selectedCategory);
      return matchQuery && matchCategory;
    }).toList();
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Cari tutor atau mapel...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionText,
    required this.onTapAction,
  });

  final String title;
  final String actionText;
  final VoidCallback onTapAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        InkWell(
          onTap: onTapAction,
          child: Text(
            actionText,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: categories.map((item) {
        final isSelected = item == selected;
        return ChoiceChip(
          label: Text(item),
          selected: isSelected,
          onSelected: (_) => onSelected(item),
          selectedColor: const Color(0xFF4B176E),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
          ),
        );
      }).toList(),
    );
  }
}

class _TutorListCard extends StatelessWidget {
  const _TutorListCard({required this.tutor, required this.onTap});

  final TutorSummary tutor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(
          tutor.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text(tutor.rating.toStringAsFixed(1)),
                const SizedBox(width: 8),
                Text('(${tutor.totalReviews})'),
                const SizedBox(width: 12),
                const Icon(Icons.place_outlined, size: 16),
                const SizedBox(width: 4),
                Text(
                  tutor.distanceFromUserKm == null
                      ? '-'
                      : '${tutor.distanceFromUserKm!.toStringAsFixed(1)} km',
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Mulai dari Rp ${tutor.pricePerHour}/jam'),
          ],
        ),
        trailing: CircleAvatar(
          backgroundColor: Colors.teal.shade200,
          backgroundImage: tutor.photoUrl.isNotEmpty
              ? NetworkImage(tutor.photoUrl)
              : null,
          child: tutor.photoUrl.isEmpty ? const Icon(Icons.person) : null,
        ),
      ),
    );
  }
}

class _EmptyTutorState extends StatelessWidget {
  const _EmptyTutorState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
      ),
      child: const Text('Belum ada tutor dalam radius pencarian ini.'),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.detail,
    required this.onRetry,
  });

  final String message;
  final String detail;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 36),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WebMapFallback extends StatelessWidget {
  const _WebMapFallback({required this.location});

  final LatLng? location;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map_outlined, size: 36),
            const SizedBox(height: 10),
            const Text(
              'Peta tidak tersedia di mode web saat ini.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              location == null
                  ? 'Gunakan Android untuk tampilan peta interaktif.'
                  : 'Lokasi aktif: ${location!.latitude.toStringAsFixed(4)}, ${location!.longitude.toStringAsFixed(4)}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingNotificationButton extends StatelessWidget {
  const _BookingNotificationButton({
    required this.icon,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        IconButton(onPressed: onTap, icon: Icon(icon), tooltip: 'Notifikasi'),
        if (count > 0)
          Container(
            margin: const EdgeInsets.only(top: 8, right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count > 9 ? '9+' : '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _BookingStatusBanner extends StatelessWidget {
  const _BookingStatusBanner({
    required this.pendingPaymentCount,
    required this.paidCount,
    required this.onTap,
  });

  final int pendingPaymentCount;
  final int paidCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = <String>[];
    if (pendingPaymentCount > 0) {
      text.add('$pendingPaymentCount booking menunggu pembayaran');
    }
    if (paidCount > 0) {
      text.add('$paidCount booking sudah lunas');
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline),
            const SizedBox(width: 8),
            Expanded(child: Text(text.join(' • '))),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
