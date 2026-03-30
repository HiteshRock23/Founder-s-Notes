import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../features/projects/presentation/providers/project_provider.dart';
import '../providers/capture_provider.dart';
import '../../../../features/projects/presentation/screens/project_detail_screen.dart';
import '../../../../features/projects/presentation/screens/create_project_sheet.dart';

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
  late FocusNode _titleFocusNode;

  String? _selectedProjectId;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descController = TextEditingController();
    _titleFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _titleFocusNode.dispose();
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

    // Initialize fields once
    if (!_isInit) {
      _isInit = true;
      if (state.title != null) _titleController.text = state.title!;
      if (state.description != null) _descController.text = state.description!;

      if (state.error != null || _titleController.text.trim().isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _titleFocusNode.requestFocus();
        });
      }
    }

    // Effect: Handle Prefill Data when loading finishes
    ref.listen<CaptureState>(captureProvider(widget.url), (prev, next) {
      if (prev?.isLoading == true && next.isLoading == false) {
        final currentTitle = _titleController.text.trim();
        final prevTitle = (prev?.title ?? '').trim();

        // Update Title if user hasn't typed, or if they left the fallback title unmodified
        if (currentTitle.isEmpty || currentTitle == prevTitle) {
          if (next.title != null) _titleController.text = next.title!;
        }

        // Update Description if user hasn't typed
        if (_descController.text.trim().isEmpty && next.description != null) {
          _descController.text = next.description!;
        }

        // If error and title is still empty, focus title
        if (next.error != null && _titleController.text.trim().isEmpty) {
          _titleFocusNode.requestFocus();
        }
      }

      // Handle successful save
      if (next.isSaved && prev?.isSaved != true) {
        ReceiveSharingIntent.instance.reset(); // Consume intent
        if (mounted) {
          final project = projectsAsync.valueOrNull
              ?.firstWhere((p) => p.id == _selectedProjectId);
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
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (state.isLoading)
                        LinearProgressIndicator(
                          minHeight: 2,
                          backgroundColor: Colors.transparent,
                          color: theme.colorScheme.primary,
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            if (state.favicon != null &&
                                state.favicon!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    state.favicon!,
                                    width: 24,
                                    height: 24,
                                    errorBuilder: (_, __, ___) => Icon(
                                        Icons.link,
                                        color: theme.colorScheme.primary),
                                  ),
                                ),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Icon(Icons.link,
                                    size: 24,
                                    color: state.isLoading
                                        ? theme.colorScheme.primary
                                        : Colors.grey),
                              ),
                            Expanded(
                              child: Text(
                                state.url,
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
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (state.error != null && state.title == null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color:
                              theme.colorScheme.error.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 20, color: theme.colorScheme.error),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Could not auto-fill details. Please enter them manually.',
                            style:
                                TextStyle(color: theme.colorScheme.onSurface),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Project Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Project', style: theme.textTheme.titleSmall),
                    TextButton.icon(
                      onPressed: () async {
                        final newProject =
                            await CreateProjectSheet.show(context);
                        if (newProject != null) {
                          setState(() {
                            _selectedProjectId = newProject.id;
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Project created')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New Project'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 0),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                projectsAsync.when(
                  data: (projects) {
                    if (projects.isEmpty) {
                      return const Text(
                          'No projects available. Please create one first.');
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
                          borderSide:
                              BorderSide(color: theme.colorScheme.outline),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: theme.colorScheme.outline
                                  .withValues(alpha: 0.5)),
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
                  focusNode: _titleFocusNode,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Title is required';
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
                  child: FilledButton.icon(
                    onPressed: state.isSubmitting || state.isLoading
                        ? null
                        : () => _onSave(state),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: state.isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.bookmark_add_outlined, size: 20),
                    label: Text(
                        state.isSubmitting
                            ? 'Saving...'
                            : (state.isLoading
                                ? 'Loading Details...'
                                : 'Save Note'),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
