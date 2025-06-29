import 'package:flutter/material.dart';

class DayOneStoryPage extends StatelessWidget {
  const DayOneStoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text('Nick and the Puppy'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Instruction Container
          Container(
            padding: const EdgeInsets.all(20.0),
            margin: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.lightBlue[50],
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Text(
              'Read the text and then answer the questions.',
              style: TextStyle(fontSize: 18, height: 1.5),
              textAlign: TextAlign.justify,
            ),
          ),

          // Scrollable Story Container
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Ever since he was six years old, Nick had wanted to get a puppy. His parents always refused. '
                        'They said he wasn’t capable of taking care of a puppy. “You have no idea how much work a puppy is,” Dad said. '
                        '“You would have to housebreak the puppy, train the puppy to obey you, and groom it, too.”',
                        style: TextStyle(fontSize: 18, height: 1.8),
                        textAlign: TextAlign.justify,
                      ),
                      SizedBox(height: 16),
                      Text(
                        '“And then there’s taking the puppy to the vet, playing with it, and feeding it,” Mom added. '
                        '“It’s not that I’m against having a puppy. But a puppy takes up a lot of time.”',
                        style: TextStyle(fontSize: 18, height: 1.8),
                        textAlign: TextAlign.justify,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Nick couldn’t think of a way that he could convince his parents that he was ready for a puppy. '
                        'Then, he got an idea. “If I volunteer at the animal shelter,” he thought, “I’ll bet Mom and Dad will see that I’m ready to take care of a puppy!”',
                        style: TextStyle(fontSize: 18, height: 1.8),
                        textAlign: TextAlign.justify,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Copyright
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 10.0, bottom: 20.0),
              child: Text(
                "© K5 Learning 2019",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.grey[200],
    );
  }
}
