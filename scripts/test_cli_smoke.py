#!/usr/bin/env python3
"""Exercise bilingual CLI processes without submitting a complete file operation."""
import argparse
import os
import pathlib
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("executable", type=pathlib.Path)
    parser.add_argument("expected_version")
    parser.add_argument("architecture", nargs="?", choices=["arm64", "x86_64"])
    args = parser.parse_args()
    invocation = [str(args.executable.resolve(strict=True))]
    if args.architecture:
        invocation = ["/usr/bin/arch", f"-{args.architecture}", *invocation]
    environment = {key: value for key, value in os.environ.items() if key not in ("LC_ALL", "LC_MESSAGES", "LANG")}
    checks = 0

    def check(label, arguments, stdin, exit_code, expected, locale=None, opens_menu=False):
        nonlocal checks
        result = subprocess.run([*invocation, *arguments], input=stdin, capture_output=True, text=True,
                                timeout=10, env={**environment, **(locale or {"LC_ALL": "C"})})
        combined = result.stdout + result.stderr
        assert result.returncode == exit_code and expected in combined, (label, result.returncode, combined)
        if not opens_menu:
            assert "Select a command" not in combined and "Выберите команду" not in combined, label
        print(f"PASS: {label}; exit={result.returncode}")
        checks += 1
        return combined

    for language in ("en", "ru"):
        is_ru = language == "ru"
        menu = "Выберите команду" if is_ru else "Select a command"
        unsupported = "Недопустимые аргументы" if is_ru else "Unsupported arguments"
        cases = [
            ("help", ["--help"], "", 0, "Использование:" if is_ru else "Usage:"),
            ("short help", ["-h"], "", 0, "Использование:" if is_ru else "Usage:"),
            ("version", ["--version"], "", 0, f"photos-sorter-cli {args.expected_version}"),
            ("unknown argument", ["--unknown"], "", 64, unsupported),
            ("combined commands", ["--help", "--version"], "", 64, unsupported),
            ("menu EOF", [], "", 0, menu),
            ("explicit exit", [], "0\n", 0, menu),
            ("invalid menu", [], "invalid\n0\n", 0, "Недопустимый ввод" if is_ru else "Invalid input"),
            ("menu version", [], "0\n", 0, f"v.{args.expected_version}"),
            ("language menu EOF", [], "7\n", 0, "1. English\n2. Русский"),
        ]
        cases += [(f"operation {choice} EOF", [], f"{choice}\n", 0, menu) for choice in range(1, 7)]
        for label, arguments, stdin, exit_code, expected in cases:
            check(f"{language}: {label}", ["--language", language, *arguments], stdin, exit_code,
                  expected, opens_menu=not arguments)
        target_language = "en" if is_ru else "ru"
        target_selection = "1" if is_ru else "2"
        switched = check(f"{language}: menu language switch", ["--language", language],
                         f"7\ninvalid\n{target_selection}\n0\n", 0,
                         "Недопустимый ввод" if is_ru else "Invalid input", opens_menu=True)
        final_menu = switched.rsplit("Photos Sorter CLI", 1)[-1]
        assert ("Выберите команду" if target_language == "ru" else "Select a command") in final_menu
        check(f"{language}: language menu Back", ["--language", language], "7\n0\n0\n", 0,
              menu, opens_menu=True)
    check("trailing language", ["--help", "--language", "ru"], "", 0, "Использование:")
    check("language alias", ["--lang", "ru", "-h"], "", 0, "Использование:")
    check("unknown before language", ["--unknown", "--language", "ru"], "", 64, "Недопустимые аргументы")
    for arguments in (["--language"], ["--language", "de"], ["--language", "ru", "--lang", "en"]):
        check("invalid language " + repr(arguments), arguments, "", 64, "--language ru")
    for label, locale, expected in [
        ("LC_ALL wins", {"LC_ALL": "ru_RU.UTF-8", "LC_MESSAGES": "en_US", "LANG": "en_US"}, "Использование:"),
        ("LC_MESSAGES wins", {"LC_MESSAGES": "ru_RU", "LANG": "en_US"}, "Использование:"),
        ("LANG", {"LANG": "ru_RU.UTF-8"}, "Использование:"),
        ("C locale", {"LC_ALL": "C", "LANG": "ru_RU"}, "Usage:"),
        ("unsupported locale", {"LC_ALL": "de_DE", "LANG": "ru_RU"}, "Usage:"),
    ]:
        check(label, ["--help"], "", 0, expected, locale)
    check("explicit overrides environment", ["--language", "en", "--help"], "", 0, "Usage:", {"LC_ALL": "ru_RU"})
    print(f"CLI process checks passed: {checks}")


if __name__ == "__main__":
    main()
