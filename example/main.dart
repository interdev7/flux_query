import 'package:flutter/material.dart';
import 'package:flux_query/flux_query.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FluxQueryProvider(client: FluxQueryClient(), child: MaterialApp(title: 'Flux Query Demo', theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true), home: const HomePage()));
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flux Query Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Todo Example', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(child: TodoListExample()),
            const SizedBox(height: 20),
            Expanded(child: AddTodoExample()),
          ],
        ),
      ),
    );
  }
}

class TodoListExample extends StatelessWidget {
  const TodoListExample({super.key});

  Future<List<Todo>> fetchTodos() async {
    final response = await http.get(Uri.parse('https://jsonplaceholder.typicode.com/todos?_limit=10'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Todo.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load todos');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FluxQueryBuilder<List<Todo>>(
      queryKey: 'todos',
      queryFn: fetchTodos,
      staleTime: const Duration(minutes: 1),
      cacheTime: const Duration(minutes: 5),
      builder: (context, query) {
        if (query.isLoading && !query.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (query.hasError && !query.hasData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Text('Error: ${query.error}'), const SizedBox(height: 16), ElevatedButton(onPressed: query.refetch, child: const Text('Try Again'))],
            ),
          );
        }

        final todos = query.data ?? [];

        return Column(
          children: [
            if (query.isLoading) const Padding(padding: EdgeInsets.all(8.0), child: LinearProgressIndicator()),
            if (query.isStale && !query.isLoading) const Padding(padding: EdgeInsets.all(8.0), child: Text('Data is stale. Refreshing...')),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(onPressed: query.refetch, child: const Text('Refresh')),
                  ElevatedButton(
                    onPressed: () {
                      final client = FluxQueryProvider.of(context);
                      client.invalidateQuery('todos');
                    },
                    child: const Text('Invalidate Cache'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: todos.length,
                itemBuilder: (context, index) {
                  final todo = todos[index];
                  return TodoItem(todo: todo);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class TodoItem extends StatelessWidget {
  final Todo todo;

  const TodoItem({super.key, required this.todo});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: todo.completed ? Colors.green : Colors.orange, child: Text(todo.id.toString())),
        title: Text(todo.title),
        subtitle: Text('User ID: ${todo.userId}'),
        trailing: Icon(todo.completed ? Icons.check_circle : Icons.circle_outlined, color: todo.completed ? Colors.green : Colors.orange),
      ),
    );
  }
}

class Todo {
  final int id;
  final int userId;
  final String title;
  final bool completed;

  Todo({required this.id, required this.userId, required this.title, required this.completed});

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(id: json['id'], userId: json['userId'], title: json['title'], completed: json['completed']);
  }
}

class AddTodoExample extends StatefulWidget {
  const AddTodoExample({super.key});

  @override
  State<AddTodoExample> createState() => _AddTodoExampleState();
}

class _AddTodoExampleState extends State<AddTodoExample> {
  final TextEditingController _controller = TextEditingController();
  bool _simulateError = false;

  Future<Todo> addTodo(String title) async {
    await Future.delayed(const Duration(seconds: 1));
    if (_simulateError) {
      throw Exception('Ошибка при добавлении задачи');
    }
    return Todo(id: DateTime.now().millisecondsSinceEpoch, userId: 1, title: title, completed: false);
  }

  @override
  Widget build(BuildContext context) {
    return MutationBuilder<Todo, String>(
      mutationFn: addTodo,
      builder: (context, mutation) {
        return Column(
          children: [
            TextField(controller: _controller, decoration: const InputDecoration(labelText: 'New Todo')),
            Row(children: [Checkbox(value: _simulateError, onChanged: (v) => setState(() => _simulateError = v ?? false)), const Text('Симулировать ошибку')]),
            ElevatedButton(
              onPressed:
                  mutation.isLoading
                      ? null
                      : () async {
                        try {
                          final todo = await mutation.mutate(_controller.text);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Добавлено: ${todo.title}')));
                          _controller.clear();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
                        }
                      },
              child: mutation.isLoading ? const CircularProgressIndicator() : const Text('Добавить Todo'),
            ),
            if (mutation.hasError) Padding(padding: const EdgeInsets.all(8.0), child: Text('Ошибка: ${mutation.error}', style: const TextStyle(color: Colors.red))),
          ],
        );
      },
    );
  }
}
