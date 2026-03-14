import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/websocket_service.dart';
import '../../../workloads/domain/repositories/workload_repository.dart';
import '../../../workloads/domain/entities/namespace_entity.dart';
import '../../../workloads/domain/entities/workload_entity.dart';
import 'package:provider/provider.dart';

class LogsPage extends StatefulWidget {
  final String? initialNamespace;
  final String? initialPod;

  const LogsPage({super.key, this.initialNamespace, this.initialPod});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();
  StreamSubscription? _logSubscription;
  
  String? _selectedNamespace;
  String? _selectedPod;
  List<NamespaceEntity> _namespaces = [];
  List<WorkloadEntity> _pods = [];
  bool _isLoadingNamespaces = false;
  bool _isLoadingPods = false;

  @override
  void initState() {
    super.initState();
    _selectedNamespace = widget.initialNamespace;
    _selectedPod = widget.initialPod;
    _loadNamespaces();
    if (_selectedNamespace != null && _selectedPod != null) {
      _startLogStream();
    }
  }

  Future<void> _loadNamespaces() async {
    setState(() => _isLoadingNamespaces = true);
    try {
      final repo = context.read<WorkloadRepository>();
      final ns = await repo.getNamespaces('current-cluster');
      setState(() {
        _namespaces = ns;
        _isLoadingNamespaces = false;
        if (_selectedNamespace == null && ns.isNotEmpty) {
          _selectedNamespace = 'default';
        }
      });
      if (_selectedNamespace != null) {
        _loadPods();
      }
    } catch (e) {
      setState(() => _isLoadingNamespaces = false);
    }
  }

  Future<void> _loadPods() async {
    if (_selectedNamespace == null) return;
    setState(() {
      _isLoadingPods = true;
      _pods = [];
    });
    try {
      final repo = context.read<WorkloadRepository>();
      final pods = await repo.getPods('current-cluster', _selectedNamespace!);
      setState(() {
        _pods = pods;
        _isLoadingPods = false;
      });
    } catch (e) {
      setState(() => _isLoadingPods = false);
    }
  }

  Future<void> _startLogStream() async {
    if (_selectedNamespace == null || _selectedPod == null) return;
    
    await _logSubscription?.cancel();
    setState(() {
      _logs.clear();
      _logs.add('--- Connecting to logs for $_selectedPod ---');
    });

    try {
      final wsService = context.read<WebSocketService>();
      final logStream = await wsService.createStandaloneStream(
        '/api/v1/ws/logs/$_selectedNamespace/$_selectedPod',
      );

      _logSubscription = logStream.listen(
        (data) {
          if (data['type'] == 'POD_LOG') {
            setState(() {
              _logs.add(data['data']);
              if (_logs.length > 500) _logs.removeAt(0);
            });
            _scrollToBottom();
          }
        },
        onError: (error) {
          setState(() => _logs.add('--- Log stream error: $error ---'));
        },
        onDone: () {
          setState(() => _logs.add('--- Log stream closed ---'));
        },
      );
    } catch (e) {
      setState(() => _logs.add('--- Failed to connect to log stream: $e ---'));
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _logSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildControls(),
        const SizedBox(height: 12),
        Expanded(child: _buildLogTerminal()),
      ],
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildDropdown(
              label: 'Namespace',
              value: _selectedNamespace,
              items: _namespaces.map((ns) => ns.name).toList(),
              isLoading: _isLoadingNamespaces,
              onChanged: (val) {
                setState(() {
                  _selectedNamespace = val;
                  _selectedPod = null;
                });
                _loadPods();
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildDropdown(
              label: 'Pod',
              value: _selectedPod,
              items: _pods.map((p) => p.name).toList(),
              isLoading: _isLoadingPods,
              onChanged: (val) {
                setState(() => _selectedPod = val);
                _startLogStream();
              },
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textDim),
            onPressed: () {
              if (_selectedPod != null) _startLogStream();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: AppColors.textDim),
            onPressed: () => setState(() => _logs.clear()),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required bool isLoading,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.border),
          ),
          child: isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : DropdownButton<String>(
                  value: value,
                  isExpanded: true,
                  underline: const SizedBox(),
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.textMain, fontSize: 13),
                  items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: onChanged,
                ),
        ),
      ],
    );
  }

  Widget _buildLogTerminal() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F111A), // Drac-ish dark
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: _selectedPod == null
          ? const Center(child: Text('Select a pod to view logs', style: TextStyle(color: AppColors.textDim)))
          : ListView.builder(
              controller: _scrollController,
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                return Text(
                  _logs[index],
                  style: const TextStyle(
                    color: Color(0xFFE6EDF3),
                    fontFamily: 'monospace',
                    fontSize: 12,
                    height: 1.4,
                  ),
                );
              },
            ),
    );
  }
}
