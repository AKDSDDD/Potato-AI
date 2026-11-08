::[Bat To Exe Converter]
::
::YAwzoRdxOk+EWAjk
::fBw5plQjdCqDJEqB5lQ1OghoWhe9NWWuCLAI1P7o0P6SpkIIa+Q9RInazL2NL+5d40brFQ==
::YAwzuBVtJxjWCl3EqQJgSA==
::ZR4luwNxJguZRRnk
::Yhs/ulQjdF+5
::cxAkpRVqdFKZSDk=
::cBs/ulQjdF+5
::ZR41oxFsdFKZSDk=
::eBoioBt6dFKZSDk=
::cRo6pxp7LAbNWATEpCI=
::egkzugNsPRvcWATEpCI=
::dAsiuh18IRvcCxnZtBJQ
::cRYluBh/LU+EWAnk
::YxY4rhs+aU+JeA==
::cxY6rQJ7JhzQF1fEqQJQ
::ZQ05rAF9IBncCkqN+0xwdVs0
::ZQ05rAF9IAHYFVzEqQJQ
::eg0/rx1wNQPfEVWB+kM9LVsJDGQ=
::fBEirQZwNQPfEVWB+kM9LVsJDGQ=
::cRolqwZ3JBvQF1fEqQJQ
::dhA7uBVwLU+EWDk=
::YQ03rBFzNR3SWATElA==
::dhAmsQZ3MwfNWATElA==
::ZQ0/vhVqMQ3MEVWAtB9wSA==
::Zg8zqx1/OA3MEVWAtB9wSA==
::dhA7pRFwIByZRRnk
::Zh4grVQjdCyDJGyX8VAjFB9RSTimM2ivC7AS/PvH/+WTo1kSa8MWRAo0KzxPzGf6AnnUeoIswnVlueJCCQNdHg==
::YB416Ek+ZG8=
::
::
::978f952a14a936cc963da21a135fa983
@echo off
setlocal enabledelayedexpansion
color 0B
title 土豆 AI 启动器
cd /d "%~dp0"

echo ================================================
echo         土豆 AI 启动器 - 基于llama.cpp
echo ================================================
echo.

echo [系统检测] 正在探测您的硬件环境...

set "ENGINE_NAME=CPU_AVX2"
set "ENGINE_DIR=engines\cpu"

:: 1. 检查 NVIDIA
nvidia-smi >nul 2>&1
if !errorlevel!==0 goto :found_nvidia

:: 2. 检查 Intel
powershell -NoProfile -Command "if ((Get-CimInstance Win32_VideoController).Name -match 'Intel') { exit 0 } else { exit 1 }" >nul 2>&1
if !errorlevel!==0 goto :found_intel

:: 3. 兜底 Vulkan
set "ENGINE_NAME=通用_Vulkan"
set "ENGINE_DIR=engines\vulkan"
goto :check_engine

:found_nvidia
set "ENGINE_NAME=NVIDIA_CUDA"
set "ENGINE_DIR=engines\cuda"
goto :check_engine

:found_intel
set "ENGINE_NAME=Intel_SYCL"
set "ENGINE_DIR=engines\sycl"

:check_engine
echo [检测结果] 匹配引擎: !ENGINE_NAME!
echo.

if not exist "!ENGINE_DIR!\llama-server.exe" goto :manual_select
goto :start_scan

:manual_select
color 0E
echo ================================================
echo [警告] 未找到对应的引擎文件！
echo 预期路径: "!ENGINE_DIR!\llama-server.exe"
echo 请确认你的文件夹结构，或者手动选择：
echo ================================================
echo 1. Intel GPU (SYCL) -> 放入 engines\sycl 文件夹
echo 2. NVIDIA GPU (CUDA) -> 放入 engines\cuda 文件夹
echo 3. CPU 模式 (AVX2) -> 放入 engines\cpu 文件夹
echo 4. 通用显卡 (Vulkan) -> 放入 engines\vulkan 文件夹
echo ================================================
set /p manual_choice=请输入序号 (1-4): 

if "!manual_choice!"=="1" set "ENGINE_DIR=engines\sycl"
if "!manual_choice!"=="2" set "ENGINE_DIR=engines\cuda"
if "!manual_choice!"=="3" set "ENGINE_DIR=engines\cpu"
if "!manual_choice!"=="4" set "ENGINE_DIR=engines\vulkan"

if not exist "!ENGINE_DIR!\llama-server.exe" goto :fatal_error
goto :start_scan

:fatal_error
color 0C
echo.
echo [致命错误] 还是找不到 !ENGINE_DIR!\llama-server.exe
echo 请检查你解压的文件夹是不是改名叫 sycl 并放进了 engines 里！
pause
exit /b

:start_scan
if not exist "Models" goto :no_models

echo 正在扫描 Models 文件夹...
echo.
set count=0
for %%f in (Models\*.gguf) do (
    set /a count+=1
    echo   !count!. %%~nxf
    set "model_!count!=%%~ff"
)

if !count!==0 goto :no_models

echo.
echo ================================================
set /p choice=请输入你想运行的模型序号 (1-!count!) 然后回车: 

if not defined model_!choice! (
    color 0C
    echo [错误] 输入无效！
    pause
    exit /b
)

for %%i in (!choice!) do set "SELECTED_MODEL=!model_%%i!"
for %%j in ("!SELECTED_MODEL!") do set "SELECTED_NAME=%%~nxj"

echo.
echo ================================================
echo -启动配置-
echo   计算引擎: !ENGINE_NAME!
echo   加载模型: !SELECTED_NAME!
echo   API 地址: http://127.0.0.1:8089/v1
echo   API KEY ：该本地服务无密钥，可随意填上。
echo   Web 服务：http://127.0.0.1:8089/
echo ================================================
echo.
echo 正在加载模型到显存/内存 (请稍候)...
echo.
echo 可使用键盘 Ctrl + C 或点击页面左上方的红叉退出。
echo （服务正在启动）

if "!ENGINE_DIR!"=="engines\sycl" set ONEAPI_DEVICE_SELECTOR=level_zero:gpu

"!ENGINE_DIR!\llama-server.exe" -m "!SELECTED_MODEL!" -ngl 999 -c 4096 --host 127.0.0.1 --port 8089

echo.
echo 服务已停止。
pause
exit /b

:no_models
color 0C
echo [错误] 未找到 Models 文件夹或其中没有任何 .gguf 模型！
pause
exit /b