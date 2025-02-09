class Resume {
  String fullName;
  String email;
  String phone;
  List<String> address;
  String summary;
  List<String> skills;
  List<Experience> experiences;
  List<Education> educations;
  String imageUrl;

  Resume(
      {required this.fullName,
      required this.email,
      required this.phone,
      required this.address,
      required this.summary,
      required this.skills,
      required this.experiences,
      required this.educations,
      required this.imageUrl});
}

class Experience {
  String company;
  String position;
  String start_date;
  String end_date;
  String description;

  Experience({
    required this.company,
    required this.position,
    required this.start_date,
    required this.end_date,
    required this.description,
  });
}

class Education {
  String institution;
  String degree;
  String start_date;
  String end_date;
  String course;

  Education(
      {required this.institution,
      required this.degree,
      required this.start_date,
      required this.end_date,
      required this.course});
}
