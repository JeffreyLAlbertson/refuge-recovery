class MeetingDetailsArgs {
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
  MeetingDetailsArgs(
      this.id,
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
      this.subRegion);
}
