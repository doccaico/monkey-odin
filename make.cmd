@echo off

if        "%1" == "debug"       ( goto :DEBUG
) else if "%1" == "release"     ( goto :RELEASE
) else if "%1" == "debug-run"   ( goto :DEBUG_RUN
) else if "%1" == "release-run" ( goto :RELEASE_RUN
) else if "%1" == "test-all"    ( goto :TEST_ALL
) else (
  echo Usage:
  echo     $ make.cmd [debug, release, debug-run, release-run, test-all]
  goto :EOF
)

:DEBUG
  odin build . -debug
goto :EOF

:RELEASE
  odin build . -o:speed
goto :EOF

:DEBUG_RUN
  odin run . -debug
goto :EOF

:RELEASE_RUN
  odin run . -o:speed
goto :EOF

:TEST_ALL
  REM odin test lexer -debug
  odin test parser -debug
goto :EOF

REM vim: foldmethod=marker ft=dosbatch fenc=cp932 ff=dos
