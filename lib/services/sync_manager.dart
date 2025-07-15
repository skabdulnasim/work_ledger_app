import 'dart:io';

import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:work_ledger/db_constants.dart';
import 'package:work_ledger/db_models/db_company.dart';
import 'package:work_ledger/db_models/db_employee.dart';
import 'package:work_ledger/db_models/db_site.dart';
import 'package:work_ledger/db_models/db_skill.dart';
import 'package:work_ledger/db_models/db_user_prefs.dart';
import 'package:work_ledger/models/company.dart';
import 'package:work_ledger/models/company_bill_payment.dart';
import 'package:work_ledger/models/employee.dart';
import 'package:work_ledger/models/employee_attendance.dart';
import 'package:work_ledger/models/site.dart';
import 'package:work_ledger/models/site_payment_role.dart';
import 'package:work_ledger/models/skill.dart';
import 'package:work_ledger/services/api_constant.dart';
import 'package:work_ledger/services/helper.dart';
import 'package:work_ledger/services/secure_api_service.dart';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';

class SyncManager {
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal();

  final _companyBox = Hive.box<Company>(BOX_COMPANY);
  final _skillBox = Hive.box<Skill>(BOX_SKILL);
  final _siteBox = Hive.box<Site>(BOX_SITE);
  final _companyBillPayBox =
      Hive.box<CompanyBillPayment>(BOX_COMPANY_BILL_PAYMENT);
  final _employeeBox = Hive.box<Employee>(BOX_EMPLOYEE);
  final _employeeAttendanceBox =
      Hive.box<EmployeeAttendance>(BOX_EMPLOYEE_ATTENDANCE);

  Future<void> syncPendingCompanies() async {
    final unsyncedCompanies =
        _companyBox.values.where((company) => !company.isSynced).toList();
    for (final company in unsyncedCompanies) {
      await syncCompanyToServer(company);
    }
  }

  Future<void> syncCompanyToServer(Company company) async {
    try {
      final payload = {
        "company": {
          "name": company.name,
          "address": company.address,
          "mobile_no": company.mobileNo,
          "gstin": company.gstin,
        },
      };

      if (company.serverId != null) {
        final response = await SecureApiService.updateCompany(company);

        if (response != null && response['id'] != null) {
          // Update company with server ID and mark as synced
          company.isSynced = true;

          await company.save(); // Save updated info to Hive
        }
      } else {
        final response = await SecureApiService.createCompany(company);

        if (response != null && response['id'] != null) {
          // Update company with server ID and mark as synced
          company
            ..serverId = response['id'].toString()
            ..isSynced = true;

          await company.save(); // Save updated info to Hive
        }
      }
    } catch (e) {
      print("Background sync failed: $e");
    }
  }

  Future<void> syncCompaniesFromServer() async {
    try {
      final companiesFromServer =
          await SecureApiService.fetchCompaniesFromServer();

      final box = Hive.box<Company>(BOX_COMPANY);
      for (final company in companiesFromServer) {
        final existingCompany = box.values.firstWhereOrNull(
          (c) => c.serverId == company.serverId,
        );

        if (existingCompany != null) {
          // Update existing
          existingCompany
            ..name = company.name
            ..address = company.address
            ..mobileNo = company.mobileNo
            ..gstin = company.gstin
            ..isSynced = true;

          await existingCompany.save();
        } else {
          // Create new
          final newCompany = Company(
            id: "LOCAL-${DateTime.now().microsecondsSinceEpoch}",
            serverId: company.serverId,
            name: company.name,
            address: company.address,
            mobileNo: company.mobileNo,
            gstin: company.gstin,
            isSynced: true,
          );

          await box.add(newCompany);
        }
      }
      await DBUserPrefs().savePreference(
        COMPANY_SYNCED_AT,
        Helper.getCurrentDateTime(),
      );
    } catch (e) {
      print("Failed to sync companies: $e");
    }
  }

  Future<void> syncPendingSkills() async {
    final unsyncedSkills =
        _skillBox.values.where((skill) => !skill.isSynced).toList();
    for (final skill in unsyncedSkills) {
      await syncSkillToServer(skill);
    }
  }

