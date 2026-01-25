class ApiConfig {
  // IMPORTANT: Change this based on your server setup!
  // - MAMP (Mac): 'http://10.0.2.2:8888/api'
  // - XAMPP: 'http://10.0.2.2/api' (port 80) or 'http://10.0.2.2:8080/api' (port 8080)
  // - Physical Device: 'http://YOUR_IP_ADDRESS/api' (e.g., 'http://192.168.1.100/api')
  static const String baseUrl = 'http://10.0.2.2:8888/api';

  static String get registerUrl => '$baseUrl/register.php';
  static String get loginUrl => '$baseUrl/login.php';
  static String get completeRegistrationUrl => '$baseUrl/complete_registration.php';
  static String get verifyPasswordUrl => '$baseUrl/verify_password.php';
  static String get changePasswordUrl => '$baseUrl/change_password.php';
  static String get getAllVehiclesUrl => '$baseUrl/get_all_vehicles.php';
  static String get createVehicleUrl => '$baseUrl/create_vehicle.php';
  static String get updateVehicleUrl => '$baseUrl/update_vehicle.php';
  static String get employeeCreateUrl => '$baseUrl/employee_create.php';
  static String get teamCreateUrl => '$baseUrl/team_create.php';
  static String get teamsListUrl => '$baseUrl/teams_list.php';
  static String get employeeJobsUrl => '$baseUrl/employee_jobs.php';
  static String get bookingGetDetailsUrl => '$baseUrl/booking_get_details.php';
  static String get bookingUpdateStatusUrl => '$baseUrl/booking_update_status.php';
  static String get customerBookingsUrl => '$baseUrl/customer_bookings.php';
  static String get submitRatingUrl => '$baseUrl/submit_rating.php';
  static String get getCurrentBookingsUrl => '$baseUrl/get_current_bookings.php';
  static String get getPastBookingsUrl => '$baseUrl/get_past_bookings.php';
  static String get ratingFeedbackUrl => '$baseUrl/rating_feedback.php';
  static String get createBookingUrl => '$baseUrl/create_booking.php';
  static String get deleteVehicleUrl => '$baseUrl/delete_vehicle.php';
  static String get getWalletUrl => '$baseUrl/get_wallet.php';
  static String get convertPointsUrl => '$baseUrl/convert_points.php';
  static String get addPointsUrl => '$baseUrl/add_points.php';
  static String get managerStatsUrl => '$baseUrl/manager_stats.php';
  static String get managerRecentActivitiesUrl => '$baseUrl/manager_recent_activities.php';
  static String get servicesListUrl => '$baseUrl/services_list.php';
  static String get servicesCreateUrl => '$baseUrl/services_create.php';
  static String get servicesUpdateUrl => '$baseUrl/services_update.php';
  static String get servicesDeleteUrl => '$baseUrl/services_delete.php';
  static String get teamUpdateUrl => '$baseUrl/team_update.php';
  static String get employeesListUrl => '$baseUrl/employees_list.php';
  static String get employeeUpdateStatusUrl => '$baseUrl/employee_update_status.php';
  static String get managerBookingsUrl => '$baseUrl/manager_bookings.php';
  static String get allBookingsForEmployeesUrl => '$baseUrl/get_all_bookings_for_employees.php';
  static String get servicesListAllUrl => '$baseUrl/services_list_all.php';
  static String get createDefaultServicesUrl => '$baseUrl/create_default_services.php';
  static String get companyCarsListUrl => '$baseUrl/company_cars_list.php';
  static String get companyCarsCreateUrl => '$baseUrl/company_cars_create.php';
  static String get companyCarsUpdateUrl => '$baseUrl/company_cars_update.php';
  static String get companyCarsDeleteUrl => '$baseUrl/company_cars_delete.php';
  static String get teamDeleteUrl => '$baseUrl/team_delete.php';
  static String get teamMembersAddUrl => '$baseUrl/team_members_add.php';
  static String get teamMembersRemoveUrl => '$baseUrl/team_members_remove.php';
  static String get teamMembersListUrl => '$baseUrl/team_members_list.php';

  static String getApiUrl(String endpoint) => '$baseUrl/$endpoint';
}
