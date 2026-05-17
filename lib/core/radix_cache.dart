import 'dart:math' as math;
import 'location_search_service.dart';

/// A single node in the Radix Tree.
class RadixNode<T> {
  String edgeLabel;
  Map<String, RadixNode<T>> children;
  T? value;
  bool isEnd;

  RadixNode({
    required this.edgeLabel,
    this.value,
    this.isEnd = false,
  }) : children = {};
}

/// A generic space-optimized Radix Tree (compact prefix tree) implementation.
class RadixTree<T> {
  final RadixNode<T> _root = RadixNode<T>(edgeLabel: "");

  /// Inserts a key-value pair into the Radix Tree.
  void insert(String key, T value) {
    if (key.isEmpty) return;
    _insert(_root, key.toLowerCase().trim(), value);
  }

  void _insert(RadixNode<T> node, String key, T value) {
    if (key.isEmpty) {
      node.value = value;
      node.isEnd = true;
      return;
    }

    for (var entry in node.children.entries) {
      String edge = entry.key;
      RadixNode<T> child = entry.value;

      int commonPrefixLength = _getCommonPrefixLength(key, edge);

      if (commonPrefixLength > 0) {
        // Case 1: Key matches edge label completely or edge label matches key completely
        if (commonPrefixLength == edge.length) {
          _insert(child, key.substring(commonPrefixLength), value);
          return;
        }

        // Case 2: Split the edge
        String commonPrefix = edge.substring(0, commonPrefixLength);
        String remainingEdge = edge.substring(commonPrefixLength);
        String remainingKey = key.substring(commonPrefixLength);

        // Create a new intermediate node
        RadixNode<T> intermediate = RadixNode<T>(
          edgeLabel: commonPrefix,
        );

        // Remove child from current node's children list
        node.children.remove(edge);
        node.children[commonPrefix] = intermediate;

        // Reparent child under the intermediate node
        child.edgeLabel = remainingEdge;
        intermediate.children[remainingEdge] = child;

        // Insert remaining part of key
        _insert(intermediate, remainingKey, value);
        return;
      }
    }

    // Case 3: No common prefix with any child, insert directly
    node.children[key] = RadixNode<T>(
      edgeLabel: key,
      value: value,
      isEnd: true,
    );
  }

  /// Looks up an exact match in the Radix Tree.
  T? lookup(String key) {
    if (key.isEmpty) return null;
    return _lookup(_root, key.toLowerCase().trim());
  }

  T? _lookup(RadixNode<T> node, String key) {
    if (key.isEmpty) {
      return node.isEnd ? node.value : null;
    }

    for (var entry in node.children.entries) {
      String edge = entry.key;
      RadixNode<T> child = entry.value;

      if (key == edge) {
        return child.isEnd ? child.value : null;
      } else if (key.startsWith(edge)) {
        return _lookup(child, key.substring(edge.length));
      }
    }

    return null;
  }

  /// Looks up values that match a prefix (e.g. autocompleting queries).
  List<T> getWithPrefix(String prefix) {
    if (prefix.isEmpty) return [];
    List<T> results = [];
    _findPrefix(_root, prefix.toLowerCase().trim(), results);
    return results;
  }

  void _findPrefix(RadixNode<T> node, String prefix, List<T> results) {
    if (prefix.isEmpty) {
      _collectAllValues(node, results);
      return;
    }

    for (var entry in node.children.entries) {
      String edge = entry.key;
      RadixNode<T> child = entry.value;

      if (edge.startsWith(prefix)) {
        _collectAllValues(child, results);
        return;
      } else if (prefix.startsWith(edge)) {
        _findPrefix(child, prefix.substring(edge.length), results);
        return;
      }
    }
  }

  void _collectAllValues(RadixNode<T> node, List<T> results) {
    if (node.isEnd && node.value != null) {
      results.add(node.value!);
    }
    for (var child in node.children.values) {
      _collectAllValues(child, results);
    }
  }

  int _getCommonPrefixLength(String s1, String s2) {
    int minLen = math.min(s1.length, s2.length);
    for (int i = 0; i < minLen; i++) {
      if (s1[i] != s2[i]) return i;
    }
    return minLen;
  }
}

/// Service that manages search query caching using a Radix Tree.
class RadixCacheService {
  // Singleton pattern
  static final RadixCacheService _instance = RadixCacheService._internal();
  factory RadixCacheService() => _instance;
  RadixCacheService._internal();

  final RadixTree<List<LocationResult>> _cache = RadixTree<List<LocationResult>>();

  /// Adds search results to the cache.
  void set(String query, List<LocationResult> results) {
    _cache.insert(query, results);
  }

  /// Retrieves search results from the cache by looking up the query.
  List<LocationResult>? get(String query) {
    return _cache.lookup(query);
  }

  /// Performs fuzzy / autocomplete prefix lookup for search queries.
  List<LocationResult>? getPrefixMatches(String prefix) {
    final matches = _cache.getWithPrefix(prefix);
    if (matches.isEmpty) return null;
    // Flatten list of list to single unique list of results
    final uniqueResults = <String, LocationResult>{};
    for (var list in matches) {
      for (var item in list) {
        uniqueResults[item.name] = item;
      }
    }
    return uniqueResults.values.toList();
  }
}
