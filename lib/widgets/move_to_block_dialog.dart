import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/block.dart';
import '../services/block_database.dart';

class MoveToBlockDialog extends StatefulWidget {
  final VoidCallback onBlockSelected;

  const MoveToBlockDialog({super.key, required this.onBlockSelected});

  @override
  State<MoveToBlockDialog> createState() => _MoveToBlockDialogState();
}

class _MoveToBlockDialogState extends State<MoveToBlockDialog> {
  List<Block> _blocks = [];
  bool _isCreating = false;
  final TextEditingController _newBlockController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshBlocks();
  }

  void _refreshBlocks() {
    setState(() {
      _blocks = BlockDatabase.getBlocks();
    });
  }

  @override
  void dispose() {
    _newBlockController.dispose();
    super.dispose();
  }

  Future<void> _createBlock() async {
    final name = _newBlockController.text.trim();
    if (name.isNotEmpty) {
      final newBlock = Block()
        ..id = const Uuid().v4()
        ..name = name
        ..createdAt = DateTime.now();
      
      await BlockDatabase.createBlock(newBlock);
      _newBlockController.clear();
      setState(() => _isCreating = false);
      _refreshBlocks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Move to Block",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Serif',
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            
            // List of Blocks
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  // Option for "None" / "Others"
                  ListTile(
                    leading: Icon(Icons.folder_off_outlined, color: theme.hintColor),
                    title: Text("Others (No Block)", style: TextStyle(color: theme.colorScheme.onSurface)),
                    onTap: () => Navigator.pop(context, null), // Return null for 'Others'
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  const Divider(height: 16),
                  
                  if (_blocks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "No blocks created yet.",
                        style: TextStyle(color: theme.hintColor, fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  ..._blocks.map((block) => ListTile(
                    leading: Icon(Icons.folder_outlined, color: theme.colorScheme.secondary),
                    title: Text(block.name, style: TextStyle(color: theme.colorScheme.onSurface)),
                    onTap: () => Navigator.pop(context, block.id),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline, size: 18, color: theme.colorScheme.error.withOpacity(0.5)),
                      onPressed: () async {
                        await BlockDatabase.deleteBlock(block.id);
                        _refreshBlocks();
                      },
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  )),
                ],
              ),
            ),

            const SizedBox(height: 16),
            
            // Create New Block Section
            if (_isCreating)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newBlockController,
                      autofocus: true,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: "Block name...",
                        hintStyle: TextStyle(color: theme.hintColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onSubmitted: (_) => _createBlock(),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.check, color: theme.colorScheme.secondary),
                    onPressed: _createBlock,
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _isCreating = true),
                  icon: Icon(Icons.add, size: 18, color: theme.colorScheme.secondary),
                  label: Text("Create Block", style: TextStyle(color: theme.colorScheme.secondary)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.dividerColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
