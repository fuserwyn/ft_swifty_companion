import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/student.dart';
import '../services/intra_api_service.dart';
import 'profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.apiService});

  final IntraApiService apiService;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _loginController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _loginController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final Student student = await widget.apiService.fetchStudentByLogin(
        _loginController.text,
      );

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ProfileScreen(student: student),
        ),
      );
    } on AppError catch (error) {
      setState(() => _errorText = error.message);
    } catch (_) {
      setState(() => _errorText = 'Unexpected error. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Profiler')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth.clamp(320.0, 560.0);
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: width),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: SizedBox(
                              width: 100,
                              height: 100,
                              child: Image.asset(
                                'assets/icons/app_icon.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (kIsWeb) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.amber.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: const Text(
                                    'Web mode can fail due to browser CORS restrictions. '
                                    'Use Android/iOS run for full API test.',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                              Text(
                                'Search a 42 student by login',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _loginController,
                                decoration: const InputDecoration(
                                  labelText: 'Login',
                                  prefixIcon: Icon(Icons.search),
                                ),
                                textInputAction: TextInputAction.search,
                                onSubmitted: (_) => _search(),
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: _isLoading ? null : _search,
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.person_search),
                                label: Text(
                                  _isLoading ? 'Searching...' : 'Search',
                                ),
                              ),
                              if (_errorText != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  _errorText!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
