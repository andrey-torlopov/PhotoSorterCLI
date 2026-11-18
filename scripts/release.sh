#!/bin/bash
# Each invocation performs only its named stage. Never publishes or installs anything.
set -euo pipefail
umask 022

usage() {
    cat <<'HELP'
Usage: scripts/release.sh STAGE --version X.Y.Z --output DIR [OPTIONS]
Stages: preflight, build, sign, package, notarize, verify
Options:
  --arch ARCH                 arm64 (default), x86_64 or universal
  --application-identity NAME  Developer ID Application identity (sign/preflight)
  --installer-identity NAME    Developer ID Installer identity (package/preflight)
  --team-id ID                 Apple Team ID (sign/package/preflight/verify)
  --notary-profile NAME        Existing notarytool Keychain profile (notarize/preflight)
  --allow-dirty                Allow a build snapshot with uncommitted source changes

DIR is a parent directory; this script owns DIR/photos-sorter-cli-X.Y.Z-ARCH.
Build requires a new stage directory and never replaces an existing release.
Build may reapply a local ad-hoc signature after removing a proven unused toolchain rpath.
No stage is run automatically as a prerequisite. Signing and notarization are explicit.
HELP
}
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || fail "Required tool is missing: $1"; }
require_value() { [[ $# -ge 2 && -n "$2" && "$2" != --* ]] || fail "Missing value for $1"; }

[[ $# -gt 0 ]] || { usage; exit 64; }
stage="$1"; shift
case "$stage" in
    --help|-h|help) usage; exit 0 ;;
    preflight|build|sign|package|notarize|verify) ;;
    *) fail "Unknown stage: $stage" ;;
esac
release_version=""; architecture="arm64"; output_parent=""; application_identity=""
installer_identity=""; team_id=""; notary_profile=""; allow_dirty=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --version) require_value "$@"; release_version="$2"; shift 2 ;;
        --arch) require_value "$@"; architecture="$2"; shift 2 ;;
        --output) require_value "$@"; output_parent="$2"; shift 2 ;;
        --application-identity) require_value "$@"; application_identity="$2"; shift 2 ;;
        --installer-identity) require_value "$@"; installer_identity="$2"; shift 2 ;;
        --team-id) require_value "$@"; team_id="$2"; shift 2 ;;
        --notary-profile) require_value "$@"; notary_profile="$2"; shift 2 ;;
        --allow-dirty) allow_dirty=true; shift ;;
        *) fail "Unknown option: $1" ;;
    esac
