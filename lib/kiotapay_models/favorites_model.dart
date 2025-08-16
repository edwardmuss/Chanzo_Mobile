class FavoritesModel {
  String? msg;
  List<Data>? data;

  FavoritesModel({this.msg, this.data});

  FavoritesModel.fromJson(Map<String, dynamic> json) {
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
  String? fullName;
  String? payTo;
  String? payVia;
  String? additionalPayTo;
  String? currency;
  String? linkOrganisation;
  String? createdBy;
  String? createdAt;
  String? updatedAt;

  Data(
      {this.id,
        this.uuid,
        this.fullName,
        this.payTo,
        this.payVia,
        this.additionalPayTo,
        this.currency,
        this.linkOrganisation,
        this.createdBy,
        this.createdAt,
        this.updatedAt});

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    uuid = json['uuid'];
    fullName = json['full_name'];
    payTo = json['payTo'];
    payVia = json['pay_via'];
    additionalPayTo = json['additionalPayTo'];
    currency = json['currency'];
    linkOrganisation = json['link_organisation'];
    createdBy = json['created_by'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['uuid'] = this.uuid;
    data['full_name'] = this.fullName;
    data['payTo'] = this.payTo;
    data['pay_via'] = this.payVia;
    data['additionalPayTo'] = this.additionalPayTo;
    data['currency'] = this.currency;
    data['link_organisation'] = this.linkOrganisation;
    data['created_by'] = this.createdBy;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}
