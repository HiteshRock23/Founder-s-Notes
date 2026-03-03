import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../features/projects/presentation/providers/project_provider.dart';
import '../../../../features/projects/domain/entities/project.dart';
import '../providers/capture_provider.dart';
import '../../../../features/projects/presentation/screens/project_detail_screen.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  final String url;

  const CaptureScreen({super.key, required this.url});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  
  String? _selectedProjectId;
  bool _hasInitializedFields = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _onSave(CaptureState state) {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a project first')),
      );
      return;
    }

    ref.read(captureProvider(widget.url).notifier).saveToProject(
      projectId: _selectedProjectId!,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(captureProvider(widget.url));
    final projectsAsync = ref.watch(projectsListProvider);

    // Sync state fields to controllers once loaded
    if (!state.isLoading && !_hasInitializedFields) {
      _hasInitializedFields = true;
      if (state.title != null) _titleController.text = state.title!;
      if (state.description != null) _descController.text = state.description!;
    }

    // Effect: Handle successful save
    ref.listen<CaptureState>(captureProvider(widget.url), (prev, next) {
      if (next.isSaved && prev?.isSaved != true) {
        ReceiveSharingIntent.instance.reset(); // Consume intent
        if (mounted) {
          final project = projectsAsync.valueOrNull?.firstWhere((p) => p.id == _selectedProjectId);
          if (project != null) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => ProjectDetailScreen(project: project),
              ),
            );
          } else {
            Navigator.of(context).pop();
          }
        }
      }
    });

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Save to Founder Notes'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            ReceiveSharingIntent.instance.reset(); // Consume intent
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // URL Readonly Display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      if (state.favicon != null && state.favicon!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              state.favicon!,
                              width: 24,
                              height: 24,
                              errorBuilder: (_, __, ___) => const Icon(Icons.link),
                            ),
                          ),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: Icon(Icons.link, size: 24, color: Colors.grey),
                        ),
                      Expanded(
                        child: Text(
                          widget.url,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (state.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else ...[
                  if (state.error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        state.error!,
                        style: TextStyle(color: theme.colorScheme.onErrorContainer),
                      ),
                    ),
                  
                  // Project Selector
                  Text('Project', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  projectsAsync.when(
                    data: (projects) {
                      if (projects.isEmpty) {
                        return const Text('No projects available. Please create one first.');
                      }
                      
                      // Auto-select first project if none selected
                      if (_selectedProjectId == null && projects.isNotEmpty) {
                        _selectedProjectId = projects.first.id;
                      }

                      return DropdownButtonFormField<String>(
                        value: _selectedProjectId,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.colorScheme.outline),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                          ),
                        ),
                        items: projects.map((p) {
                          return DropdownMenuItem(
                            value: p.id,
                            child: Text(p.name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedProjectId = val);
                        },
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => Text('Error loading projects: $e'),
                  ),
                  const SizedBox(height: 24),

                  AppTextField(
                    label: 'Title',
                    hintText: 'Enter title',
                    controller: _titleController,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Title is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  AppTextField(
                    label: 'Description (Optional)',
                    hintText: 'Enter description or context',
                    controller: _descController,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: state.isSubmitting ? null : () => _onSave(state),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: state.isSubmitting
                          ? const SizedBox(
                              width: 24, height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Save Note', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