  Future<void> syncSkillToServer(Skill skill) async {
    try {
      final payload = {"employee_role": skill.toJson()};

      if (skill.serverId != null) {
        final response = await SecureApiService.updateSkill(skill);

        if (response != null && response['id'] != null) {
          skill.isSynced = true;

          await skill.save();
        }
      } else {
        final response = await SecureApiService.createSkill(skill);

        if (response != null && response['id'] != null) {
          skill
            ..serverId = response['id'].toString()
            ..isSynced = true;

          await skill.save();
        }
      }
    } catch (e) {
      print("Background sync failed: $e");
    }
  }

  Future<void> syncSkillsFromServer() async {
    try {
      final skillsFromServer = await SecureApiService.fetchSkillsFromServer();

      final box = Hive.box<Skill>(BOX_SKILL);
      for (final skill in skillsFromServer) {
        final existingSkill = box.values.firstWhereOrNull(
          (c) => c.serverId == skill.serverId,
        );

        if (existingSkill != null) {
          // Update existing
          existingSkill
            ..name = skill.name
            ..isSynced = true;

          await existingSkill.save();
        } else {
          // Create new
          final newSkill = Skill(
            id: "LOCAL-${DateTime.now().microsecondsSinceEpoch}",
            serverId: skill.serverId,
            name: skill.name,
            isSynced: true,
          );

          await box.add(newSkill);
        }
      }
      await DBUserPrefs().savePreference(
        EMPLOYEE_ROLE_SYNCED_AT,
        Helper.getCurrentDateTime(),
      );
    } catch (e) {
      print("Failed to sync companies: $e");
    }
  }

  Future<void> syncPendingSites() async {
    final unsyncedSites =
        _siteBox.values.where((site) => !site.isSynced).toList();
    for (final site in unsyncedSites) {
      await syncSiteToServer(site);
    }
  }

  Future<void> syncSiteToServer(Site site) async {
    try {
      Company? siteCompany = DBCompany.find(site.companyId);
      if (siteCompany != null) {
        final payload = {
          "site": {
            "name": site.name,
            "address": site.address,
            "company_id": siteCompany.serverId,
            "site_payment_roles_attributes": site.sitePaymentRoles!.map((tier) {
              Skill? skill = DBSkill.find(tier.skillId); // Fetch the Skill
              if (skill!.serverId != null) {
                return {
                  if (tier.serverId != null) "id": tier.serverId,
                  "employee_role_id": skill.serverId,
                  "daily_wage": tier.dailyWage,
                  "overtime_rate": tier.overtimeRate,
                };
              }
            }).toList(),
          },
        };

        if (site.serverId != null) {
          final response =
              await SecureApiService.updateSite(payload, site.serverId!);

          if (response != null && response['id'] != null) {
            // Update company with server ID and mark as synced
            site.isSynced = true;

            await site.save(); // Save updated info to Hive
          }
        } else {
          final response = await SecureApiService.createSite(payload);

          if (response != null && response['id'] != null) {
            // Update company with server ID and mark as synced
            site
              ..serverId = response['id'].toString()
              ..isSynced = true;

            await site.save(); // Save updated info to Hive
          }
        }
      }
    } catch (e) {
      print("Background sync failed: $e");
    }
  }

