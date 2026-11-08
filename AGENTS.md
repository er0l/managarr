# Project workflow

### Before committing

1. Bump `version` in `pubspec.yaml` (patch `1.x.y+z` for small fixes, minor `1.x+1.0` for new features).
2. Run `flutter analyze --no-pub` and confirm **No issues found**.
3. Then commit and push.
4. Tag the release commit: `git tag version_number`.
5. Push the version tag: `git push origin version_number`.

Replace `version_number` with the release version tag, following the existing `v` prefix and omitting the build number (for example, `v1.8.0` for `1.8.0+53`).
