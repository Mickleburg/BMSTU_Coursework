$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

# Find the MinGW compiler with the C headers and OpenMP runtime.
$searchRoots = @(
    "C:\Program Files\LLVM-mingw",
    "$env:LOCALAPPDATA\Microsoft\WinGet\Packages"
)
$clang = Get-ChildItem $searchRoots -Filter clang.exe -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match "mingw" } |
    Select-Object -First 1 -ExpandProperty FullName
$mpiInclude = "C:\Program Files (x86)\Microsoft SDKs\MPI\Include"
$mpiLib = "C:\Program Files (x86)\Microsoft SDKs\MPI\Lib\x64"

if (-not $clang) {
    throw "LLVM MinGW clang.exe was not found. Install LLVM MinGW, then run this script again."
}
if (-not (Test-Path -LiteralPath (Join-Path $mpiInclude "mpi.h"))) {
    throw "Microsoft MPI SDK was not found."
}

& $clang -O2 -Wall -Wextra -fopenmp solver_openmp.c -o solver_openmp.exe -lm
if ($LASTEXITCODE -ne 0) { throw "OpenMP build failed." }
& $clang -O2 -Wall -Wextra -I $mpiInclude solver_mpi.c -o solver_mpi.exe -L $mpiLib -lmsmpi -lm
if ($LASTEXITCODE -ne 0) { throw "MPI build failed." }

# Keep the OpenMP DLL next to the executable.
$clangBin = Split-Path -Parent $clang
Copy-Item (Join-Path $clangBin "libomp.dll") .\libomp.dll -Force

Write-Host "Build completed."