  Future<void> syncSitesFromServer() async {
    try {
      final sitesFromServer = await SecureApiService.fetchSitesFromServer();
      final box = Hive.box<Site>(BOX_SITE);
      for (final site in sitesFromServer) {
        final existingSite = box.values.firstWhereOrNull(
          (c) => c.serverId == site['id'],
        );

        if (existingSite != null) {
          // Update existing
          final companyServerId = site['company_id'].toString();
          final localCompany = DBCompany.byServerId(companyServerId);

          List<SitePaymentRole> sitePaymentRoles = [];
          for (var sprE in site['site_payment_roles']) {
            final skillServerId = sprE['employee_role_id'].toString();
            final localSkill = DBSkill.byServerId(skillServerId);
            SitePaymentRole spr = SitePaymentRole(
              skillId: localSkill!.id!,
              dailyWage: double.parse(sprE['daily_wage'].toString()),
              overtimeRate: double.parse(
                sprE['overtime_rate'].toString(),
              ),
            );
            sitePaymentRoles.add(spr);
          }

          existingSite
            ..name = site['name']
            ..address = site['address']
            ..companyId = localCompany!.id!
            ..sitePaymentRoles = sitePaymentRoles
            ..isSynced = true;

          await existingSite.save();
        } else {
          // Create new
          final companyServerId = site['company_id'].toString();
          final localCompany = DBCompany.byServerId(companyServerId);

          List<SitePaymentRole> sitePaymentRoles = [];
          for (var sprE in site['site_payment_roles']) {
            final skillServerId = sprE['employee_role_id'].toString();
            final localSkill = DBSkill.byServerId(skillServerId);
            SitePaymentRole spr = SitePaymentRole(
              skillId: localSkill!.id!,
              dailyWage: double.parse(sprE['daily_wage'].toString()),
              overtimeRate: double.parse(
                sprE['overtime_rate'].toString(),
              ),
            );
            sitePaymentRoles.add(spr);
          }

          final newSite = Site(
            id: "LOCAL-${DateTime.now().microsecondsSinceEpoch}",
            serverId: site['id'].toString(),
            name: site['name'],
            address: site['address'],
            companyId: localCompany!.id!,
            sitePaymentRoles: sitePaymentRoles,
            isSynced: true,
          );

          await box.add(newSite);
        }
      }
      await DBUserPrefs().savePreference(
        SITE_SYNCED_AT,
        Helper.getCurrentDateTime(),
      );
    } catch (e) {
      print("Failed to sync sites: $e");
    }
  }

  Future<void> syncPendingCompanyBillPayments() async {
    final unsyncedBills =
        _companyBillPayBox.values.where((bill) => !bill.isSynced).toList();
    for (final bill in unsyncedBills) {
      await syncCompanyBillPaymentToServer(bill);
    }
  }

  Future<void> syncCompanyBillPaymentToServer(
      CompanyBillPayment billPay) async {
    final response = await SecureApiService.createCompanyBillPayment(billPay);

    if (response != null && response['id'] != null) {
      billPay
        ..serverId = response['id'].toString()
        ..isSynced = true;

      await billPay.save();
    }
  }

  Future<void> syncComBillPayFromServer() async {
    try {
      final comBillFromServer =
          await SecureApiService.fetchCompanyBillPaymentsFromServer();
      final box = Hive.box<CompanyBillPayment>(BOX_COMPANY_BILL_PAYMENT);
      for (final cBillPay in comBillFromServer) {
        final existing = box.values.firstWhereOrNull(
          (c) => c.serverId == cBillPay['id'],
        );

        if (existing != null) {
          // Update existing
          final siteServerId = cBillPay['site_id'].toString();
          final localSite = DBSite.byServerId(siteServerId);

          final List<String> attachmentsDownloadedPaths = [];
          final sAttachments = cBillPay['attachments'] as List<dynamic>;
          for (final attachment in sAttachments) {
            final filename = attachment['filename'];
            final relativeUrl = attachment['url'];
            final fullUrl = "$BASE_PATH$relativeUrl";

            try {
              final response = await http.get(Uri.parse(fullUrl));
              if (response.statusCode == 200) {
                final dir = await getApplicationDocumentsDirectory();
                final localFile = File('${dir.path}/$filename');

                await localFile.writeAsBytes(response.bodyBytes);
                attachmentsDownloadedPaths.add(localFile.path);
              }
            } catch (e) {
              print("Error downloading $filename: $e");
            }
          }

          existing
            ..amount = double.tryParse(cBillPay['amount']) ?? 0.0
            ..transactionAt =
                Helper.getStringToDateTime(cBillPay['transaction_at'])
            ..billNo = cBillPay['bill_no']
            ..paymentMode = cBillPay['payment_mode']
            ..transactionType = cBillPay['transaction_type']
            ..remarks = cBillPay['remarks'] ?? ''
            ..siteId = localSite!.id!
            ..isSynced = true
            ..attachmentPaths = [...attachmentsDownloadedPaths];

          await existing.save();
        } else {
          // Create new
          final siteServerId = cBillPay['site_id'].toString();
          final localSite = DBSite.byServerId(siteServerId);

          final List<String> attachmentsDownloadedPaths = [];
          final sAttachments = cBillPay['attachments'] as List<dynamic>;
          for (final attachment in sAttachments) {
            final filename = attachment['filename'];
            final relativeUrl = attachment['url'];
            final fullUrl = "$BASE_PATH$relativeUrl";

            try {
              final response = await http.get(Uri.parse(fullUrl));
              if (response.statusCode == 200) {
                final dir = await getApplicationDocumentsDirectory();
                final localFile = File('${dir.path}/$filename');

                await localFile.writeAsBytes(response.bodyBytes);
                attachmentsDownloadedPaths.add(localFile.path);
              }
            } catch (e) {
              print("Error downloading $filename: $e");
            }
          }

          final newPayment = CompanyBillPayment(
            id: "LOCAL-${DateTime.now().microsecondsSinceEpoch}",
            transactionAt:
                Helper.getStringToDateTime(cBillPay['transaction_at']),
            billNo: cBillPay['bill_no'],
            amount: double.tryParse(cBillPay['amount']) ?? 0.0,
            paymentMode: cBillPay['payment_mode'],
            transactionType: cBillPay['transaction_type'],
            remarks: cBillPay['remarks'] ?? '',
            siteId: localSite!.id!,
            attachmentPaths: [...attachmentsDownloadedPaths],
            serverId: cBillPay['is'].toString(),
            isSynced: true,
          );

          await box.add(newPayment);
        }
      }
      await DBUserPrefs().savePreference(
        COMPANY_BILL_PAY_SYNCED_AT,
        Helper.getCurrentDateTime(),
      );
    } catch (e) {
      print("Failed to sync company bill pay: $e");
    }
  }

