/// Humanize folder/slug name: "starter-astro-blog" -> "Starter astro blog".
String humanize(String s) {
  if (s.isEmpty) return s;
  return s
      .split(RegExp(r'[-_\s]+'))
      .map(
        (e) => e.isEmpty
            ? e
            : '${e[0].toUpperCase()}${e.substring(1).toLowerCase()}',
      )
      .join(' ');
}
