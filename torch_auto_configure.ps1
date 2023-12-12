function print(
    $level,
    $content,
    [System.ConsoleColor] $fore,
    [System.ConsoleColor] $back,
    [switch] $new_line,
    [switch] $time) {
    if ($time) {
        write-host "[" -nonewline
        $datetime = (get-date -format 'yyyy-MM-dd HH:mm:ss')
        write-host $datetime -ForegroundColor:DarkCyan -nonewline
        write-host "]" -nonewline
    }
    if ($level) {
        switch ($level) {
            0 { write-host " DEBUG " -ForegroundColor:DarkGray -nonewline }
            1 { write-host " INFO " -ForegroundColor:DarkGray -nonewline }
            2 { write-host " WARN " -ForegroundColor:Yellow -nonewline }
            3 { write-host " ERROR " -ForegroundColor:Red -nonewline }
            4 { write-host " FATAL " -BackgroundColor:DarkRed -nonewline }
            5 { write-host " SUCCESS " -ForegroundColor:Green -nonewline }
            6 { write-host " FAIL " -ForegroundColor:DarkRed -nonewline }
            default { write-host " $level " -ForegroundColor:Black -BackgroundColor:Gray -nonewline }
        }
    }
    if ($content) {
        if ($fore -and $back) {
            write-host $content -ForegroundColor:$fore -BackgroundColor:$back -nonewline
        }
        elseif ($fore) {
            write-host $content -ForegroundColor:$fore -nonewline
        }
        elseif ($back) {
            write-host $content -BackgroundColor:$back -nonewline
        }
        else {
            write-host $content -nonewline
        }
    }
    if ($new_line) {
        write-host ""
    }
    
}

function overwrite_condarc() {
    $user_name = "unspecified"
    try {
        print -content "正在获取用户名..." -level 1 -time -new_line
        $user_name = (Get-ChildItem Env:\USERNAME).Value
    }
    catch {
        print -content "在获取用户名数据时发生错误! 请确认已经使用管理员权限运行该脚本!" -level 6 -new_line -time
        return 0
    }
    print -content "您的用户名为 " -level 5 -time
    print -content "$user_name" -fore:Cyan -new_line

    $condarc_path = "unspecified"
    try {
        print -content "正在获取用户文件夹..." -level 1 -time -new_line
        $condarc_path = "$env:USERPROFILE\.condarc"
    }
    catch {
        print -content "在获取用户文件夹数据时发生错误! 请确认已经使用管理员权限运行该脚本!" -level 6 -new_line -time
        return 0
    }
    print -content "用户文件夹为 " -level 5 -time
    print -content "$condarc_path" -fore:Cyan -new_line

    print -content "进入文件夹以重写 " -level 1 -time
    print -content ".condarc " -fore:Cyan
    print -content "文件..." -new_line
    $condarc = @"
channels:
    - defaults
show_channel_urls: true
default_channels:
    - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main
    - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/r
    - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/msys2
custom_channels:
    conda-forge: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
    msys2: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
    bioconda: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
    menpo: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
    pytorch: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
    pytorch-lts: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
    simpleitk: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
    deepmodeling: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/
"@
    try {
        print -content "正在重写文件..." -level 1 -time -new_line
        $condarc | out-file -filepath $condarc_path -encoding utf8
    }
    catch {
        print -content "文件重写失败! 请确认对该文件有访问权限!" -level 6 -new_line -time
        return 0
    }
    print -content ".condarc " -level 5 -time -fore:Cyan
    print -content "文件重写成功" -new_line

    try {
        print -content "正在清理Anaconda缓存..." -level 1 -time -new_line
        conda clean --all -y | out-null
    }
    catch {
        print -content "缓存清理失败! 请检查Anaconda安装情况!" -level 6 -new_line -time
        return 0
    }
    print -content "缓存清理成功" -level 5 -time -new_line
    return 1
}

function init_environ() {
    print -content "请输入要创建的虚拟环境名称: " -level 1 -time
    $env_name = read-host
    print -content "请输入要创建的虚拟环境Python版本(3.8): " -level 1 -time
    $env_pyver = read-host
    if ($env_pyver -eq "") {
        $env_pyver = "3.8"
    }
    try {
        if ($env_name -eq "") {
            throw "no-env-name"
        }
        print -content "正在创建虚拟环境: " -level 1 -time
        print -content "$env_name" -fore:DarkYellow
        print -content "..." -new_line
        conda create -n $env_name python=$env_pyver -y | out-null
    }
    catch {
        print -content "在创建虚拟环境时发生错误!请确定环境名合法!" -level 6 -new_line -time
        return 0
    }
    print -content "创建虚拟环境 " -level 5 -time
    print -content "$env_name " -fore:DarkYellow
    print -content "成功" -new_line

    try {
        print -content "正在激活虚拟环境: " -level 1 -time
        print -content "$env_name" -fore:DarkYellow
        print -content "..." -new_line
        conda activate $env_name | out-null
    } 
    catch {
        print -content "在激活虚拟环境时发生错误!请检查Anaconda!" -level 6 -new_line -time
        return 0
    }
    print -content "激活虚拟环境 " -level 5 -time
    print -content "$env_name " -fore:DarkYellow
    print -content "成功" -new_line
    
    try {
        print -content "正在配置虚拟环境 " -level 1 -time
        print -content "$env_name " -fore:DarkYellow
        print -content "的pip源..." -new_line
        pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple | out-null
    } 
    catch {
        print -content "在激活虚拟环境时发生错误!请检查Anaconda!" -level 6 -new_line -time
        return 0
    }
    print -content "修改虚拟环境 " -level 5 -time
    print -content "$env_name " -fore:DarkYellow
    print -content "的pip源成功" -new_line
    return 1
}