  Future<void> syncPendingEmployees() async {
    final unsyncedEmployees =
        _employeeBox.values.where((employee) => !employee.isSynced).toList();
    for (final employee in unsyncedEmployees) {
      await syncEmployeeToServer(employee);
    }
  }

  Future<void> syncEmployeeToServer(Employee employee) async {
    try {
      Skill? skill = DBSkill.find(employee.skillId);
      final payload = {
        "employee": {
          "name": employee.name,
          "address": employee.address,
          "mobile_no": employee.mobileNo,
          "employee_role_id": skill!.serverId,
        },
      };

      if (employee.serverId != null) {
        final response =
            await SecureApiService.updateEmployee(payload, employee.serverId!);

        if (response != null && response['id'] != null) {
          // Update company with server ID and mark as synced
          employee.isSynced = true;

          await employee.save(); // Save updated info to Hive
        }
      } else {
        final response = await SecureApiService.createEmployee(payload);

        if (response != null && response['id'] != null) {
          // Update company with server ID and mark as synced
          employee
            ..serverId = response['id'].toString()
            ..isSynced = true;

          await employee.save(); // Save updated info to Hive
        }
      }
    } catch (e) {
      print("Background sync failed: $e");
    }
  }

  Future<void> syncEmployeesFromServer() async {
    try {
      final employeesFromServer =
          await SecureApiService.fetchEmployeeFromServer();
      final box = Hive.box<Employee>(BOX_EMPLOYEE);
      for (final employee in employeesFromServer) {
        final existingEmployee = box.values.firstWhereOrNull(
          (c) => c.serverId == employee['id'],
        );

        if (existingEmployee != null) {
          // Update existing
          final skillServerId = employee['employee_role_id'].toString();
          final localSkill = DBSkill.byServerId(skillServerId);

          existingEmployee
            ..name = employee['name']
            ..address = employee['address']
            ..mobileNo = employee['mobile_no']
            ..skillId = localSkill!.id!
            ..isSynced = true;

          await existingEmployee.save();
        } else {
          // Create new
          final skillServerId = employee['employee_role_id'].toString();
          final localSkill = DBSkill.byServerId(skillServerId);

          final newEmployee = Employee(
            id: "LOCAL-${DateTime.now().microsecondsSinceEpoch}",
            serverId: employee['id'].toString(),
            name: employee['name'],
            address: employee['address'],
            mobileNo: employee['mobile_no'],
            skillId: localSkill!.id!,
            isSynced: true,
          );

          await box.add(newEmployee);
        }
      }
      await DBUserPrefs().savePreference(
        EMPLOYEE_SYNCED_AT,
        Helper.getCurrentDateTime(),
      );
    } catch (e) {
      print("Failed to sync employees: $e");
    }
  }

