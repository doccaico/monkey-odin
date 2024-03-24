@echo off

if        "%1" == "debug"       ( goto :DEBUG
) else if "%1" == "release"     ( goto :RELEASE
) else if "%1" == "debug-run"   ( goto :DEBUG_RUN
) else if "%1" == "release-run" ( goto :RELEASE_RUN
) else if "%1" == "lexer"       ( goto :LEXER
) else if "%1" == "parser"      ( goto :PARSER
) else if "%1" == "ast"         ( goto :AST
) else if "%1" == "evaluator"   ( goto :EVALUATOR
) else if "%1" == "test-all"    ( goto :TEST_ALL
) else (
  echo Usage:
  echo     $ make.cmd [debug, release, debug-run, release-run, test-all
  echo                 lexer, parser, ast, evaluator]
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

:LEXER
  odin test lexer -debug
goto :EOF

:PARSER
  odin test parser -debug
goto :EOF

:AST
  odin test ast -debug
goto :EOF

:EVALUATOR 
  odin test evaluator -debug
goto :EOF

REM :OBJECT
REM   odin test object -debug
REM goto :EOF

:TEST_ALL
  odin test lexer -debug
  odin test parser -debug
  odin test ast -debug
  odin test evaluator -debug
  REM odin test object -debug
goto :EOF

REM vim: foldmethod=marker ft=dosbatch fenc=cp932 ff=dos