function install_torch_packages() {
    print -content "请输入要安装的PyTorch版本(CPU/NVIDIA, 留空为CPU): " -level 1 -time
    $torch_device = read-host
    switch ($torch_device) {
        { $_ -in "CPU", "cpu", "" } {
            try {
                print -content "正在安装 " -level 1 -time
                print -content " PyTorch " -fore:Black -back:DarkYellow
                print -content " CPU " -fore:White -back:DarkBlue
                print -content " 版本..." -new_line
                conda install pytorch torchvision torchaudio cpuonly -c pytorch -y | out-null
            }
            catch {
                print -content "在安装Pytorch时发生错误!请检查Anaconda!" -level 6 -new_line -time
                return 0
            }
            print -content "成功安装 " -level 5 -time
            print -content " PyTorch " -fore:Black -back:DarkYellow
            print -content " CPU " -fore:White -back:DarkBlue
            print -content " 版本" -new_line
        }
        { $_ -in "NVIDIA", "nvidia" } {
            print -content "请输入要安装的CUDA版本(11.8/12.1, 留空为11.8): " -level 1 -time
            $torch_cuver = read-host
            switch ($torch_cuver) {
                { $_ -in "11.8", "" } {
                    try {
                        print -content "正在安装 " -level 1 -time
                        print -content " PyTorch " -fore:Black -back:DarkYellow
                        print -content " CUDA " -fore:White -back:DarkGreen
                        print -content " 11.8 " -fore:White -back:Cyan
                        print -content " 版本..." -new_line
                        conda install pytorch torchvision torchaudio pytorch-cuda=11.8 -c pytorch -c nvidia -y | out-null
                    }
                    catch {
                        print -content "在安装Pytorch时发生错误!请检查Anaconda!" -level 6 -new_line -time
                        return 0
                    }
                    print -content "成功安装 " -level 5 -time
                    print -content " PyTorch " -fore:Black -back:DarkYellow
                    print -content " CUDA " -fore:White -back:DarkGreen
                    print -content " 11.8 " -fore:White -back:Cyan
                    print -content " 版本" -new_line
                }
                "12.1" {
                    try {
                        print -content "正在安装 " -level 1 -time
                        print -content " PyTorch " -fore:Black -back:DarkYellow
                        print -content " CUDA " -fore:White -back:DarkGreen
                        print -content " 12.1 " -fore:White -back:Cyan
                        print -content " 版本..." -new_line
                        conda install pytorch torchvision torchaudio pytorch-cuda=12.1 -c pytorch -c nvidia -y | out-null
                    }
                    catch {
                        print -content "在安装Pytorch时发生错误!请检查Anaconda!" -level 6 -new_line -time
                        return 0
                    }
                    print -content "成功安装 " -level 5 -time
                    print -content " PyTorch " -fore:Black -back:DarkYellow
                    print -content " CUDA " -fore:White -back:DarkGreen
                    print -content " 12.1 " -fore:White -back:Cyan
                    print -content " 版本" -new_line
                }
                default { 
                    print -content "PyTorch Nvidia版本选择不合法!" -level 6 -new_line -time
                    return 0
                }
            }
        }
        default {
            print -content "PyTorch版本选择不合法!" -level 6 -new_line -time
            return 0
        }
    }
    return 1
}

function verify_torch() {
    print -content "正在验证PyTorch是否可用..." -level 1 -time -new_line
    try {
        $v_res = (python -c "import torch;print(torch.cuda.is_available())")
        if ($v_res -eq "True" -or $v_res -eq "False") {
            print -content "PyTorch验证成功" -level 5 -time -new_line
            return 1
        }
        else {
            print -content "PyTorch验证失败" -level 6 -time -new_line
            return 0
        }
    }
    catch {
        print -content "在验证Pytorch时发生错误!请检查Anaconda!" -level 6 -new_line -time
        return 0
    }
}

function display_splash() {
    print -content "+-----------------------------------------------------------------+" -level 1 -time -new_line
    print -content "+-----------Anaconda Auto Configuring Script for PyTorch----------+" -level 1 -time -new_line
    print -content "+-----------------------------------------------------------------+" -level 1 -time -new_line
}

function end_script() {
    print -content "Pytorch 环境已按照步骤配置完毕, 您可以在IDE中进行使用" -level 2 -time -new_line
    print -content "如果在配置中出现来自Anaconda的错误信息, 则无法保证已经安装完成" -level 2 -time -new_line
}

function main() {
    display_splash
    if ($(overwrite_condarc) -eq 0) {
        print -content "重写步骤失败, 脚本退出中..." -level 4 -new_line -time
        return
    }
    if ($(init_environ) -eq 0) {
        print -content "初始化环境失败, 脚本退出中..." -level 4 -new_line -time
        return
    }
    if ($(install_torch_packages) -eq 0) {
        print -content "PyTorch包安装失败, 脚本退出中..." -level 4 -new_line -time
        return
    }
    if ($(verify_torch) -eq 0) {
        print -content "PyTorch包验证失败, 脚本退出中..." -level 4 -new_line -time
        return
    }
    end_script  
}

main
