class CategoryModel {
  String? msg;
  List<Data>? data;

  CategoryModel({this.msg, this.data});

  CategoryModel.fromJson(Map<String, dynamic> json) {
    msg = json['msg'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(new Data.fromJson(v));
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

class Data {
  int? id;
  String? uuid;
  String? categoryName;
  String? linkOrganisation;
  String? createdBy;
  String? updatedBy;
  String? createdAt;
  String? updatedAt;
  List<SubCategories>? subCategories;

  Data(
      {this.id,
        this.uuid,
        this.categoryName,
        this.linkOrganisation,
        this.createdBy,
        this.updatedBy,
        this.createdAt,
        this.updatedAt,
        this.subCategories});

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    uuid = json['uuid'];
    categoryName = json['categoryName'];
    linkOrganisation = json['link_organisation'];
    createdBy = json['created_by'];
    updatedBy = json['updated_by'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    if (json['subCategories'] != null) {
      subCategories = <SubCategories>[];
      json['subCategories'].forEach((v) {
        subCategories!.add(new SubCategories.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['uuid'] = this.uuid;
    data['categoryName'] = this.categoryName;
    data['link_organisation'] = this.linkOrganisation;
    data['created_by'] = this.createdBy;
    data['updated_by'] = this.updatedBy;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    if (this.subCategories != null) {
      data['subCategories'] =
          this.subCategories!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class SubCategories {
  int? id;
  String? uuid;
  String? linkCategory;
  String? subCategoryName;
  String? linkOrganisation;
  String? createdBy;
  String? updatedBy;
  String? createdAt;
  String? updatedAt;

  SubCategories(
      {this.id,
        this.uuid,
        this.linkCategory,
        this.subCategoryName,
        this.linkOrganisation,
        this.createdBy,
        this.updatedBy,
        this.createdAt,
        this.updatedAt});

  SubCategories.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    uuid = json['uuid'];
    linkCategory = json['link_category'];
    subCategoryName = json['subCategoryName'];
    linkOrganisation = json['link_organisation'];
    createdBy = json['created_by'];
    updatedBy = json['updated_by'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['uuid'] = this.uuid;
    data['link_category'] = this.linkCategory;
    data['subCategoryName'] = this.subCategoryName;
    data['link_organisation'] = this.linkOrganisation;
    data['created_by'] = this.createdBy;
    data['updated_by'] = this.updatedBy;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}

class Menu {
  String? categoryName;
  String? subCategoryName;
  String? uuid;
  String? link_category;

  // IconData? icon;
  List<Menu> subCategories = [];

  Menu(
      {required this.categoryName,
        required this.subCategories,
        this.subCategoryName,
        this.uuid,
        this.link_category});

  Menu.fromJson(Map<String, dynamic> json) {
    categoryName = json['categoryName'];
    link_category = json['link_category'];
    uuid = json['uuid'];
    // icon = json['icon'];
    if (json['subCategories'] != null) {
      subCategories.clear();
      json['subCategories'].forEach((v) {
        v['categoryName'] = v['subCategoryName'];
        subCategoryName = v['subCategoryName'];
        subCategories.add(new Menu.fromJson(v));
      });
    }
  }
}
