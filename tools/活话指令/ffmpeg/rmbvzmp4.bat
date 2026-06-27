@echo off
:: 关键：设置编码为UTF-8，解决乱码
chcp 65001 >nul 2>nul
setlocal enabledelayedexpansion

:: ################## 配置区（必改！）##################
:: 1. 填写你的FFmpeg.exe完整路径（例如下面的示例路径）
set "ffmpeg_path=C:\Program Files (x86)\ffmpeg-master-latest-win64-gpl-shared\bin\ffmpeg.exe"
:: 2. 输出文件夹名称（默认在脚本所在目录生成）
set "output_root=ConvertedMP4"
:: ####################################################

:: 1. 检查FFmpeg是否存在（避免路径错误）
if not exist "!ffmpeg_path!" (
    echo 错误：未找到FFmpeg程序！
    echo 当前设置的FFmpeg路径：!ffmpeg_path!
    echo 请确认路径正确，或从 https://ffmpeg.org/ 下载FFmpeg
    pause
    exit /b 1
)

:: 2. 创建输出根目录（不存在则自动创建）
if not exist "!output_root!" (
    mkdir "!output_root!"
    echo 已创建输出文件夹：!output_root!
    echo.
)

:: 3. 统计当前目录及子目录下的rmvb文件总数
set "total_count=0"
for /r %%f in (*.rmvb) do (
    set /a total_count+=1
)

:: 4. 无rmvb文件时直接退出
if !total_count! equ 0 (
    echo 未找到任何.rmvb格式文件，请将脚本放在rmvb文件所在目录！
    pause
    exit /b 0
)

:: 5. 开始批量转换
echo 找到 !total_count! 个rmvb文件，即将开始转换...
echo 输出路径：!cd!\!output_root!
echo.
set "success_count=0"
set "fail_count=0"
set "current_count=0"

:: 遍历所有MKV文件（包括子目录）
for /r %%f in (*.rmvb) do (
    set /a current_count+=1

    :: 检查文件名是否含特殊字符（如冒号，避免"protocol not found"错误）
    echo "%%~nxf" | findstr /r ":" >nul
    if not errorlevel 1 (
        echo [进度：!current_count!/!total_count!] 跳过
        echo 原因：文件名含特殊字符「:」，可能导致错误：%%~nxf
        echo.
        set /a fail_count+=1
        goto next_file  :: 跳过当前文件，处理下一个
    )

    :: 6. 计算输出路径（保持原目录结构）
    :: 例：原路径 C:\Videos\Folder1\a.rmvb → 输出 C:\Videos\ConvertedMP4\Folder1\a.mp4
    set "original_path=%%~dpf"  :: 原文件的目录路径（含盘符）
    set "relative_path=!original_path:%cd%\=!"  :: 相对于脚本所在目录的路径
    set "output_dir=!output_root!\!relative_path!"  :: 输出目录
    set "output_file=!output_dir!%%~nf.mp4"  :: 输出文件名（替换后缀为.mp4）

    :: 7. 创建输出子目录（保持原结构）
    if not exist "!output_dir!" (
        mkdir "!output_dir!"
    )

    :: 8. 显示当前转换信息
    echo [进度：!current_count!/!total_count!] 正在转换
    echo 输入文件：%%f
    echo 输出文件：!output_file!
    echo --------------------------

    :: 9. 调用FFmpeg转换（无损复制，速度快、画质不变）
    "!ffmpeg_path!" -hide_banner -loglevel error -i "%%f" -c:v copy -c:a copy "!output_file!"

    :: 10. 检查转换结果
    if !errorlevel! equ 0 (
        echo 转换成功！
        set /a success_count+=1
    ) else (
        echo 转换失败！
        set /a fail_count+=1
        :: 删除转换失败的空文件（避免残留）
        if exist "!output_file!" del "!output_file!"
    )
    echo.

    :: 标记：跳过含特殊字符的文件后，回到这里继续下一个
    :next_file
)

:: 11. 转换完成，显示统计结果
echo ==========================================
echo 转换全部完成！
echo 总文件数：!total_count! 个
echo 成功：!success_count! 个
echo 失败：!fail_count! 个
echo 输出文件夹：!cd!\!output_root!
echo ==========================================
pause