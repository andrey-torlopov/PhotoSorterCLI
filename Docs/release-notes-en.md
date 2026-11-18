# PhotoSorterCLI 1.0.0

- The menu header displays `v.1.0.0`; `--version` prints `photos-sorter-cli 1.0.0` without opening the menu.
- Menu item **7 — Language / Язык** changes the interface immediately: **1 — English**, **2 — Русский**, **0 — Back**. The selection applies until exit.
- `--language` / `--lang`, locale detection, bilingual yes/no input, and all six photo operations are supported.
- EOF exits all input dialogues without starting incomplete file operations. Unknown or conflicting arguments exit with code 64.
- Original deletion is off by default and needs an explicit yes. Date-format punctuation is preserved.
- Uses the published PhotoSorterCore **0.0.2**. The installer places only `/usr/local/bin/photos-sorter-cli` and does not process photographs.

Target: Apple Silicon (arm64), macOS 15.0 or later. Intel is not supported by this package. See the published release notes for observed signing/notarization, validation and tested systems. Source documentation alone does not establish that a package was signed or published.

Before installation, place the PKG and SHA256SUMS in the same directory and run `shasum -a 256 -c SHA256SUMS`. Install with macOS Installer, then check `photos-sorter-cli --version`. Start photo operations on disposable copies and keep deletion disabled while checking the results.
