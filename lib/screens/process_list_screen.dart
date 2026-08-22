import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sse_frontend_mobil/models/process.dart';
import 'package:sse_frontend_mobil/providers/process_provider.dart';
import 'package:sse_frontend_mobil/widgets/process_card.dart';

enum _StatusFilter { all, active, closed }

class ProcessListScreen extends ConsumerStatefulWidget {
  const ProcessListScreen({super.key});

  @override
  ConsumerState<ProcessListScreen> createState() => _ProcessListScreenState();
}

class _ProcessListScreenState extends ConsumerState<ProcessListScreen> {
  final _searchController = TextEditingController();
  _StatusFilter _statusFilter = _StatusFilter.all;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Process> _filterProcesses(List<Process> processes) {
    var filtered = processes;

    switch (_statusFilter) {
      case _StatusFilter.active:
        filtered = filtered.where((p) => !p.isClosed).toList();
        break;
      case _StatusFilter.closed:
        filtered = filtered.where((p) => p.isClosed).toList();
        break;
      case _StatusFilter.all:
        break;
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((p) {
        return p.name.toLowerCase().contains(q) ||
            (p.clientName?.toLowerCase().contains(q) ?? false) ||
            (p.description?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    return filtered;
  }

  Map<String, List<Process>> _groupByClient(List<Process> processes) {
    final map = <String, List<Process>>{};
    for (final p in processes) {
      final key = p.clientName ?? 'Sin empresa';
      map.putIfAbsent(key, () => []).add(p);
    }
    final sortedKeys = map.keys.toList()..sort();
    return {for (final k in sortedKeys) k: map[k]!};
  }

  @override
  Widget build(BuildContext context) {
    final processState = ref.watch(processListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        title: const Text(
          'Procesos',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(child: _buildProcessList(processState)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Buscar por nombre, empresa...',
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
          prefixIcon:
              const Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 18, color: Color(0xFF94A3B8)),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      child: Row(
        children: [
          _buildChip('Todos', _StatusFilter.all),
          const SizedBox(width: 8),
          _buildChip('En curso', _StatusFilter.active),
          const SizedBox(width: 8),
          _buildChip('Sellados', _StatusFilter.closed),
        ],
      ),
    );
  }

  Widget _buildChip(String label, _StatusFilter filter) {
    final isSelected = _statusFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1E293B)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildProcessList(AsyncValue<List<Process>> processState) {
    return processState.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF1E293B)),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 48, color: Color(0xFF94A3B8)),
              const SizedBox(height: 16),
              const Text(
                'Sin conexion',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Verifica tu conexion a internet',
                style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(processListProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
      data: (processes) {
        final filtered = _filterProcesses(processes);

        if (filtered.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _searchQuery.isNotEmpty || _statusFilter != _StatusFilter.all
                        ? Icons.search_off_rounded
                        : Icons.assignment_turned_in_rounded,
                    size: 48,
                    color: const Color(0xFF94A3B8),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isNotEmpty || _statusFilter != _StatusFilter.all
                        ? 'Sin resultados'
                        : 'Sin procesos',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _searchQuery.isNotEmpty || _statusFilter != _StatusFilter.all
                        ? 'Intenta con otros filtros'
                        : 'No hay procesos disponibles',
                    style:
                        const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
          );
        }

        final grouped = _groupByClient(filtered);

        return RefreshIndicator(
          onRefresh: () async {
            await ref.read(processListProvider.notifier).refresh();
          },
          color: const Color(0xFF1E293B),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _countItems(grouped),
            itemBuilder: (context, index) {
              return _buildListItem(grouped, index);
            },
          ),
        );
      },
    );
  }

  int _countItems(Map<String, List<Process>> grouped) {
    int count = 0;
    for (final entry in grouped.entries) {
      count += 1; // header
      count += entry.value.length; // process cards
    }
    return count;
  }

  Widget _buildListItem(Map<String, List<Process>> grouped, int index) {
    int currentIndex = 0;
    for (final entry in grouped.entries) {
      if (currentIndex == index) {
        return _buildClientHeader(entry.key, entry.value.length);
      }
      currentIndex++;

      for (final process in entry.value) {
        if (currentIndex == index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ProcessCard(
              process: process,
              onTap: () => context.push('/process/${process.id}'),
            ),
          );
        }
        currentIndex++;
      }
    }
    return const SizedBox.shrink();
  }

  Widget _buildClientHeader(String client, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 8),
      child: Row(
        children: [
          const Icon(Icons.business_rounded,
              size: 16, color: Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(
            client,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
