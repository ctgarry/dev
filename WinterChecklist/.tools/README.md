##########
This is the list of files for vscode automation:

• deploy.ps1: tiny wrapper that always finds publish.ps1 (path-safe) 
   and forwards flags.

• publish.ps1: builds TOC-only ZIPs to dist\{Addon}-v{Version}-{Flavor}.zip 
   and (optionally) installs TOC-only files to your AddOns dir.

• tasks.json: uses options.env (ADDON_NAME, WOW_DIR_RETAIL, WOW_DIR_CLASSIC) 
   and calls deploy.ps1 for:
  - Build ZIP: Retail / ClassicEra
  - Install (TOC-only): Retail / ClassicEra