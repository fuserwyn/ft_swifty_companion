import 'package:flutter/material.dart';

import '../models/student.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(student.login)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: constraints.maxWidth,
                  maxWidth: 760,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _ProfileHeader(student: student),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _InfoCards(student: student),
                    const SizedBox(height: 20),
                    Text(
                      'Skills',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: student.skills
                              .map((skill) => _SkillTile(skill: skill))
                              .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Projects',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    if (student.projects.isEmpty)
                      const Text('No projects found.')
                    else
                      ...student.projects.map(
                        (project) => _ProjectTile(project: project),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          child: CircleAvatar(
            radius: 42,
            backgroundImage:
                student.imageUrl.isNotEmpty ? NetworkImage(student.imageUrl) : null,
            child: student.imageUrl.isEmpty
                ? const Icon(Icons.person, size: 36)
                : null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(student.login, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(student.email),
              Text('Mobile: ${student.phone}'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: const Icon(Icons.badge, size: 16),
                    label: Text(student.login),
                  ),
                  Chip(
                    avatar: const Icon(Icons.school, size: 16),
                    label: Text('Level ${student.level.toStringAsFixed(2)}'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoCards extends StatelessWidget {
  const _InfoCards({required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _InfoCard(label: 'Level', value: student.level.toStringAsFixed(2)),
        _InfoCard(label: 'Location', value: student.location),
        _InfoCard(label: 'Wallet', value: '${student.wallet} ₳'),
        _InfoCard(
          label: 'Evaluation points',
          value: student.evaluationPoints.toString(),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(value),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkillTile extends StatelessWidget {
  const _SkillTile({required this.skill});

  final Skill skill;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(skill.name)),
              Text(
                '${skill.level.toStringAsFixed(2)} (${skill.percent.toStringAsFixed(1)}%)',
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: skill.percent / 100,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({required this.project});

  final Project project;

  Color _statusColor(BuildContext context) {
    if (project.validated == true) return Colors.green;
    if (project.validated == false) return Colors.red;
    return Theme.of(context).colorScheme.secondary;
  }

  String _statusLabel() {
    if (project.validated == true) return 'passed';
    if (project.validated == false) return 'failed';
    return project.status;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(project.name),
        subtitle: Text('Mark: ${project.finalMark?.toString() ?? '-'}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _statusColor(context).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            _statusLabel(),
            style: TextStyle(
              color: _statusColor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
