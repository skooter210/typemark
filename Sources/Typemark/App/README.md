# App

This directory contains the application entry point and top-level scene configuration.

## Contents

- `MarkdownEditorApp.swift` — The `@main` struct conforming to `App`. Declares the `DocumentGroup` scene which provides native file open/save/new document support.

## Conventions

- Only one file should contain `@main`.
- Scene-level configuration (menu commands, window sizing) lives here.
- Do not import Views directly from App — keep the entry point minimal.
