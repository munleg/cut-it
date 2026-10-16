param([int]$Jobs = 2, [string]$OutputName = 'cut-it-windows')
$ErrorActionPreference = 'Stop'
$taskRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$env:Path = "C:\msys64\mingw64\bin;C:\msys64\usr\bin;$env:Path"
$env:PKG_CONFIG_PATH = 'C:/msys64/mingw64/lib/pkgconfig'
$build = Join-Path $taskRoot 'work/native-build'
if ($OutputName -notmatch '^cut-it[-a-z0-9]*$') { throw 'Invalid output folder name' }
$stage = Join-Path $taskRoot "outputs/$OutputName"
$runtime = Join-Path $stage 'runtime'
& cmake -S $PSScriptRoot -B $build -G Ninja '-DCMAKE_BUILD_TYPE=Release' '-DSHOTCUT_VERSION=26.10.13' '-DCMAKE_PREFIX_PATH=C:/msys64/mingw64' '-DCLANG_FORMAT=OFF' '-DSHOTCUT_BUILD_TESTS=ON' "-DCMAKE_INSTALL_PREFIX=$runtime"
if ($LASTEXITCODE) { throw 'CMake configure failed' }
& cmake --build $build --parallel $Jobs
if ($LASTEXITCODE) { throw 'Native build failed' }
New-Item -ItemType Directory -Force "$build/lib", "$build/share" | Out-Null
Copy-Item C:/msys64/mingw64/lib/mlt "$build/lib" -Recurse -Force
Copy-Item C:/msys64/mingw64/share/mlt "$build/share" -Recurse -Force
& ctest --test-dir $build --output-on-failure
if ($LASTEXITCODE) { throw 'Native tests failed' }
& cmake --install $build
if ($LASTEXITCODE) { throw 'Install failed' }
New-Item -ItemType Directory -Force "$stage/lib", "$stage/share" | Out-Null
Copy-Item C:/msys64/mingw64/lib/mlt "$stage/lib" -Recurse -Force
Copy-Item C:/msys64/mingw64/share/mlt "$stage/share" -Recurse -Force
Copy-Item "$build/CuteLogger/libCuteLogger.dll" $runtime -Force
Copy-Item C:/msys64/mingw64/bin/melt.exe,C:/msys64/mingw64/bin/ffmpeg.exe,C:/msys64/mingw64/bin/ffprobe.exe $runtime -Force
Copy-Item "$PSScriptRoot/COPYING", "$PSScriptRoot/CUT-IT.md" $stage -Force
Write-Host "Local development build staged at $stage (requires C:/msys64)."

