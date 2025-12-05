import 'package:hive_flutter/hive_flutter.dart';
import '../models/block.dart';

class BlockDatabase {
  static const String _boxName = 'blocks';

  static Box<Block> get _box => Hive.box<Block>(_boxName);

  static Future<void> initialize() async {
    Hive.registerAdapter(BlockAdapter());
    await Hive.openBox<Block>(_boxName);
  }

  static Future<void> createBlock(Block block) async {
    await _box.put(block.id, block);
  }

  static List<Block> getBlocks() {
    final blocks = _box.values.toList();
    // Sort by creation date
    blocks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return blocks;
  }

  static Future<void> deleteBlock(String id) async {
    await _box.delete(id);
  }
  
  static Block? getBlock(String? id) {
    if (id == null) return null;
    return _box.get(id);
  }
}
