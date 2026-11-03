# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PDFiumReader is a Delphi VCL application that provides a PDF viewer using the custom libPDFium.dll library. The project demonstrates integration of the PDFium rendering engine with Delphi through a COM-like interface wrapper.

## Project Structure

```
/mnt/w/PDFiumReader/
├── src/                    # Source code files
│   ├── PDFiumReader.dpr    # Main project file
│   ├── PDFiumReader.dproj  # RAD Studio project configuration
│   ├── Main.pas/dfm        # Main form implementation
│   ├── PDFiumFrame.pas/dfm # PDF viewer frame component
│   ├── ExecutelibPDFium.pas # libPDFium.dll interface definitions
│   └── DynamicButtons.pas  # Button components
├── bin/                    # Compiled binaries
│   ├── PDFiumReader.exe    # Compiled application
│   └── libpdfium.dll       # PDF rendering library
└── libPDFium/             # libPDFium source and build info
    └── readme.md          # Build instructions for libPDFium
```

## Build & Compilation

### Compiling the Project
Compile with `delphi-compiler.exe` (in `W:/bin`, on PATH); decide pass/fail by its exit code:
```bash
delphi-compiler.exe W:/PDFiumReader/src/PDFiumReader.dproj
```

### Project Dependencies
- **Delphi Version**: RAD Studio 12 (Delphi 29.0)
- **Framework**: VCL (Visual Component Library)
- **Target Platform**: Win32 (with Win64 support configured)
- **Required DLL**: libpdfium.dll must be present in the output directory
- **Package Dependencies**: CtrlsMAX package (from CyberMAX framework)

### Configuration
- The project references `W:\Delphi Current Version.optset` for common settings
- Build configurations: Debug and Release
- DPI Awareness Mode: none (legacy DPI handling)

## Architecture & Key Components

### Core Components

1. **ExecutelibPDFium.pas**
   - Defines COM-like interfaces for PDFium interaction
   - Key interfaces: IPDFium, IPDFDocument, IPDFPage, IPDFText, IPDFAnnotation
   - Handles PDF loading, rendering, and text extraction

2. **PDFiumFrame.pas**
   - TFrame descendant implementing the PDF viewer
   - Manages page rendering, scrolling, zoom, and text selection
   - Implements double-buffering for smooth display
   - Constants: PAGE_MARGIN = 5 pixels

3. **Main.pas**
   - Application main form
   - Provides UI for file operations and zoom controls
   - Zoom levels: 10% to 6400%
   - Integrates PDFiumFrame for display

### Key Patterns

- **Interface-based API**: All PDFium functionality exposed through interfaces
- **Points to Pixels conversion**: 1 point = 1/72 inch (≈0.3528 mm)
- **Coordinate system**: PDF uses bottom-left origin, converted for display
- **Memory management**: Reference counting via COM interfaces

## libPDFium.dll Integration

The project uses a custom-built libPDFium.dll that wraps Google's PDFium in a COM-like interface:

```pascal
// Creating PDFium instance
PDF_Create(1, pdf);  // C-style
// or
pdf := CreatePDFium; // Delphi wrapper

// Loading document
pdf.LoadFromFile('document.pdf', nil);
```

### Building libPDFium (if needed)
1. Install depot_tools
2. Download PDFium source
3. Add libpdfium files to pdfium/libpdfium/
4. Modify pdfium/BUILD.gn to include libpdfium
5. Build with: `ninja -C out libpdfium`

See `/mnt/w/PDFiumReader/libPDFium/readme.md` for detailed instructions.

## Development Notes

- **Character encoding**: Mixed encoding, UTF-8 recommended for new files
- **Error handling**: Check interface method return values (0 = success)
- **Performance**: Use double buffering for rendering operations
- **Text extraction**: Available through IPDFText interface per page
- **Annotations**: Support for reading PDF annotations via IPDFAnnotation