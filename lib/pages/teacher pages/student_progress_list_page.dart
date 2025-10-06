// import 'package:flutter/material.dart';
//
// class StudentProgressList extends StatelessWidget {
//   final List<Map<String, dynamic>> students;
//
//   const StudentProgressList({super.key, required this.students});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("📚 Student Progress")),
//       body: Column(
//         children: [
//           // Stats Row (scrollable)
//           SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: Row(
//               children: [
//                 _buildStatCard("Avg Reading Time", "120m"),
//                 _buildStatCard("Avg Miscues", "15"),
//                 _buildStatCard("Avg Quiz", "82%"),
//               ],
//             ),
//           ),
//
//           Expanded(
//             child: ListView.builder(
//               itemCount: students.length,
//               itemBuilder: (context, index) {
//                 final s = students[index];
//                 return ListTile(
//                   leading: CircleAvatar(child: Text(s['studentName'][0])),
//                   title: Text(s['studentName']),
//                   subtitle: Text(
//                     "Time: ${s['readingTime']}m | Miscues: ${s['miscues']} | Quiz: ${s['quizAverage']}%",
//                   ),
//                   trailing: Icon(Icons.chevron_right),
//                   onTap: () {
//                     Navigator.push(context,
//                         MaterialPageRoute(builder: (_) => StudentDetailPage(student: s))
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildStatCard(String title, String value) {
//     return Card(
//       margin: EdgeInsets.all(8),
//       child: Padding(
//         padding: EdgeInsets.all(12),
//         child: Column(
//           children: [
//             Text(title, style: TextStyle(fontSize: 12, color: Colors.grey)),
//             SizedBox(height: 6),
//             Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class StudentDetailPage extends StatelessWidget {
//   final Map<String, dynamic> student;
//
//   const StudentDetailPage({super.key, required this.student});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(student['studentName'])),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             // Example chart
//             SizedBox(
//               height: 200,
//               child: LineChart(
//                 LineChartData(
//                   lineBarsData: [
//                     LineChartBarData(
//                       spots: [FlSpot(1, 80), FlSpot(2, 90), FlSpot(3, 70)],
//                       isCurved: true,
//                       dotData: FlDotData(show: true),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             // CRUD Records
//             ListTile(
//               title: Text("Sept 25, 2025"),
//               subtitle: Text("Reading: 45m | Miscues: 2 | Quiz: 88%"),
//               trailing: Icon(Icons.edit),
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         child: Icon(Icons.add),
//         onPressed: () {
//           // Add new record
//         },
//       ),
//     );
//   }
// }
