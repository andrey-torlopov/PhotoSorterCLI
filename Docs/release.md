# PhotoSorter CLI: build and release

The tracked entry point is `scripts/release.sh`. Do not use the old ignored `build_and_notarize.sh`: it overwrites shared output directories. The new script retains a separate directory for each candidate and never installs or publishes it. Existing `dist/` and `pkg-root/` are not inputs or outputs.

## Contract

- macOS minimum: 15.0. The toolchain must support the package's Swift tools 6.1 manifest.
- Core is pinned to the published remote version `0.0.2` (`6b97352c15a956d633493bee955037d73757a304`). SwiftPM generates `Package.resolved`; the release build fails if resolution would change it. Never patch `.build/checkouts` or hand-edit the lockfile's `originHash`.
- `--version` is the single source for the candidate binary and PKG version. It must be numeric `X.Y.Z`. The current source reports `1.0.0`; the release value is also injected into the private source snapshot. A public tag must contain the same version as the PKG.
- The first release targets Apple Silicon only; `--arch` defaults to `arm64`. Explicit `--arch x86_64` and `--arch universal` remain available for future validation. Universal builds compile each slice separately and merge before signing. Intel support is not claimed; Rosetta and a universal Mach-O do not replace Intel hardware validation.
- Binary signing: **Developer ID Application**, secure timestamp and Hardened Runtime. PKG signing: **Developer ID Installer** from the same team. These are separate from Sorta's Mac App Store signing.
- Package identifier stays `torlopov.andrey.photossorter`; executable path stays `/usr/local/bin/photos-sorter-cli`. Check the previous installed receipt before a public upgrade. The script does not remove or replace receipts.
- A clean source snapshot comes from `git archive HEAD`, excluding ignored/untracked local files. A snapshot includes uncommitted changes only with `--allow-dirty`; its Git status and HEAD are retained. Source symlinks and output directories inside Sources, Tests, scripts or .git are rejected. Public candidates should come from the reviewed, committed source.

## Stages

Run `scripts/release.sh --help` for options. Each command performs only its own stage; there is no implicit Developer ID signing, upload or publication. The build stage may restore a local ad-hoc signature after the narrowly scoped Mach-O normalization described below.

| Stage | Work and retained evidence |
|---|---|
| `preflight` | Check tools, exact signing identities/private keys, Team ID and access to an existing notarytool profile; no build or upload |
| `build` | Create a new staging directory, copy sources/lockfile, inject version into the copy, resolve/build isolated slices, check architectures, minimum OS, dynamic dependencies/runtime search paths and `--version`; retain logs and source/toolchain metadata; normalize a proven unused compatibility rpath and restore a local ad-hoc signature if needed |
| `sign` | Sign the completed binary and validate authority, team, runtime flag and timestamp; retain checksum |
| `package` | Validate signed payload and create a signed versioned PKG; retain signature output and checksum |
| `notarize` | Submit the PKG, wait, save submission JSON and notarization log, require `Accepted`, staple and validate; retain final-container checksum |
| `verify` | Recheck signed binary and stapled PKG integrity, signatures, architectures, dependencies, Gatekeeper and staple; write final `SHA256SUMS` |

All stages take the same `--version`, `--arch` and `--output`. The output parent contains `photos-sorter-cli-X.Y.Z-ARCH/`; `build` refuses an existing candidate. Failed artifacts/logs are retained for diagnosis. To retry a modified candidate, choose a new output parent; do not rewrite an existing version's published bytes.

Choose the version from release history before building. The following interactive setup avoids hardcoded credentials or an accidental choice of version:

```bash
read -r -p 'Candidate version (X.Y.Z): ' release_version
release_arch=arm64
read -r -p 'New output parent directory: ' release_output
read -r -p 'Apple Team ID: ' release_team
read -r -p 'Developer ID Application identity: ' release_application_identity
read -r -p 'Developer ID Installer identity: ' release_installer_identity
read -r -p 'Existing notarytool Keychain profile: ' release_notary_profile
```

Execute in Bash, from the repository root. Profile names and signing identity names are configuration, not credentials; the script never asks for an Apple password or private-key export. Store credentials with Apple's supported Keychain workflow separately.

```bash
scripts/release.sh preflight --version "$release_version" --arch "$release_arch" --output "$release_output" \
  --team-id "$release_team" --application-identity "$release_application_identity" \
  --installer-identity "$release_installer_identity" --notary-profile "$release_notary_profile"

scripts/release.sh build --version "$release_version" --arch "$release_arch" --output "$release_output"

scripts/release.sh sign --version "$release_version" --arch "$release_arch" --output "$release_output" \
  --team-id "$release_team" --application-identity "$release_application_identity"

scripts/release.sh package --version "$release_version" --arch "$release_arch" --output "$release_output" \
  --team-id "$release_team" --installer-identity "$release_installer_identity"

scripts/release.sh notarize --version "$release_version" --arch "$release_arch" --output "$release_output" \
  --notary-profile "$release_notary_profile"

scripts/release.sh verify --version "$release_version" --arch "$release_arch" --output "$release_output" \
  --team-id "$release_team"
```

