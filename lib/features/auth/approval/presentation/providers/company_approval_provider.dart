import 'package:fieldguard/features/auth/approval/data/datasource/company_approval_datasource.dart';
import 'package:fieldguard/features/auth/approval/data/datasource/company_approval_datasource_impl.dart';
import 'package:fieldguard/features/auth/login/presentation/providers/login_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final companyApprovalDataSourceProvider = Provider<CompanyApprovalDataSource>(
  (ref) => CompanyApprovalDatasourceImpl(ref.watch(dioProvider)),
);
