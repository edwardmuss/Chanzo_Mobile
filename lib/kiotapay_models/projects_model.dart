class ProjectsModel {
  String? msg;
  List<Project>? data;

  ProjectsModel({this.msg, this.data});

  ProjectsModel.fromJson(Map<String, dynamic> json) {
    msg = json['msg'];
    if (json['data'] != null) {
      data = <Project>[];
      json['data'].forEach((v) {
        data!.add(new Project.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['msg'] = this.msg;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Project {
  int? id;
  String? uuid;
  String? projectName;
  String? linkOrganisation;
  String? description;
  String? createdBy;
  bool? isActive;
  int? projectEstAmount;
  int? projectAmount;
  String? status;
  String? createdAt;
  String? updatedAt;
  List<Teams>? teams;

  Project(
      {this.id,
        this.uuid,
        this.projectName,
        this.linkOrganisation,
        this.description,
        this.createdBy,
        this.isActive,
        this.projectEstAmount,
        this.projectAmount,
        this.status,
        this.createdAt,
        this.updatedAt,
        this.teams});

  Project.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    uuid = json['uuid'];
    projectName = json['project_name'];
    linkOrganisation = json['link_organisation'];
    description = json['description'];
    createdBy = json['created_by'];
    isActive = json['isActive'];
    projectEstAmount = json['project_est_amount'];
    projectAmount = json['project_amount'];
    status = json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    if (json['teams'] != null) {
      teams = <Teams>[];
      json['teams'].forEach((v) {
        teams!.add(new Teams.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['uuid'] = this.uuid;
    data['project_name'] = this.projectName;
    data['link_organisation'] = this.linkOrganisation;
    data['description'] = this.description;
    data['created_by'] = this.createdBy;
    data['isActive'] = this.isActive;
    data['project_est_amount'] = this.projectEstAmount;
    data['project_amount'] = this.projectAmount;
    data['status'] = this.status;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    if (this.teams != null) {
      data['teams'] = this.teams!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Teams {
  int? id;
  String? uuid;
  String? name;
  String? description;
  String? linkProject;
  String? createdBy;
  String? linkOrganisation;
  bool? isAdmin;
  bool? isActive;
  int? teamLimit;
  int? teamSpentAmount;
  String? createdAt;
  String? updatedAt;

  Teams(
      {this.id,
        this.uuid,
        this.name,
        this.description,
        this.linkProject,
        this.createdBy,
        this.linkOrganisation,
        this.isAdmin,
        this.isActive,
        this.teamLimit,
        this.teamSpentAmount,
        this.createdAt,
        this.updatedAt});

  Teams.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    uuid = json['uuid'];
    name = json['name'];
    description = json['description'];
    linkProject = json['link_project'];
    createdBy = json['created_by'];
    linkOrganisation = json['link_organisation'];
    isAdmin = json['isAdmin'];
    isActive = json['isActive'];
    teamLimit = json['team_limit'];
    teamSpentAmount = json['team_spent_amount'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['uuid'] = this.uuid;
    data['name'] = this.name;
    data['description'] = this.description;
    data['link_project'] = this.linkProject;
    data['created_by'] = this.createdBy;
    data['link_organisation'] = this.linkOrganisation;
    data['isAdmin'] = this.isAdmin;
    data['isActive'] = this.isActive;
    data['team_limit'] = this.teamLimit;
    data['team_spent_amount'] = this.teamSpentAmount;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}
