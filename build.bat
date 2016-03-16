:loop
@cls
if exist bin\main.exe del /F bin\main.exe
@gprbuild main.gpr -p
@if exist bin\main.exe (
  cd bin
  main.exe show 4 manhattan 2 BN.csv BN2.csv 1.0 2.0
  cd ..
) else (
  echo "No main.exe try again?"
)

@pause
goto loop
