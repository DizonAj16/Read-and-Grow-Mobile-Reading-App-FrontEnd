import 'package:flutter/material.dart';

class DayThreeStoryPage extends StatelessWidget {
  const DayThreeStoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text('Nick and the Animal Shelter'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Instruction Box
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

          // Scrollable Story Box
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
                        'Nick volunteered at the animal shelter for three months. He learned a great deal '
                        'about raising puppies and training them. Every time he learned something new, he practiced it. '
                        'He also told his parents about what he was learning. He wanted to persuade them that he could be trusted '
                        'with a puppy of his own.',
                        style: TextStyle(fontSize: 18, height: 1.8),
                        textAlign: TextAlign.justify,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'One afternoon, Dad picked Nick up from volunteering and asked him how the day went.\n\n'
                        '“Oh, it went great,” Nick answered enthusiastically. “They even let me help introduce the dogs to people who want to adopt them!”\n\n'
                        '“That’s terrific!” Dad answered with a grin. “I’m so glad you’re getting this experience. You’ll need it for our new puppy!”\n\n'
                        '“We’re getting a puppy?” Nick practically shouted. “That’s awesome! I can’t wait!”',
                        style: TextStyle(fontSize: 18, height: 1.8),
                        textAlign: TextAlign.justify,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Footer
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