Run each stage after reviewing its predecessor's result and obtaining the applicable build/signing/upload authorization. An invalid notarization result is a release blocker. The recorded submission ID can be inspected with `xcrun notarytool info` and `log`; do not resubmit blindly after a connection failure. The script refuses a second submission record.

## SwiftPM compatibility search path

With the verified Apple Swift 6.4.2 toolchain, SwiftPM adds an absolute `LC_RPATH` to its `usr/lib/swift-6.2/macosx` directory even when the executable does not load `libswiftCompatibilitySpan.dylib`. Both build backends were observed to do this; driver stdlib-rpath flags do not remove the explicit linker argument.

Before merging slices, `build` records each slice's actual dependencies and load commands. It removes only that exact compatibility directory from the selected compiler's toolchain, and only when **every** library load is an absolute `/usr/lib/` or `/System/Library/` path. An `@rpath` dependency, another non-system library or an unknown search path stops the build. No library is silently discarded or replaced. The script then restores the local ad-hoc signature invalidated by `install_name_tool`, records the after-state and verifies that library loads are unchanged. The final validator still rejects all non-system runtime paths.

The original link outputs remain under `build-arm64`/`build-x86_64`; normalization evidence remains under `logs/normalization-*`. Ad-hoc signing is part of local executable preparation and does not satisfy the separate Developer ID signing stage or public distribution requirements.

## Verification and handoff

The RU/EN catalogue is embedded in the executable: there is no resource bundle to package. Verify both `--language en` and `--language ru`, menu item 7 language switching, the version header, environment precedence, invalid language arguments and bilingual yes/no input. `scripts/test_cli_smoke.py` runs both languages; run `scripts/test_cli_fixtures.py` separately with `--language en` and `--language ru` and a genuine `--dng-fixture`.

Before signing, run `swift test` and all six operations on disposable fixture copies, including ordinary filesystem URLs without sandbox scopes, keep-originals and deletion modes, errors and collisions. Validate stdin EOF in the main menu and nested prompts, `--help`, `--version`, and invalid arguments. Builds/tests require the project's normal execution authorization.

After `verify`, prepare release notes in English and Russian describing actual changes, the version, Core revision, tested macOS/architectures and unverified limitations. Attach the versioned PKG, `SHA256SUMS`, and release notes to the reviewed GitHub release. This script has no GitHub mutation or publication command.

On a clean account/machine without Xcode, download the candidate through a browser (quarantine preserved), check its checksum, install, execute `--version` and all fixture operations, and test an upgrade from the previous receipt. Check online/offline behavior after stapling. Repeat the download/install check after publication. A local successful assessment alone does not establish public-download or clean-machine behavior. Rosetta is an additional check, not a replacement for Intel hardware.

## Русское резюме

Используйте `scripts/release.sh`, а не старый неотслеживаемый скрипт. Этапы `preflight`, `build`, `sign`, `package`, `notarize`, `verify` вызываются отдельно; публикации и установки скрипт не выполняет. Для известного лишнего Swift 6.2 compatibility rpath допускается только проверенная нормализация с локальной ad-hoc подписью; Developer ID остаётся отдельным этапом. Версия задаётся одним `--version` и попадает в бинарь и PKG. Первый выпуск предназначен только для Apple Silicon: по умолчанию используется `arm64`. Параметры `--arch x86_64` и `--arch universal` сохранены для будущих проверок; поддержка Intel пока не заявляется. Исходники собираются в отдельной копии с закреплённым Core, рабочие `dist/` и `pkg-root/` сохраняются.

Для подписи нужны разные Developer ID Application и Developer ID Installer одной team, для нотарификации — существующий профиль Keychain. Не выводите пароли, ключи и токены. Дождитесь `Accepted`, staple и Gatekeeper; итоговый checksum формируется после staple. Ошибки сохраняются вместе с логами и блокируют выпуск.

Перед публикацией обязательны тесты шести операций на копиях файлов, RU/EN release notes, установка на чистой macOS без Xcode, обновление и проверка каждой заявленной архитектуры. Команда удаления из пользовательского README удаляет только executable, а не фотоархивы. Публичный выпуск требует отдельного разрешения и повторной проверки скачанного установщика.
