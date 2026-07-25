/// Shortens a full Thai date string for compact display
/// "25 กรกฎาคม 2026 เวลา 12:27" -> "25 ก.ค. 26"
String shortenThaiDate(String fullDate) {
  const monthAbbr = {
    'มกราคม': 'ม.ค.',
    'กุมภาพันธ์': 'ก.พ.',
    'มีนาคม': 'มี.ค.',
    'เมษายน': 'เม.ย.',
    'พฤษภาคม': 'พ.ค.',
    'มิถุนายน': 'มิ.ย.',
    'กรกฎาคม': 'ก.ค.',
    'สิงหาคม': 'ส.ค.',
    'กันยายน': 'ก.ย.',
    'ตุลาคม': 'ต.ค.',
    'พฤศจิกายน': 'พ.ย.',
    'ธันวาคม': 'ธ.ค.',
  };

  var result = fullDate;
  monthAbbr.forEach((full, abbr) {
    result = result.replaceAll(full, abbr);
  });

  result = result.replaceAllMapped(
    RegExp(r'\b(\d{4})\b'),
    (m) => m.group(1)!.substring(2),
  );

  result = result.replaceAll('เวลา ', '');

  return result;
}
