class Meeting {
  final int id;
  final String name;
  final String slug;
  final String updated;
  final int locationId;
  final String url;
  final int day;
  final String time;
  final String endTime;
  final String timeFormatted;
  final String website;
  final String website2;
  final String phone;
  final List<dynamic> types;
  final String location;
  final String locationNotes;
  final String locationUrl;
  final String formattedAddress1;
  final String formattedAddress2;
  final num latitude;
  final num longitude;
  final int regionId;
  final String region;
  final String subRegion;

  Meeting(
      {this.id,
      this.name,
      this.slug,
      this.updated,
      this.locationId,
      this.url,
      this.day,
      this.time,
      this.endTime,
      this.timeFormatted,
      this.website,
      this.website2,
      this.phone,
      this.types,
      this.location,
      this.locationNotes,
      this.locationUrl,
      this.formattedAddress1,
      this.formattedAddress2,
      this.latitude,
      this.longitude,
      this.regionId,
      this.region,
      this.subRegion});

  bool selected = false;

  factory Meeting.fromJson(Map<String, dynamic> json) {
    String address = json['formatted_address'].toString();
    int subregionIndex = address.indexOf(json['sub_region'].toString());

    String formattedAddress2 = subregionIndex != -1
        ? address.substring(subregionIndex, address.length)
        : address;
    int usaIndex = formattedAddress2.indexOf(', USA');
    formattedAddress2 = usaIndex != -1
        ? formattedAddress2.substring(0, usaIndex)
        : formattedAddress2;

    String formattedAddress1 =
        subregionIndex != -1 ? address.substring(0, subregionIndex) : '';
    formattedAddress1 = formattedAddress1.trim();
    formattedAddress1 = formattedAddress1.length > 0
        ? formattedAddress1.substring(0, formattedAddress1.length - 1)
        : '';

    return Meeting(
        id: json['id'] as int,
        name: json['name'] as String,
        slug: json['slug'] as String,
        updated: json['updated'] as String,
        locationId: json['location_id'] as int,
        url: json['url'] as String,
        day: json['day'] as int,
        time: json['time'] as String,
        endTime: json['end_time'] as String,
        timeFormatted: json['time_formatted'],
        website: json['website'] as String,
        website2: json['website_2'] as String,
        phone: json['phone'] as String,
        types: json['types'] as List<dynamic>,
        location: json['location'] as String,
        locationNotes: json['location_notes'] as String,
        locationUrl: json['location_url'] as String,
        formattedAddress1: formattedAddress1,
        formattedAddress2: formattedAddress2,
        latitude: json['latitude'] as num,
        longitude: json['longitude'] as num,
        regionId: json['region_id'] as int,
        region: json['region'] as String,
        subRegion: json['sub_region'] as String);
  }
}