done
[[ "$release_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "--version must be X.Y.Z"
case "$architecture" in arm64|x86_64|universal) ;; *) fail "Choose --arch arm64, x86_64 or universal" ;; esac
[[ -n "$output_parent" ]] || fail "--output is required"
[[ "$(uname -s)" == Darwin ]] || fail "macOS is required"
project_root="$(cd "$(dirname "$0")/.." && pwd -P)"
case "$output_parent" in /*) ;; *) output_parent="$PWD/$output_parent" ;; esac
release_name="photos-sorter-cli-${release_version}-${architecture}"
release_dir="$output_parent/$release_name"
binary="$release_dir/payload/usr/local/bin/photos-sorter-cli"
pkg="$release_dir/$release_name.pkg"
architectures=("$architecture")
if [[ "$architecture" == universal ]]; then architectures=(arm64 x86_64); fi

require_stage() {
    [[ -d "$release_dir" && ! -L "$release_dir" ]] || fail "Build stage is missing: $release_dir"
    [[ "$(cat "$release_dir/version.txt")" == "$release_version" ]] || fail "Version mismatch"
    [[ "$(cat "$release_dir/architecture.txt")" == "$architecture" ]] || fail "Architecture mismatch"
}
require_team() {
    [[ "$team_id" =~ ^[A-Z0-9]{10}$ ]] || fail "--team-id must be a 10-character Apple Team ID"
}
require_application_identity() {
    require_team
    [[ "$application_identity" == 'Developer ID Application: '*"($team_id)" ]] || fail "Use a Developer ID Application identity for the requested team"
    security find-identity -v -p codesigning | grep -Fq -- "$application_identity" || fail "Application identity/private key is unavailable"
}
require_installer_identity() {
    require_team
    [[ "$installer_identity" == 'Developer ID Installer: '*"($team_id)" ]] || fail "Use a Developer ID Installer identity for the requested team"
    security find-identity -v | grep -Fq -- "$installer_identity" || fail "Installer identity/private key is unavailable"
}
normalize_slice() {
    local slice_binary="$1" slice_arch="$2" dependency runtime_path runtime_root compatibility_rpath
    local prefix="$release_dir/logs/normalization-$slice_arch"
    swiftc -target "$slice_arch-apple-macosx15.0" -print-target-info > "$prefix-target-info.json"
    runtime_root="$(plutil -extract paths.runtimeResourcePath raw -o - "$prefix-target-info.json")"
    # SwiftPM 6.4 inserts its Swift 6.2 Span compatibility directory even when unused.
    # This is deliberately one known path, not a wildcard for arbitrary toolchain directories.
    compatibility_rpath="$(dirname "$runtime_root")/swift-6.2/macosx"
    otool -arch "$slice_arch" -L "$slice_binary" > "$prefix-dependencies-before.txt"
    # Remove a toolchain search path only when every actual library load is an absolute system path.
    # In particular, @rpath/libswiftCompatibilitySpan.dylib must fail instead of losing its runtime.
    while IFS= read -r dependency; do
        case "$dependency" in
            /usr/lib/*|/System/Library/*) ;;
            *) fail "Cannot normalize $slice_arch with a non-system dependency: $dependency" ;;
        esac
    done < <(awk '/compatibility version/ { print $1 }' "$prefix-dependencies-before.txt")
    otool -arch "$slice_arch" -l "$slice_binary" > "$prefix-load-commands-before.txt"
    local normalized=false
    while IFS= read -r runtime_path; do
        case "$runtime_path" in
            /usr/lib/swift|/System/Library/*) ;;
            "$compatibility_rpath")
                xcrun install_name_tool -delete_rpath "$runtime_path" "$slice_binary"
                normalized=true ;;
            *) fail "Unknown runtime path cannot be normalized safely: $runtime_path" ;;
        esac
    done < <(awk '$1 == "cmd" && $2 == "LC_RPATH" { wanted = 1; next }
        wanted && $1 == "path" { print $2; wanted = 0 }' "$prefix-load-commands-before.txt")
    if [[ "$normalized" == true ]]; then
        # Re-establish the local build signature invalidated by editing Mach-O load commands.
        # This does not use a Developer ID identity or make the candidate distributable.
        codesign --force --sign - "$slice_binary"
    fi
    codesign --verify --strict "$slice_binary"
    otool -arch "$slice_arch" -L "$slice_binary" > "$prefix-dependencies-after.txt"
    cmp "$prefix-dependencies-before.txt" "$prefix-dependencies-after.txt" || fail "Normalization changed library dependencies"
    otool -arch "$slice_arch" -l "$slice_binary" > "$prefix-load-commands-after.txt"
}
verify_binary() {
    [[ -x "$binary" ]] || fail "Missing executable"
    local actual_arch expected_arch dependency min_os runtime_path
    actual_arch="$(lipo -archs "$binary" | tr ' ' '\n' | sort | tr '\n' ' ')"
    expected_arch="$(printf '%s\n' "${architectures[@]}" | sort | tr '\n' ' ')"
    [[ "$actual_arch" == "$expected_arch" ]] || fail "Unexpected Mach-O architectures: $actual_arch"
    otool -L "$binary" > "$release_dir/dynamic-libraries.txt"
    while IFS= read -r dependency; do
        case "$dependency" in
            /usr/lib/*|/System/Library/*) ;;
            *) fail "Non-system dynamic dependency must be bundled before distribution: $dependency" ;;
        esac
    done < <(awk '/compatibility version/ { print $1 }' "$release_dir/dynamic-libraries.txt")
    otool -l "$binary" > "$release_dir/load-commands.txt"
    while IFS= read -r runtime_path; do
        case "$runtime_path" in
            /usr/lib/swift|/System/Library/*) ;;
            *) fail "Non-system runtime search path: $runtime_path" ;;
        esac
    done < <(awk '$1 == "cmd" && $2 == "LC_RPATH" { wanted = 1; next }
        wanted && $1 == "path" { print $2; wanted = 0 }' "$release_dir/load-commands.txt")
    xcrun vtool -show-build "$binary" > "$release_dir/macho-build-version.txt"
    grep -q 'minos ' "$release_dir/macho-build-version.txt" || fail "Mach-O minimum OS not found"
    while IFS= read -r min_os; do
        [[ "$min_os" == 15.0 || "$min_os" == 15.0.0 ]] || fail "Unexpected minimum macOS: $min_os"
    done < <(awk '$1 == "minos" { print $2 }' "$release_dir/macho-build-version.txt")
    [[ "$("$binary" --version)" == "photos-sorter-cli $release_version" ]] || fail "Binary and package versions differ"
}
verify_signature() {
    require_team
    codesign --verify --strict --verbose=2 "$binary"
    codesign -dvv "$binary" > "$release_dir/codesign.txt" 2>&1
    grep -Fq "TeamIdentifier=$team_id" "$release_dir/codesign.txt" || fail "Unexpected signing team"
    grep -Fq 'Authority=Developer ID Application:' "$release_dir/codesign.txt" || fail "Not a Developer ID Application signature"
    grep -q 'flags=.*runtime' "$release_dir/codesign.txt" || fail "Hardened Runtime missing"
    grep -q '^Timestamp=' "$release_dir/codesign.txt" || fail "Secure timestamp missing"
}

case "$stage" in
    preflight)
        for tool in swift xcrun codesign security pkgbuild pkgutil lipo otool shasum git; do need "$tool"; done
        swift --version
        xcrun --sdk macosx --show-sdk-version
        require_application_identity
        require_installer_identity
        [[ -n "$notary_profile" ]] || fail "--notary-profile is required"
        xcrun notarytool history --keychain-profile "$notary_profile" --output-format json >/dev/null
        printf 'Preflight passed. No build, signature, package or upload was performed.\n'
        ;;
    build)
        need swift; need swiftc; need git; need lipo; need otool; need xcrun; need codesign; need plutil
        [[ ! -e "$release_dir" ]] || fail "Release directory already exists; choose a new output parent"
        source_commit="$(git -C "$project_root" rev-parse HEAD)"
        source_status="$(git -C "$project_root" status --porcelain -- Package.swift Package.resolved Sources Tests scripts)"
        [[ -z "$source_status" || "$allow_dirty" == true ]] || fail "Source changes are uncommitted; commit them or explicitly pass --allow-dirty"
        mkdir -p "$output_parent"
        output_parent="$(cd "$output_parent" && pwd -P)"
        case "$output_parent/" in
            "$project_root/Sources/"*|"$project_root/Tests/"*|"$project_root/scripts/"*|"$project_root/.git/"*)
                fail "Output must be outside source, test, script and Git directories" ;;
        esac
        release_dir="$output_parent/$release_name"
        binary="$release_dir/payload/usr/local/bin/photos-sorter-cli"
        pkg="$release_dir/$release_name.pkg"
        mkdir "$release_dir"
        printf '%s\n' "$release_version" > "$release_dir/version.txt"
        printf '%s\n' "$architecture" > "$release_dir/architecture.txt"
        printf '%s\n' "$source_status" > "$release_dir/source-status.txt"
        printf '%s\n' "$source_commit" > "$release_dir/source-commit.txt"
        swift --version > "$release_dir/toolchain.txt"
        xcrun --sdk macosx --show-sdk-version >> "$release_dir/toolchain.txt"
        mkdir "$release_dir/source" "$release_dir/logs" "$release_dir/slices"
        if [[ -z "$source_status" ]]; then
            # Tracked source only: ignored local files cannot leak into a clean release.
            git -C "$project_root" archive --format=tar "$source_commit" -- Package.swift Package.resolved Sources Tests |
                tar -xf - -C "$release_dir/source"
        else
            cp "$project_root/Package.swift" "$project_root/Package.resolved" "$release_dir/source/"
            cp -R "$project_root/Sources" "$project_root/Tests" "$release_dir/source/"
        fi
        [[ -z "$(find "$release_dir/source" -type l -print -quit)" ]] || fail "Source snapshot contains a symlink; make release inputs self-contained"
        printf 'enum BuildVersion { static let current = "%s" }\n' "$release_version" > "$release_dir/source/Sources/Version.swift"
        cp "$release_dir/source/Package.resolved" "$release_dir/Package.resolved"
        for slice in "${architectures[@]}"; do
            build_args=(--package-path "$release_dir/source" --scratch-path "$release_dir/build-$slice"
                --cache-path "$release_dir/cache" --config-path "$release_dir/config" --security-path "$release_dir/security"
                --disable-dependency-cache --force-resolved-versions
                --build-system native --configuration release --triple "$slice-apple-macosx15.0" --product photos-sorter-cli --disable-local-rpath)
            swift build "${build_args[@]}" 2>&1 | tee "$release_dir/logs/build-$slice.log"
            bin_dir="$(swift build "${build_args[@]}" --show-bin-path)"
            cp "$bin_dir/photos-sorter-cli" "$release_dir/slices/photos-sorter-cli-$slice"
            normalize_slice "$release_dir/slices/photos-sorter-cli-$slice" "$slice"
        done
        cmp "$release_dir/Package.resolved" "$release_dir/source/Package.resolved" || fail "Build changed the pinned dependency lockfile"
        mkdir -p "$release_dir/payload/usr/local/bin"
        if [[ "$architecture" == universal ]]; then
            lipo -create "$release_dir/slices/photos-sorter-cli-arm64" "$release_dir/slices/photos-sorter-cli-x86_64" -output "$binary"
        else
            cp "$release_dir/slices/photos-sorter-cli-$architecture" "$binary"
        fi
        chmod 755 "$binary"
        verify_binary
        printf 'Build complete: %s\n' "$binary"
        ;;
    sign)
        require_stage; require_application_identity
        [[ ! -e "$release_dir/signed.sha256" && ! -e "$pkg" ]] || fail "This stage is already signed/packaged; create a new release instead of modifying it"
        verify_binary
        codesign --force --sign "$application_identity" --timestamp --options runtime "$binary"
        verify_signature
        shasum -a 256 "$binary" > "$release_dir/signed.sha256"
        ;;
    package)
        require_stage; require_installer_identity
        [[ -f "$release_dir/signed.sha256" ]] || fail "Run sign first"
        [[ ! -e "$pkg" ]] || fail "Package already exists; it will not be replaced"
        shasum -a 256 -c "$release_dir/signed.sha256"
        verify_binary; verify_signature
        pkgbuild --root "$release_dir/payload" --identifier torlopov.andrey.photossorter \
            --version "$release_version" --install-location / --sign "$installer_identity" "$pkg"
        pkgutil --check-signature "$pkg" | tee "$release_dir/installer-signature.txt"
        grep -Fq "($team_id)" "$release_dir/installer-signature.txt" || fail "Unexpected installer signing team"
        shasum -a 256 "$pkg" > "$release_dir/package.sha256"
        ;;
    notarize)
        require_stage
        [[ -n "$notary_profile" ]] || fail "--notary-profile is required"
        [[ -f "$release_dir/package.sha256" ]] || fail "Run package first"
        [[ ! -e "$release_dir/notary-submit.json" ]] || fail "Submission record exists; inspect it before creating a new submission"
        shasum -a 256 -c "$release_dir/package.sha256"
        if ! xcrun notarytool submit "$pkg" --keychain-profile "$notary_profile" --wait --output-format json > "$release_dir/notary-submit.json"; then
            fail "Notarization command failed; inspect the retained submission record"
        fi
        submission_id="$(plutil -extract id raw -o - "$release_dir/notary-submit.json")"
        xcrun notarytool log "$submission_id" --keychain-profile "$notary_profile" "$release_dir/notary-log.json"
        submission_status="$(plutil -extract status raw -o - "$release_dir/notary-submit.json")"
        [[ "$submission_status" == Accepted ]] || fail "Notarization status is $submission_status; release is blocked"
        xcrun stapler staple "$pkg"
        xcrun stapler validate "$pkg"
        shasum -a 256 "$pkg" > "$release_dir/stapled.sha256"
        ;;
    verify)
        require_stage; require_team
        [[ -f "$release_dir/stapled.sha256" ]] || fail "Run notarize and staple first"
        shasum -a 256 -c "$release_dir/signed.sha256"
        shasum -a 256 -c "$release_dir/stapled.sha256"
        verify_binary; verify_signature
        pkgutil --check-signature "$pkg" | tee "$release_dir/installer-signature.txt"
        grep -Fq "($team_id)" "$release_dir/installer-signature.txt" || fail "Unexpected installer signing team"
        xcrun stapler validate "$pkg"
        spctl --assess --type install --verbose=2 "$pkg" 2>&1 | tee "$release_dir/gatekeeper.txt"
        (cd "$release_dir" && shasum -a 256 "$release_name.pkg" > SHA256SUMS)
        printf 'Verified local artifact: %s\nSHA256SUMS is final after staple. Clean-machine and downloaded-artifact checks are still required.\n' "$pkg"
        ;;
esac