  Future<void> syncEmployeeAttendancesFromServer() async {
    try {
      final employeeAttendancesFromServer =
          await SecureApiService.fetchEmployeeAttendanceFromServer();
      final box = Hive.box<EmployeeAttendance>(BOX_EMPLOYEE_ATTENDANCE);
      for (final attendance in employeeAttendancesFromServer) {
        final existingAttendance = box.values.firstWhereOrNull(
          (c) => c.serverId == attendance['id'],
        );

        if (existingAttendance != null) {
          // Update existing
          final employeeServerId = attendance['employee_id'].toString();
          final localEmployee = DBEmployee.byServerId(employeeServerId);
          final siteServerId = attendance['site_id'].toString();
          final localSite = DBSite.byServerId(siteServerId);

          existingAttendance
            ..employeeId = localEmployee!.id!
            ..siteId = localSite!.id!
            ..date = DateTime.parse(attendance['date'])
            ..overtimeCount = attendance['overtime_count']
            ..isAbsence = attendance['is_absence']
            ..isFullDay = attendance['is_full_day']
            ..isHalfDay = attendance['is_half_day']
            ..remarks = attendance['remarks']
            ..isSynced = true;

          await existingAttendance.save();
        } else {
          // Create new
          final employeeServerId = attendance['employee_id'].toString();
          final localEmployee = DBEmployee.byServerId(employeeServerId);
          final siteServerId = attendance['site_id'].toString();
          final localSite = DBSite.byServerId(siteServerId);

          final newAttendance = EmployeeAttendance(
            id: "LOCAL-${DateTime.now().microsecondsSinceEpoch}",
            serverId: attendance['id'].toString(),
            siteId: localSite!.id!,
            employeeId: localEmployee!.id!,
            date: DateTime.parse(attendance['date']),
            overtimeCount: attendance['overtime_count'],
            isAbsence: attendance['is_absence'],
            isFullDay: attendance['is_full_day'],
            isHalfDay: attendance['is_half_day'],
            remarks: attendance['remarks'],
            isSynced: true,
          );

          await box.add(newAttendance);
        }
      }
      await DBUserPrefs().savePreference(
        EMPLOYEE_ATTENDANCE_SYNCED_AT,
        Helper.getCurrentDateTime(),
      );
    } catch (e) {
      print("Failed to sync employees: $e");
    }
  }

  Future<void> syncPendingEmployeeAttendances() async {
    final unsyncedEmployeeAttendances = _employeeAttendanceBox.values
        .where((attendance) => !attendance.isSynced)
        .toList();
    for (final attendance in unsyncedEmployeeAttendances) {
      await syncEmployeeAttendanceToServer(attendance);
    }
  }

  Future<void> syncEmployeeAttendanceToServer(
      EmployeeAttendance attendance) async {
    try {
      final localEmployee = DBEmployee.byServerId(attendance.employeeId);
      final localSite = DBSite.byServerId(attendance.siteId);
      final payload = {
        "employee_attendance": {
          "employee_id": localEmployee!.serverId!,
          "site_id": localSite!.serverId!,
          "date": Helper.getFullDateTime(attendance.date),
          "overtime_count": attendance.overtimeCount,
          "is_half_day": attendance.isHalfDay,
          "is_full_day": attendance.isFullDay,
          "is_absence": attendance.isAbsence,
          "remarks": attendance.remarks,
        },
      };

      if (attendance.serverId != null) {
        final response = await SecureApiService.updateEmployeeAttendance(
            payload, attendance.serverId!);

        if (response != null && response['id'] != null) {
          // Update company with server ID and mark as synced
          attendance.isSynced = true;

          await attendance.save(); // Save updated info to Hive
        }
      } else {
        final response =
            await SecureApiService.createEmployeeAttendance(payload);

        if (response != null && response['id'] != null) {
          // Update company with server ID and mark as synced
          attendance
            ..serverId = response['id'].toString()
            ..isSynced = true;

          await attendance.save(); // Save updated info to Hive
        }
      }
    } catch (e) {
      print("Background sync failed: $e");
    }
  }
}
