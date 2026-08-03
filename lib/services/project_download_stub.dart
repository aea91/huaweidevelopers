/// Non-web fallback. The project download uses browser APIs and is only
/// wired on web; on other platforms this throws.
void downloadZip(List<int> bytes, String filename) {
  throw UnsupportedError('Project download is only supported on web.');
}
