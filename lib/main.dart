import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todo_app/repo/task_repository.dart';
import 'package:todo_app/widgets/task.dart';

import 'bloc/tasks_bloc.dart';
import 'model/task.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ToDo M-You App',
      theme: ThemeData(
          useMaterial3: true,
          primaryColor: const Color(0XFFceef86),
          ),
      home: RepositoryProvider(
        create: (context) => TaskRepository(),
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
                create: (context) => TasksBloc(
                  RepositoryProvider.of<TaskRepository>(context),
                )..add(LoadTask()))
          ],
          child: MyHomePage(title: 'Tasks List'),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late TextEditingController textInputTitleController;
  late TextEditingController textInputUserIdController;

  @override
  void initState() {
    super.initState();

    textInputTitleController = TextEditingController();
    textInputUserIdController = TextEditingController();
  }

  @override
  void dispose() {
    textInputTitleController.dispose();
    textInputUserIdController.dispose();
    super.dispose();
  }

  Future<Task?> _openDialog(int lastId) {
    textInputTitleController.text = '';
    textInputUserIdController.text = '';
    return showDialog<Task>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0XFFfeddaa),
          title: TextField(
              controller: textInputTitleController,
              decoration: const InputDecoration(

                  hintText: 'Task Title',
                  filled: true,
                  border: InputBorder.none)
          ),
          content: TextField(
              controller: textInputUserIdController,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly
              ],
              decoration: const InputDecoration(
                  hintText: 'User ID',
                  border: InputBorder.none,
                  filled: true)),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                )),
            TextButton(
                onPressed: (() {
                  if (textInputTitleController.text != '' &&
                      textInputUserIdController.text != '') {
                    Navigator.of(context).pop(Task(
                        id: lastId + 1,
                        userId: int.parse(textInputUserIdController.text),
                        title: textInputTitleController.text));
                  }
                }),
                child: const Text('Add',
                    style: TextStyle(color: Color(0xFF322a1d))))
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    int? lastId;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          widget.title,
          style:
          const TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
      ),
      body: BlocBuilder<TasksBloc, TasksState>(
        builder: (context, state) {
          if (state is TasksLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (state is TasksLoaded) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    ...state.tasks.map(
                          (task) => InkWell(
                        onTap: (() {
                          context.read<TasksBloc>().add(UpdateTask(
                              task:
                              task.copyWith(isComplete: !task.isComplete)));
                        }),
                        child: TaskWidget(
                          task: task,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 80,
                    )
                  ],
                ),
              ),
            );
          } else {
            return Center(child: const Text('No Task Found'));
          }
        },
      ),
      floatingActionButton: BlocListener<TasksBloc, TasksState>(
        listener: (context, state) {
          if (state is TasksLoaded) {
            lastId = state.tasks.last.id;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Task Updated!'),
            ));
          }
        },
        child: FloatingActionButton(
          backgroundColor: const Color(0xFFf8bd47),
          foregroundColor: const Color(0xFF322a1d),
          onPressed: () async {
            Task? task = await _openDialog(lastId ?? 0);
            if (task != null) {
              context.read<TasksBloc>().add(
                AddTask(task: task),
              );
            }
          },
          tooltip: 'Add Task',
          child: const Icon(Icons.add),
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}