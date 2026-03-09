# GameVault Hardening Tasks

## CRITICAL

- [x] 1. Add timeout to all subprocess calls in gog.py execute_shell() (gog.py:32)
- [x] 2. Fix MobX reaction memory leak — capture and return disposer (GameDetailsItem.tsx:72)
- [x] 3. Fix RunExe shortcut restore — add timeout fallback if app never launches (executeAction.tsx:30-49)
- [x] 4. Escape values in generate_bash_env_settings to prevent eval injection (GameSet.py:417, all launcher .sh)

## HIGH

- [x] 5. Guard process_info_file() against missing playTasks/gameId keys (gog.py:318,360)
- [x] 6. Fix ScummVM --list-targets to return matching target, not first (gog.py:285-290)
- [x] 7. Use cp -rn instead of cp -n for gog-support subdirectory copy (store.sh:395)
- [x] 8. Fix killall gogdl — use kill $PID instead (GOG store.sh:68)
- [x] 9. Fix inverted PULSE_LATENCY_MSEC logic — change -z to -n (gog-launcher.sh:77)
- [x] 10. Fix LD_PRELOAD — use .so file path not directory (gog-launcher.sh:156)
- [x] 11. Check game exit code before uploading cloud saves (gog-launcher.sh:176)
- [x] 12. Fix word-splitting in ARGS loop for DOSBox conf paths (gog-launcher.sh:124)
- [x] 13. Add await to getAppDetails call (GameDisplay.tsx:144)
- [x] 14. Add parseInt radix and NaN guards for steamClientID (Multiple frontend files)
- [x] 15. Fix queue item mutation — use immutable updates (installQueue.ts:277+)
- [x] 16. Fix race between clear() and async start() loop (installQueue.ts:179-275)
- [x] 17. Sanitize HTML in dangerouslySetInnerHTML (GameDisplay.tsx:294)
- [x] 18. Escape quotes/special chars in generate_bash_env_settings values (GameSet.py:417)
- [x] 19. Change PRAGMA synchronous=OFF to NORMAL, reduce thread count (GameSet.py:71)
- [x] 20. Add path validation to archive extraction in itchio.py (itchio.py:373)
- [x] 21. Validate WebSocket self-update URL against GitHub repo (main.py:474)
- [x] 22. Re-enable SSL verification for update downloads (main.py:343,672,753)
- [x] 23. Fix epic.py has_updates() double JSON parse (epic.py:302-309)
- [x] 24. Fix get_base64_images IndexError with <2 images (GameSet.py:524)
- [x] 25. Extend DOSBox conf regex for unquoted/single-quoted paths (gog.py:640)
- [x] 26. Add wget error checking in install_deps.sh (install_deps.sh:9)

## MEDIUM

- [x] 27. Quote all shell variables in GOG store.sh ($DBFILE, $TEMP, $1, etc.)
- [x] 28. Quote all shell variables in Epic store.sh
- [x] 29. Quote all shell variables in Amazon store.sh
- [x] 30. Quote all shell variables in Itchio store.sh
- [x] 31. Add debounce/guard to L3+R3 modal open (index.tsx:32-56)
- [x] 32. Fix progress polling stacking — use generation counter (GameDetailsItem.tsx:119-157) — N/A, localInstallingRef already prevents stacking
- [x] 33. Validate restored queue items from localStorage (installQueue.ts:75-91)
- [x] 34. Add runtime guards for Empty state casts to GameDetails (GameDetailsItem.tsx:29) — N/A, already guarded by Type check before render
- [x] 35. Validate AddShortcut return value before configuring (installQueue.ts:372, GameDetailsItem.tsx:359)
- [x] 36. Narrow cleanupIds to only remove GameVault-created shortcuts (GameDetailsItem.tsx:340-346)
- [x] 37. Stop queue processing on plugin dismount (index.tsx:111-116)
- [x] 38. Clear debounce timer on GridContent unmount (GridContent.tsx:44)
- [x] 39. Fix unregister leak in runApp when app doesn't start (utils.ts:26-48)
- [x] 40. Add path validation to archive extraction in main.py (main.py:388,795)
- [x] 41. Add path validation to proton_tools.py tarfile extraction (proton_tools.py:124)
- [x] 42. Fix XSS in display_game_details HTML generation (GameSet.py:605-620)
- [x] 43. Fix get_config_json NoneType crash when config_set not found (GameSet.py:458)
- [x] 44. Fix call_script None result crash (main.py:168)
- [x] 45. Wrap DB connections in try/finally or context managers (GameSet.py get_config_json)
- [x] 46. Clear action cache after download_custom_backend (main.py)
- [x] 47. Remove dead selectPressed/startPressed variables (index.tsx:27-40)
- [x] 48. Fix get_editors crash if game not found (GameSet.py:627)
- [x] 49. Fix sync_saves shell injection via save location name (gog.py:928)
- [x] 50. Add timeout to _refresh_token network call (gog.py:102) — already has timeout=30
- [x] 51. Fix GOG_install find without -print -quit (GOG store.sh:115)
- [x] 52. Check pushd return codes in GOG store.sh (store.sh:114+)
- [x] 53. Fix GOG_run-exe eval validation (GOG store.sh:283) — quote $ID
- [x] 54. Fix echo $TEMP without quotes in all store.sh files (GOG store.sh:48+)
- [x] 55. Fix epic-launcher.sh — LD_PRELOAD directory bug + PULSE_LATENCY_MSEC inverted logic
- [x] 56. Remove epic.py insert_game dead code / connection leak (epic.py:362-364)
- [x] 57. Fix get_logs crash if console_log.txt missing (main.py:996)
- [x] 58. Fix _unload cancelling its own task (main.py:1014)
