enum JobStatus {
  assigned,
  inProgress,
  completed,
}

class Job {
  final String id;
  final String customerName;
  final String serviceType;
  final String location;
  JobStatus status;

  Job({
    required this.id,
    required this.customerName,
    required this.serviceType,
    required this.location,
    this.status = JobStatus.assigned,
  });
}
