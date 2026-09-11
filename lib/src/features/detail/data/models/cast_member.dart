/// Cast member from TMDB credits (`/movie/{id}?append_to_response=credits`).
class CastMember {
  final String name;
  final String character;
  final String? profilePath;

  const CastMember({
    required this.name,
    required this.character,
    required this.profilePath,
  });

  factory CastMember.fromJson(Map<String, dynamic> json) {
    return CastMember(
      name: (json['name'] ?? '').toString(),
      character: (json['character'] ?? '').toString(),
      profilePath: json['profile_path'] as String?,
    );
  }
}
