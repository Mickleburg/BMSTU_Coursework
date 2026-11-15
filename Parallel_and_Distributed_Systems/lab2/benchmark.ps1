param(
    [int]$N = 16000,
    [double]$Eps = 1e-12
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
$workers = 1, 2, 4, 8, 16
$mpiExec = "C:\Program Files\Microsoft MPI\Bin\mpiexec.exe"
$culture = [Globalization.CultureInfo]::InvariantCulture
$epsText = $Eps.ToString("G", $culture)

if (-not (Test-Path .\solver_openmp.exe) -or -not (Test-Path .\solver_mpi.exe)) {
    throw "Run build.ps1 first."
}

# Run one experiment at a time with the same matrix and epsilon.
New-Item -ItemType Directory -Path results -Force | Out-Null
$rows = @()
$env:OMP_DYNAMIC = "FALSE"
foreach ($count in $workers) {
    foreach ($implementation in @("OpenMP", "MPI")) {
        Write-Host "$implementation, workers=$count"
        if ($implementation -eq "OpenMP") {
            $env:OMP_NUM_THREADS = "$count"
            $output = & .\solver_openmp.exe --n $N --eps $epsText --task known
        } else {
            $output = & $mpiExec -n $count .\solver_mpi.exe --n $N --eps $epsText --task known
        }
        if ($LASTEXITCODE -ne 0) { throw "$implementation failed." }
        # Save the original output before extracting values for the graphs.
        $output | Set-Content "results/$implementation-$count.txt" -Encoding UTF8
        $output | Write-Host
        $values = @{}
        foreach ($line in $output) {
            $pair = $line -split ": ", 2
            if ($pair.Count -eq 2) { $values[$pair[0]] = $pair[1] }
        }
        $time = [double]::Parse(($values["Time"] -replace " s$", ""), $culture)
        $residual = [double]::Parse($values["Relative residual"], $culture)
        if ($values["Converged"] -ne "true" -or $residual -ge $Eps) {
            throw "$implementation did not reach the required accuracy."
        }
        $rows += [PSCustomObject]@{
            implementation = $implementation
            workers = $count
            n = $N
            eps = $epsText
            seconds = $time.ToString("F6", $culture)
            iterations = $values["Iterations"]
            residual = $values["Relative residual"]
            solution_error = $values["Max solution error"]
        }
        # Write after each measurement so completed results are kept.
        $rows | Export-Csv results/times.csv -NoTypeInformation -Encoding UTF8
    }
}
