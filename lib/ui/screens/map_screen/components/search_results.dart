import 'package:flutter/material.dart';

class SearchResults extends StatelessWidget {
  final List<Map<String, dynamic>> searchResults;
  final Function(Map<String, dynamic>) onLandmarkSelected;
  final bool isVisible;

  const SearchResults({
    Key? key,
    required this.searchResults,
    required this.onLandmarkSelected,
    required this.isVisible,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox();

    return Positioned(
      top: 110,
      left: 16,
      right: 16,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 300),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: searchResults.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final landmark = searchResults[index];
            return ListTile(
              leading: const Icon(Icons.location_on, color: Colors.green),
              title: Text(
                landmark['name'],
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                landmark['description'] ?? 'No description available',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              onTap: () => onLandmarkSelected(landmark),
            );
          },
        ),
      ),
    );
  }
}
