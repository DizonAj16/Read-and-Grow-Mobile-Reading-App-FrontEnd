import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class TasksPage extends StatelessWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/animation/empty_box.json', // Use your task-related animation
                    width: 200,
                    height: 200,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "No Tasks Available",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      "Create your first task by tapping the + button below",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14, 
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Task creation coming soon...")),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}