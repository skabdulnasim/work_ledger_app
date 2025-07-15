import 'package:hive_flutter/hive_flutter.dart';
import 'package:work_ledger/db_constants.dart';

class DBUserPrefs {
  Box? prefBox;

  Future<void> savePreference(String key, dynamic value) async {
    //Open the PreferenceBox
    await _openPreferenceBox();
    //Saving preference data into PreferenceBox database
    await prefBox!.put(key, value);
    //Close the PreferenceBox
    _closePreferenceBox();
  }

  ///Function to get the saved user preference in database.
  ///[key] -> Unique key to be supplied to get the saved value.
  ///If key not exist then it will return blank string.
  Future<dynamic> getPreference(String key) async {
    //Open the PreferenceBox
    await _openPreferenceBox();
    //Getting value by key.
    dynamic value = prefBox!.get(key, defaultValue: '');
    //Close the PreferenceBox
    _closePreferenceBox();
    //Return the value
    return value;
  }

  ///Open the PreferenceBox
  _openPreferenceBox() async {
    prefBox = await Hive.openBox(BOX_USER_PREFS);
  }

  ///Close the PreferenceBox
  _closePreferenceBox() async {
    //await prefBox!.close();
  }

  Future<void> delete() async {
    prefBox = await Hive.openBox(BOX_USER_PREFS);
    await prefBox!.clear();
    await prefBox!.close();
  }
}
