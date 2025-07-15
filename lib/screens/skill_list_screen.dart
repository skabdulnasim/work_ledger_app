import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:work_ledger/db_models/db_skill.dart';
import 'package:work_ledger/screens/skill_screen.dart';
import 'package:work_ledger/widgets/bottom_nav.dart';
import 'package:work_ledger/models/skill.dart';

class SkillListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Skill")),
      body: ValueListenableBuilder(
        valueListenable: DBSkill.getListenable(),
        builder: (context, Box<Skill> box, _) {
          final skills = box.values.toList();

          if (skills.isEmpty) {
            return Center(child: Text("No skills found"));
          }

          return ListView.builder(
            itemCount: skills.length,
            itemBuilder: (context, index) {
              final skill = skills[index];
              return ListTile(
                title: Text("${skill.name.toString()}"),
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SkillScreen(skill: skill),
                    ),
                  );
                },
              );
            },
          );
        },
      ),

      /// ✅ FAB to Add New Company
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Create a blank company object (with a UUID)
          final newSkill = Skill(
            id: "LOCAL-${DateTime.now().millisecondsSinceEpoch.toString()}", // or UUID
            name: '',
          );

          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SkillScreen(skill: newSkill)),
          );

          if (result == true) {
            (context as Element).reassemble(); // Refresh after adding
          }
        },
        child: Icon(Icons.add),
        tooltip: "Add Skill",
      ),

      bottomNavigationBar: BottomNav(currentIndex: 2),
    );
  }
}
