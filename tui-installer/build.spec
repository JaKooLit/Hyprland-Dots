# -*- mode: python ; coding: utf-8 -*-
# PyInstaller spec for building a single-file binary.

from PyInstaller.utils.hooks import collect_submodules

block_cipher = None


hiddenimports = collect_submodules("textual")


a = Analysis(
    ["src/dots_tui/__main__.py"],
    pathex=["src"],
    binaries=[],
    datas=[("src/dots_tui/installer.tcss", "dots_tui")],
    hiddenimports=hiddenimports,
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name="dots-tui",
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=True,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)
