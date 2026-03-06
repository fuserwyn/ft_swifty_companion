class Skill {
  const Skill({
    required this.name,
    required this.level,
  });

  final String name;
  final double level;

  double get percent => (level / 20).clamp(0, 1) * 100;
}

class Project {
  const Project({
    required this.name,
    required this.status,
    required this.finalMark,
    required this.validated,
  });

  final String name;
  final String status;
  final int? finalMark;
  final bool? validated;
}

class Student {
  const Student({
    required this.login,
    required this.email,
    required this.phone,
    required this.imageUrl,
    required this.level,
    required this.location,
    required this.wallet,
    required this.skills,
    required this.projects,
  });

  final String login;
  final String email;
  final String phone;
  final String imageUrl;
  final double level;
  final String location;
  final int wallet;
  final List<Skill> skills;
  final List<Project> projects;

  factory Student.fromJson(Map<String, dynamic> json) {
    final cursusUsers = (json['cursus_users'] as List<dynamic>? ?? []);
    Map<String, dynamic>? selectedCursus;
    for (final cursus in cursusUsers) {
      if (cursus is Map<String, dynamic>) {
        final cursusInfo = cursus['cursus'];
        if (cursusInfo is Map<String, dynamic> && cursusInfo['kind'] == 'main') {
          selectedCursus = cursus;
          break;
        }
      }
    }
    selectedCursus ??=
        cursusUsers.isNotEmpty && cursusUsers.first is Map<String, dynamic>
            ? cursusUsers.first as Map<String, dynamic>
            : null;

    final skillsRaw = (selectedCursus?['skills'] as List<dynamic>? ?? []);
    final skills = skillsRaw
        .whereType<Map<String, dynamic>>()
        .map(
          (skillJson) => Skill(
            name: (skillJson['name'] ?? 'Unknown skill').toString(),
            level: _toDouble(skillJson['level']),
          ),
        )
        .toList();

    final projectsRaw = (json['projects_users'] as List<dynamic>? ?? []);
    final projects = projectsRaw
        .whereType<Map<String, dynamic>>()
        .map((projectUser) {
          final projectInfo =
              (projectUser['project'] as Map<String, dynamic>? ?? const {});
          return Project(
            name: (projectInfo['name'] ?? 'Unknown project').toString(),
            status: (projectUser['status'] ?? 'unknown').toString(),
            finalMark: _toIntOrNull(projectUser['final_mark']),
            validated: projectUser['validated?'] as bool?,
          );
        })
        .toList();

    return Student(
      login: (json['login'] ?? 'unknown').toString(),
      email: (json['email'] ?? '-').toString(),
      phone: (json['phone'] ?? '-').toString(),
      imageUrl: (json['image']?['link'] ?? '').toString(),
      level: _toDouble(selectedCursus?['level']),
      location: (json['location'] ?? 'Unavailable').toString(),
      wallet: _toIntOrNull(json['wallet']) ?? 0,
      skills: skills,
      projects: projects,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static int? _toIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
