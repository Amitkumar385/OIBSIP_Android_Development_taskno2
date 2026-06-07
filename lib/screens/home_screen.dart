import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import 'login_screen.dart';
import 'add_task_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _allItems = [];
  bool _loading = true;

  static const tabs = ['All', 'Task', 'Event', 'Note'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
    _loadItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() => _loading = true);
    final items = await DatabaseHelper.getTasks(widget.user['id'] as int);
    setState(() { _allItems = items; _loading = false; });
  }

  List<Map<String, dynamic>> _filtered(String type) {
    if (type == 'All') return _allItems;
    return _allItems.where((item) => item['type'] == type).toList();
  }

  Future<void> _delete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w600)),
        content: const Text('Are you sure you want to permanently delete this?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.deleteTask(id);
      _loadItems();
    }
  }

  Future<void> _toggleDone(Map<String, dynamic> item) async {
    await DatabaseHelper.toggleDone(item['id'] as int, item['is_done'] == 0);
    _loadItems();
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w600)),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            child: const Text('Log Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddScreen([Map<String, dynamic>? existing]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTaskScreen(userId: widget.user['id'] as int, existing: existing),
      ),
    );
    _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    final username = widget.user['username'] as String;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('My Tasks', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
            Text('Hello, $username', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Log Out',
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: tabs.map((type) {
                final items = _filtered(type);
                if (items.isEmpty) {
                  return _EmptyState(type: type);
                }
                return RefreshIndicator(
                  onRefresh: _loadItems,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return _ItemCard(
                        item: items[index],
                        onToggle: () => _toggleDone(items[index]),
                        onEdit: () => _openAddScreen(items[index]),
                        onDelete: () => _delete(items[index]['id'] as int),
                      );
                    },
                  ),
                );
              }).toList(),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddScreen(),
        backgroundColor: const Color(0xFF1565C0),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add New', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ItemCard({
    required this.item,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _typeColor {
    switch (item['type']) {
      case 'Event': return const Color(0xFF7B1FA2);
      case 'Note': return const Color(0xFF00695C);
      default: return const Color(0xFF1565C0);
    }
  }

  IconData get _typeIcon {
    switch (item['type']) {
      case 'Event': return Icons.event;
      case 'Note': return Icons.sticky_note_2_outlined;
      default: return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDone = item['is_done'] == 1;
    final desc = (item['description'] as String?) ?? '';
    final type = item['type'] as String;
    final isTask = type == 'Task';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isTask)
              GestureDetector(
                onTap: onToggle,
                child: Icon(
                  isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isDone ? Colors.green : Colors.grey,
                  size: 24,
                ),
              )
            else
              Icon(_typeIcon, color: _typeColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _typeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(fontSize: 11, color: _typeColor, fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (isTask && isDone) ...[
                        const SizedBox(width: 6),
                        const Text('Done', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w500)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item['title'] as String,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDone ? Colors.grey : const Color(0xFF1A1A1A),
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      desc,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blueGrey),
                  onPressed: onEdit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String type;
  const _EmptyState({required this.type});

  @override
  Widget build(BuildContext context) {
    String message;
    IconData icon;
    switch (type) {
      case 'Task':
        icon = Icons.check_circle_outline;
        message = 'No tasks yet.\nTap + to add one.';
        break;
      case 'Event':
        icon = Icons.event_outlined;
        message = 'No events yet.\nTap + to add one.';
        break;
      case 'Note':
        icon = Icons.sticky_note_2_outlined;
        message = 'No notes yet.\nTap + to add one.';
        break;
      default:
        icon = Icons.inbox_outlined;
        message = 'Nothing here yet.\nTap + to get started.';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.grey[400], height: 1.6),
          ),
        ],
      ),
    );
  }
}
