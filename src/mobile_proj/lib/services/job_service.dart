import '../models/job.dart';

class JobService {
  static final JobService _instance = JobService._internal();
  factory JobService() => _instance;
  JobService._internal();

  final List<Job> _jobs = [];

  List<Job> get jobs => List.unmodifiable(_jobs);

  void addJob(Job job) {
    _jobs.add(job);
  }

  void updateJobStatus(String jobId, JobStatus newStatus) {
    final index = _jobs.indexWhere((j) => j.id == jobId);
    if (index != -1) {
      _jobs[index].status = newStatus;
    }
  }

  Job? getJobById(String jobId) {
    try {
      return _jobs.firstWhere((j) => j.id == jobId);
    } catch (e) {
      return null;
    }
  }
}
