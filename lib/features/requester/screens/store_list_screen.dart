import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/stores_provider.dart';

/// Browsable list of nearby stores for the Requester.
/// Can be embedded in HomeScreen or shown standalone.
class StoreListScreen extends ConsumerWidget {
  final bool embedded;

  const StoreListScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stores = ref.watch(storesProvider);

    final body = stores.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text('Failed to load stores\n$e', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(onPressed: () => ref.invalidate(storesProvider),
                child: const Text('Retry')),
          ],
        ),
      ),
      data: (storeList) {
        if (storeList.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.storefront_outlined,
                    size: 64, color: AppColors.textSecondaryLight.withOpacity(0.5)),
                const SizedBox(height: 16),
                const Text('No stores available yet',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const Text('Stores from the Kursi Road corridor\nwill appear here',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondaryLight)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: storeList.length,
          itemBuilder: (context, index) {
            final store = storeList[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _categoryColor(store.category).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _categoryIcon(store.category),
                    color: _categoryColor(store.category),
                  ),
                ),
                title: Text(
                  store.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(store.address,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _categoryColor(store.category).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          store.category.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _categoryColor(store.category),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () =>
                    context.pushNamed('createOrder', pathParameters: {
                  'storeId': store.id.toString(),
                }),
              ),
            );
          },
        );
      },
    );

    if (embedded) return body;

    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Stores')),
      body: body,
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'pharmacy':
        return Icons.local_pharmacy_rounded;
      case 'bakery':
        return Icons.bakery_dining_rounded;
      case 'stationery':
        return Icons.edit_rounded;
      default:
        return Icons.storefront_rounded;
    }
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'pharmacy':
        return AppColors.success;
      case 'bakery':
        return AppColors.accent;
      case 'stationery':
        return AppColors.info;
      default:
        return AppColors.primary;
    }
  }
}
