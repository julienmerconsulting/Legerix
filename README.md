# Legerix

Tesseract + Leptonica natives bundled as a cross-platform Maven artifact, with
a thin Java loader. From Latin _legere_, "to read".

Modeled on [Apertix](https://github.com/julienmerconsulting/Apertix), which
does the same thing for OpenCV. Legerix solves the equivalent problem for
[tess4j](https://github.com/nguyenq/tess4j) consumers: ship the matching
Tesseract version with the application instead of relying on a system-wide
`apt install tesseract-ocr`, which on Ubuntu 24.04 ships `libtesseract.so.5.0.3`
(Tesseract 5.3.4) and is missing the `TessBaseAPIGetPAGEText` symbol introduced
in 5.5.x.

## Coordinates

```xml
<dependency>
    <groupId>io.github.oculix-org</groupId>
    <artifactId>legerix</artifactId>
    <version>5.5.0-1</version>
</dependency>
```

Versioning: `<tesseract-version>-<build-number>`. A bump of the build number
re-ships the same Tesseract version with a CI/packaging fix; a Tesseract
upstream release resets the build to `1`.

## What's in the jar

| Path                                  | Content                                |
| ------------------------------------- | -------------------------------------- |
| `linux-x86-64/`                       | glibc &ge; 2.38 build (Ubuntu 24.04)   |
| `linux-x86-64-legacy/`                | glibc &ge; 2.28 build (manylinux_2_28) |
| `linux-aarch64/`                      | glibc &ge; 2.38 build                  |
| `linux-aarch64-legacy/`               | glibc &ge; 2.28 build                  |
| `darwin/`                             | macOS x86\_64                          |
| `darwin-aarch64/`                     | macOS Apple Silicon                    |
| `win32-x86-64/`                       | Windows x86\_64 (vcpkg toolchain)      |
| `tessdata/eng.traineddata`            | English fast model (~2.5 MB)           |
| `io/github/julienmerconsulting/legerix/Legerix.class` | Java loader               |

Each platform directory contains both `libtesseract` and `libleptonica`.

## Public API

```java
import io.github.julienmerconsulting.legerix.Legerix;

// Extract natives + tessdata to a per-user cache, load both libs into the JVM.
Path nativesDir   = Legerix.loadNatives();

// Path to the extracted tessdata folder, ready to feed to tess4j.
Path tessdataDir  = Legerix.getTessdataPath();

// Detected runtime tier on Linux: "modern", "legacy" or "n/a" off-Linux.
String tier       = Legerix.getGlibcTier();

// Tesseract upstream version embedded in this jar (e.g. "5.5.0").
String tessVer    = Legerix.getTesseractVersion();
```

### Typical OculiX-side wiring (tess4j consumer)

```java
Legerix.loadNatives();                          // BEFORE tess4j touches JNA
ITesseract tess = new Tesseract();
tess.setDatapath(Legerix.getTessdataPath().toString());
tess.setLanguage("eng");
String text = tess.doOCR(image);
```

## Languages / tessdata

**Only `eng.traineddata` (English, fast model, ~4 MB) is bundled in the jar.**
This is a deliberate trade-off: shipping every language pack would inflate the
artifact past 100 MB, and most consumers only need a few specific languages.

If you need any other language (French, German, Spanish, multi-language, etc.),
you have to provide the corresponding `*.traineddata` files yourself. Two
approaches:

### A. Override the datapath entirely (recommended)

Download the languages you need from the upstream repos
([tessdata\_fast](https://github.com/tesseract-ocr/tessdata_fast) for speed,
[tessdata\_best](https://github.com/tesseract-ocr/tessdata_best) for accuracy)
into your own folder, then point tess4j there instead of `getTessdataPath()`:

```java
Legerix.loadNatives();
ITesseract tess = new Tesseract();
tess.setDatapath("/opt/myapp/tessdata"); // contains fra.traineddata, deu.traineddata, ...
tess.setLanguage("fra");                 // or "fra+eng" for combined
String text = tess.doOCR(image);
```

### B. Drop extra `.traineddata` next to the bundled `eng.traineddata`

`Legerix.getTessdataPath()` returns a writable per-user cache directory (e.g.
`~/.cache/legerix/5.5.0/tessdata/` on Linux,
`%LOCALAPPDATA%\legerix\5.5.0\tessdata\` on Windows). You can drop additional
language files there at install time, then keep using `getTessdataPath()`:

```java
Path tessdata = Legerix.getTessdataPath();
// Download fra.traineddata to tessdata.resolve("fra.traineddata") on first run, then:
ITesseract tess = new Tesseract();
tess.setDatapath(tessdata.toString());
tess.setLanguage("fra");
```

A future release may add a helper like `Legerix.installLanguage("fra")` that
downloads on-demand and caches. Until then, language management is the
consumer's responsibility — Legerix only guarantees that English works
out-of-the-box.

## Glibc tier picker

On Linux, `loadNatives()` runs `ldd --version` at startup and picks
`linux-<arch>-legacy/` if the detected glibc is older than 2.38, else the
modern build. No env var required, no system tesseract required, no
`apt install` required.

For non-Linux platforms the tier is reported as `"n/a"`.

## Building locally

The natives are produced by GitHub Actions (`.github/workflows/build.yml`,
7-job matrix). Reproducing locally just for one platform:

```bash
PREFIX="$PWD/_prefix"
mkdir -p "$PREFIX"
./scripts/build-leptonica.sh 1.87.0 "$PREFIX"
./scripts/build-tesseract.sh 5.5.0  "$PREFIX"
./scripts/fetch-traineddata.sh src/main/resources/tessdata

# Stage and package
mkdir -p src/main/resources/linux-x86-64
cp -L "$PREFIX/lib/libleptonica.so.6" src/main/resources/linux-x86-64/
cp -L "$PREFIX/lib/libtesseract.so.5" src/main/resources/linux-x86-64/
mvn -B install
```

CI is the source of truth for cross-platform builds; local builds populate
only the current host's resource directory.

## License

[MIT](LICENSE) for Legerix itself. Bundled natives keep their upstream
licenses (Apache 2.0 for Tesseract and the eng traineddata, BSD-2-Clause for
Leptonica). See [NOTICE](NOTICE) and [THIRD-PARTY.txt](THIRD-PARTY.txt).
