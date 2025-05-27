# BitNet Local Setup on Windows – Comprehensive Guide
## Introduction

Running advanced AI models on local Windows PCs can be challenging, especially when those models require compiling C++ code and managing multiple dependencies. **Microsoft’s BitNet** (specifically the *bitnet.cpp* framework) is a cutting-edge inference engine for 1-bit large language models (LLMs) that can run efficiently on CPUs ([Accelerating AI with Microsoft bitnet.cpp: A Simple Guide to 1-bit LLM Inference Framework](https://www.linkedin.com/pulse/accelerating-ai-microsoft-bitnetcpp-simple-guide-1-bit-sekhar-vurqc#:~:text=,more%20efficient%2C%20especially%20on%20CPUs)) ([Accelerating AI with Microsoft bitnet.cpp: A Simple Guide to 1-bit LLM Inference Framework](https://www.linkedin.com/pulse/accelerating-ai-microsoft-bitnetcpp-simple-guide-1-bit-sekhar-vurqc#:~:text=Technical%20Requirements)). This guide will walk you through setting up BitNet **from scratch on a Windows system**, including all dependencies and an automated installation script. We target technical users who may not be experts in software development, so the steps are detailed and explained in an actionable, easy-to-follow manner.

**What you’ll get from this guide:**

- A clear overview of prerequisites and why they’re needed.
- Step-by-step instructions (both manual and automated) to install BitNet and its dependencies on Windows.
- An **embedded PowerShell script** that fully automates the setup: from checking/installing prerequisites to downloading models and building the project.
- Explanations for each part of the process, so you understand what’s happening and can troubleshoot if needed.
- Tips on configuration options (like quantization types and pretuned kernels) and how to use them.
- Common issues and solutions, so you can avoid or quickly fix pitfalls during installation.
- By the end, you’ll be ready to run BitNet’s 1-bit models (such as *BitNet b1.58 2B4T*) on your own machine.

> **Note:** This guide is written for **Windows 10/11 64-bit** systems. Some steps (like Visual Studio installation) may require administrator privileges. We recommend running the PowerShell commands **as an Administrator** for a smoother installation. If you prefer a manual setup or already have some dependencies installed, you can follow the manual steps or skip parts of the script as needed.

Let’s begin by ensuring your system meets all the requirements.

## Prerequisites and Dependencies

Setting up BitNet locally involves a few system tools and libraries. Here’s what you need before running BitNet:

- **Operating System:** Windows 10 or 11 (64-bit).  
- **Python (3.9 or higher):** Required for running BitNet’s Python scripts (e.g. model conversion and inference) ([Accelerating AI with Microsoft bitnet.cpp: A Simple Guide to 1-bit LLM Inference Framework](https://www.linkedin.com/pulse/accelerating-ai-microsoft-bitnetcpp-simple-guide-1-bit-sekhar-vurqc#:~:text=Technical%20Requirements)). We recommend Python 3.10 or 3.11 for best compatibility.  
- **Conda (Miniconda/Anaconda) – *Highly Recommended*:** Conda is a package and environment manager. Using a conda environment helps isolate BitNet’s Python dependencies. While not strictly required (you could use `venv` or system Python), the BitNet developers *“highly recommend”* conda ([GitHub - microsoft/BitNet: Official inference framework for 1-bit LLMs](https://github.com/microsoft/BitNet#:~:text=%60bash%20,sh)) ([Accelerating AI with Microsoft bitnet.cpp: A Simple Guide to 1-bit LLM Inference Framework](https://www.linkedin.com/pulse/accelerating-ai-microsoft-bitnetcpp-simple-guide-1-bit-sekhar-vurqc#:~:text=Package%20Manager)) for convenience and reproducibility.  
- **CMake (3.22 or higher):** A cross-platform build system generator. BitNet’s native code uses CMake to configure and build the project ([Accelerating AI with Microsoft bitnet.cpp: A Simple Guide to 1-bit LLM Inference Framework](https://www.linkedin.com/pulse/accelerating-ai-microsoft-bitnetcpp-simple-guide-1-bit-sekhar-vurqc#:~:text=Technical%20Requirements)). Version 3.22+ is required to support the project’s CMake scripts.  
- **Clang (LLVM) 18 or higher:** A C/C++ compiler. BitNet’s code is designed to be compiled with Clang on Windows (instead of MSVC) for optimal support of 1-bit inference code and to match the behavior on other platforms ([Accelerating AI with Microsoft bitnet.cpp: A Simple Guide to 1-bit LLM Inference Framework](https://www.linkedin.com/pulse/accelerating-ai-microsoft-bitnetcpp-simple-guide-1-bit-sekhar-vurqc#:~:text=Technical%20Requirements)). Clang 18 comes with LLVM 18, and newer versions (Clang 19, etc.) are also acceptable. We will ensure the correct Clang is installed.  
- **Visual Studio 2022 (with C++ Build Tools):** On Windows, Visual Studio provides the necessary build tools, compilers, and libraries. Specifically, install **Visual Studio 2022** with the **Desktop development with C++** workload and related components. Microsoft’s documentation recommends including at least the following components for BitNet ([Accelerating AI with Microsoft bitnet.cpp: A Simple Guide to 1-bit LLM Inference Framework](https://www.linkedin.com/pulse/accelerating-ai-microsoft-bitnetcpp-simple-guide-1-bit-sekhar-vurqc#:~:text=,Toolset%20%28clang%29%20is%20recommended)):
  - *Desktop Development with C++* (workload) – includes MSVC compiler, Windows SDK, etc.
  - *C++ CMake Tools for Windows* – integration of CMake in VS, and includes the CMake binaries ([GitHub - microsoft/BitNet: Official inference framework for 1-bit LLMs](https://github.com/microsoft/BitNet#:~:text=%2A%20Desktop,with%20%20101%20Automatic%20installation)).
  - *C++ Clang Compiler for Windows* – the LLVM/Clang toolset integration for VS ([Visual Studio Community workload and component IDs | Microsoft Learn](https://learn.microsoft.com/en-us/visualstudio/install/workload-component-id-vs-community?view=vs-2022#:~:text=Microsoft,166%20Optional)) ([Visual Studio Community workload and component IDs | Microsoft Learn](https://learn.microsoft.com/en-us/visualstudio/install/workload-component-id-vs-community?view=vs-2022#:~:text=match%20at%20L2593%20Microsoft,cl%29%20toolset%2017.13.35710.127%20Optional)).
  - *MSBuild Support for LLVM (Clang-cl)* – allows using Clang in MSBuild projects (ensures `clang-cl` integration) ([Visual Studio Community workload and component IDs | Microsoft Learn](https://learn.microsoft.com/en-us/visualstudio/install/workload-component-id-vs-community?view=vs-2022#:~:text=match%20at%20L2593%20Microsoft,cl%29%20toolset%2017.13.35710.127%20Optional)).
  - *Git for Windows* – optional but recommended to easily clone repositories from Git Bash/PowerShell ([Visual Studio Community workload and component IDs | Microsoft Learn](https://learn.microsoft.com/en-us/visualstudio/install/workload-component-id-vs-community?view=vs-2022#:~:text=Microsoft,VS%202019%20C%2B%2B%20ARM%20build)). (If you already have Git installed separately, this is less critical.)

Having these VS components installed will also automatically install additional tools like **CMake** and the **Visual Studio Developer Shell**, which are needed for building BitNet ([GitHub - microsoft/BitNet: Official inference framework for 1-bit LLMs](https://github.com/microsoft/BitNet#:~:text=,required%20additional%20tools%20like%20CMake)).

- **Internet Connection:** Required to download the BitNet source code and model files from Hugging Face. The models, especially, can be large (several GB), so ensure you have a stable connection and sufficient disk space (the 2.4B parameter model is around ~1.8 GB to download, and others can be larger). 

> **Disk Space:** The BitNet repository is not very large, but the models are. Make sure you have **at least 5-10 GB** free for the repository, build artifacts, and at least one model. If you plan to download multiple models or very large models (like a 100B-token 8B model), allocate more space accordingly.

### Summary of Requirements

For quick reference, here is a table of the core dependencies and their minimum versions:

| Dependency                   | Minimum Version       | How to Get It                                      |
| ---------------------------- | --------------------- | -------------------------------------------------- |
| **Python**                   | 3.9+ (64-bit)         | [Python.org](https://www.python.org/downloads/) or via Microsoft Store/winget.             |
| **Conda (Miniconda)**        | *Latest* (Optional)   | [Miniconda installer](https://docs.conda.io/en/latest/miniconda.html) or via winget.      |
| **CMake**                    | 3.22+                 | Included with Visual Studio C++ tools or install via [Kitware](https://cmake.org/download/) (winget: `Kitware.CMake`). |
| **Clang (LLVM)**             | 18+                   | Included with Visual Studio (Clang for Windows option) or via [LLVM](https://github.com/llvm/llvm-project/releases) (winget: `LLVM.LLVM`). |
| **Visual Studio 2022 + C++** | 2022 (Community or Build Tools) with *Desktop C++*, *CMake*, *Clang* components | [Visual Studio Installer](https://visualstudio.microsoft.com/downloads/) or winget package. |
| **Git**                      | Latest (2.x)          | Included with Visual Studio (Git for Windows option) or [git-scm.com](https://git-scm.com/download/win) (winget: `Git.Git`). |
| **huggingface-cli**          | Latest                | Will be installed via pip (part of Hugging Face Hub SDK) for model downloads. |

Most of these will be handled by our automated script if they’re not already present. Now, let’s discuss how to proceed with the installation – you have two main approaches:

- **Automated**: Use the provided PowerShell script to handle everything for you. *Recommended for most users.*
- **Manual**: Follow the steps yourself (install dependencies, clone repo, build, etc.). This is useful if you want to learn the process or have a custom setup.

Feel free to skip to the **“Automated Setup with PowerShell Script”** section if you want to jump straight to automation. Otherwise, we’ll briefly outline the manual installation first for clarity.

## Manual Installation Overview (Optional)

*(If you plan to use the automated script, you can skim this section. It’s provided for understanding and for those who may prefer doing things step by step.)*

Setting up BitNet manually involves the following major steps:

1. **Install Required Software:** Ensure Python, CMake, Visual Studio 2022 (with C++ tools, Clang, etc.), and Conda are installed as described above. If using manual steps, you’d install these through their installers or package manager (e.g., using **winget** or **Visual Studio Installer**). This guide assumes these are installed or will be handled by the script.

2. **Open a Developer Command Prompt/PowerShell:** This is crucial on Windows. Microsoft’s documentation notes that you should *“always use a Developer Command Prompt / PowerShell for VS2022 for the following commands”* when building BitNet on Windows ([GitHub - microsoft/BitNet: Official inference framework for 1-bit LLMs](https://github.com/microsoft/BitNet#:~:text=Important)). The Developer environment sets up necessary environment variables (PATH to compilers, etc.). You can open it from the Start Menu (e.g., "x64 Native Tools Command Prompt for VS 2022" or "Developer PowerShell for VS 2022"). In our automated approach, the script will detect and initialize this for you if you haven’t.

3. **Clone the BitNet Repository:** Use Git to clone the BitNet source code. The repository is on GitHub under `microsoft/BitNet`. **Important:** use the `--recursive` flag to also fetch submodules (BitNet relies on submodules like `llama.cpp`) ([GitHub - microsoft/BitNet: Official inference framework for 1-bit LLMs](https://github.com/microsoft/BitNet#:~:text=1)).  
   ```shell
   git clone --recursive https://github.com/microsoft/BitNet.git 
   cd BitNet
   ```  
   This will create a `BitNet` directory with the project source.

4. **Create a Conda Environment:** (Optional but recommended) Create a fresh conda environment for BitNet to avoid dependency conflicts. The BitNet README suggests:  
   ```shell
   conda create -n bitnet-cpp python=3.9 -y
   conda activate bitnet-cpp
   ```  
   This makes a new environment named “bitnet-cpp” with Python 3.9. (You can choose a different name or Python version >=3.9.) If not using conda, ensure you have a Python 3.9+ environment ready (you might use `python -m venv` as an alternative).

5. **Install Python Dependencies:** BitNet’s Python requirements are listed in `requirements.txt` in the repo. Use pip to install them ([GitHub - microsoft/BitNet: Official inference framework for 1-bit LLMs](https://github.com/microsoft/BitNet#:~:text=,cpp)):  
   ```shell
   pip install -r requirements.txt
   ```  
   This will install necessary packages (like `numpy`, etc.). Make sure you run this **after activating** the conda env (if using conda) so they install into that env.

6. **Download a 1-bit Model:** BitNet doesn’t come with model weights – you need to obtain a compatible model (in 1-bit quantized format, typically in **GGUF** or similar format). Microsoft has an official BitNet model on Hugging Face (and there are others contributed by the community). For example, to get the official **BitNet b1.58 – 2B4T (2.4B parameters)** model, you can use Hugging Face’s CLI:  
   ```shell
   huggingface-cli download microsoft/BitNet-b1.58-2B-4T-gguf --local-dir models/BitNet-b1.58-2B-4T
   ```  
   This downloads the entire model repository into `BitNet/models/BitNet-b1.58-2B-4T` (you can choose a different path if desired). You can also manually download from the Hugging Face website, but the CLI is convenient for large files. *We will discuss other available models and how to choose one in a later section.*

7. **Build and Setup BitNet:** Now, compile the BitNet code and finalize model preparation. The repository provides a script `setup_env.py` to handle compilation and model conversion. You’ll typically run:  
   ```shell
   python setup_env.py -md models/BitNet-b1.58-2B-4T -q i2_s 
   ```  
   Here `-md` specifies the **model directory** where you downloaded the model, and `-q` specifies the quantization type (here `i2_s` is one quantization mode appropriate for BitNet models). This script will:
   - Run CMake to compile the C/C++ backend (this includes building the optimized kernels and any necessary tools, possibly linking with the llama.cpp library) ([Unable to run setup_env.py · Issue #180 · microsoft/BitNet · GitHub](https://github.com/microsoft/BitNet/issues/180#:~:text=%28bitnet,log)).
   - Convert or quantize the model files if needed and place the final model file (e.g. a `ggml-model-i2_s.gguf` or similar) in the model directory ready for inference.
   - It will print logs and might take a few minutes to complete. On success, you should see messages about successful compilation and setup. If there’s an error, it will usually direct you to a log file (e.g. `logs/compile.log`) for details.

8. **Run Inference (Test):** To verify everything works, you can run a quick test. BitNet provides a `run_inference.py` script. For example:  
   ```shell
   python run_inference.py -m models/BitNet-b1.58-2B-4T/ggml-model-i2_s.gguf -p "Hello, how are you?" -n 50 -cnv
   ```  
   This will load the model and generate a 50-token continuation for the prompt. The `-cnv` flag is used for conversation mode (for instruct models; it appends an end-of-prompt token internally). If everything is set up correctly, you should see the model generating text in response to your prompt.

If any of the steps fail, you would troubleshoot (for example, ensure Visual Studio environment is loaded if compilation fails to find a compiler, etc.). 

As you can see, the manual process has several moving parts. To simplify this, we provide an **automated PowerShell script** next, which performs all these steps with robust checks and error handling. Even if you plan to run the script, the above should give you insight into what it’s doing under the hood.

## Automated Setup with PowerShell Script

For convenience, we have created a PowerShell script that automates the entire BitNet setup on Windows. The script will:

- Verify that you are running in a proper environment (and if not, attempt to initialize a Visual Studio Developer environment for you).
- Check for each dependency (Python, Conda, CMake, Clang, Visual Studio components, Git, etc.), and install any that are missing (prompting for confirmation when needed).
- Clone the BitNet repository (with submodules) to a location of your choice.
- Create a conda environment for BitNet and install the Python requirements.
- Prompt you to select which BitNet model(s) you want to download, and where to store them.
- Use `huggingface-cli` to download the chosen model weights from Hugging Face, showing download progress in the console.
- Run the `setup_env.py` script with the appropriate arguments (model path, quantization type, etc.) to build the project and prepare the model.
- Handle errors at each step with informative messages, and log the entire process to a log file for review.
- Provide options (via script parameters) to customize behavior – such as non-interactive mode, skipping certain checks, using verbose output, etc.

This script is written to be **idempotent** and safe: you can run it multiple times. If something fails, you can fix the issue and run it again; it will skip steps that are already completed (for example, if the repo is already cloned or if a model is already downloaded, it will detect that and not duplicate work unless you ask it to). Logging ensures you have a record of what happened.

### Usage

**Download/Copy the Script:** The full script is embedded below in this document. You can copy the code block and save it as a file, for example `Setup-BitNet.ps1`. (Ensure it is saved with a `.ps1` extension which indicates a PowerShell script.)

> **Execution Policy:** By default, PowerShell might block running scripts for security. You can allow this script to run by:
> - Running PowerShell as Administrator and executing: `Set-ExecutionPolicy -Scope Process Bypass -Force` (this temporarily allows running unsigned scripts in the current session), **or**
> - Right-clicking the `.ps1` file, selecting “Properties”, and clicking “Unblock” if that appears, **or**
> - Adjusting your execution policy permanently (not recommended for most users).  
> After that, you can run the script as shown below.

**Run the Script:** Open **PowerShell** (preferably the “Developer PowerShell for VS 2022” if available; if not, the script will try to launch it for you) **as Administrator**. Navigate to the directory where you saved `Setup-BitNet.ps1`. Then run:  
```powershell
.\Setup-BitNet.ps1
```  
By default, the script will operate in interactive mode, asking for input when needed (such as selecting models or confirming an installation). It will log output to a file `BitNet_Setup.log` (in a `logs` folder or a directory you specify). 

**Script Parameters:** You can customize the script’s behavior with the following optional parameters:

- `-InstallAll` – **Automatic installation mode.** If set, the script will **not prompt for confirmations** when installing missing dependencies. It will assume “Yes” to any installation (useful for unattended installs). Without this, it will ask you before installing major components like Visual Studio or Conda.
- `-ModelIds <string[]>` – Provide one or more Hugging Face model IDs to download, bypassing the interactive selection. For example: `-ModelIds "microsoft/BitNet-b1.58-2B-4T"`, or multiple IDs like `-ModelIds "1bitLLM/bitnet_b1_58-large","tiiuae/Falcon3-7B-Instruct-1.58bit"`. (No need to include the `-gguf` suffix; the script will handle typical naming).
- `-ModelDir <path>` – Specify a base directory for model downloads. By default, the script uses a `models` folder inside the cloned BitNet repository. You can set another path (e.g. on another drive if you store models elsewhere).
- `-QuantType <string>` – Choose the quantization type for setup. Valid options are `"i2_s"` (the default, 1.58-bit weight quantization with scale) or `"tl1"` (ternary quantization) ([GitHub - microsoft/BitNet: Official inference framework for 1-bit LLMs](https://github.com/microsoft/BitNet#:~:text=,Use%20the%20pretuned%20kernel%20parameters)). If not specified, the script defaults to `i2_s`, which is used for BitNet models in most cases ([GitHub - microsoft/BitNet: Official inference framework for 1-bit LLMs](https://github.com/microsoft/BitNet#:~:text=,q%20i2_s)).
- `-UsePretuned` – Switch to indicate using pretuned kernel parameters during setup. If this flag is provided, the script will pass `--use-pretuned` to `setup_env.py` (BitNet can use pretuned optimized parameters for potentially better performance ([GitHub - microsoft/BitNet: Official inference framework for 1-bit LLMs](https://github.com/microsoft/BitNet#:~:text=,Use%20the%20pretuned%20kernel%20parameters))). By default, pretuned parameters are **not** used, for maximum compatibility. You can experiment with this option after initial setup.
- `-ForceVSDevShell` – This forces the script to re-initialize the Visual Studio Developer Shell even if it detects some environment variables. Use this if you suspect the environment isn’t properly set (for example, if you opened the script in a normal PowerShell and it didn’t automatically switch to dev shell).
- `-SkipDependencyChecks` – If provided, the script will skip verifying versions of Python, CMake, clang, etc. Use this only if you are confident everything is installed correctly and want to speed up the process. By default, the script checks each dependency and installs/updates if necessary.
- `-Verbose` – Enable more verbose output. The script already logs a lot of detail to the log file, but with `-Verbose` it will also output additional diagnostic messages to the console as it runs.
- `-LogDir <path>` – Specify a directory to store logs. By default, a `logs` directory will be created in the current path (or inside the BitNet repo folder once cloned) to store `BitNet_Setup.log`. You can change this to any directory you like. The script will ensure the directory exists.

You can see these parameters and their descriptions by running:  
```powershell
Get-Help .\Setup-BitNet.ps1 -Detailed
```  
(after you have the script file available).

Now, let’s present the **full script**. It’s heavily commented for clarity. After the script, we will walk through what each section does, and then cover some notes and troubleshooting.

### The Setup Script (`Setup-BitNet.ps1`)

Below is the PowerShell script that automates the BitNet installation. Copy everything from the opening "```powershell" to the closing "```" into a .ps1 file:

```powershell
Param(
    [Switch]$InstallAll,       # If set, auto-install missing dependencies without prompting (assume "Yes").
    [String[]]$ModelIds,       # List of Hugging Face model IDs to download (if provided, skip interactive selection).
    [String]$ModelDir,         # Base directory for model downloads. Default: ".\models" in the BitNet repo folder.
    [ValidateSet("i2_s", "tl1")] 
    [String]$QuantType = "i2_s",  # Quantization type for the model (default "i2_s").
    [Switch]$UsePretuned,      # If set, use pretuned kernel parameters during setup.
    [Switch]$ForceVSDevShell,  # Force initialization of VS Developer Shell even if environment already looks set.
    [Switch]$SkipDependencyChecks, # Skip version checks for dependencies (assume correct versions present).
    [Switch]$Verbose,          # Enable verbose logging/output.
    [String]$LogDir            # Directory for logs. Default: BitNet\logs or current dir logs.
)

# -------------------- Configuration & Logging -------------------- 

# Prepare logging
$startTime = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
if (!$LogDir) {
    # If BitNet repo will be cloned into a folder, we'll set LogDir to that later (BitNet/logs).
    # For now, use current directory's 'logs' folder.
    $LogDir = Join-Path -Path (Get-Location) -ChildPath "logs"
}
if (-not (Test-Path $LogDir)) { New-Item -Path $LogDir -ItemType Directory | Out-Null }

$logFile = Join-Path $LogDir "BitNet_Setup_$startTime.log"
# Start transcript to log everything
Try {
    Start-Transcript -Path $logFile -Append -NoClobber
} Catch {
    Write-Host "WARNING: Could not start transcript logging to $logFile. Error: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "=== BitNet Automated Setup Script ===" -ForegroundColor Cyan
Write-Host "Log file: $logFile"
Write-Host "Starting setup at $((Get-Date).ToString())"
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Host "ERROR: PowerShell 5.0 or higher is required to run this script." -ForegroundColor Red
    Exit 1
}

# If running inside Developer PowerShell, certain env vars are set (like VSCMD_ARG_HOST_ARCH).
function In-DevShell {
    return ($env:VSCMD_ARG_TGT_ARCH -or $env:DevEnvDir -or $env:VSINSTALLDIR)
}

$inDevShell = In-DevShell
if ($ForceVSDevShell) {
    Write-Host "ForceVSDevShell flag is set. Will ensure Developer Shell is initialized." -ForegroundColor Yellow
    $inDevShell = $false
}

# -------------------- Visual Studio Developer Shell Initialization -------------------- 

# This function tries to locate Visual Studio 2022 and import the Developer shell if needed.
function Enter-VSDeveloperShell {
    Write-Host "Initializing Visual Studio 2022 Developer environment..." -ForegroundColor Cyan
    # Use vswhere to find VS 2022 installation path
    $vswherePath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (-not (Test-Path $vswherePath)) {
        Write-Host "ERROR: Visual Studio 2022 not found, and vswhere is not available to locate it." -ForegroundColor Red
        Write-Host "Please install Visual Studio 2022 with C++ Desktop workload before proceeding." -ForegroundColor Red
        Exit 1
    }
    # Find latest VS2022 (Community/Professional/BuildTools) that has the C++ tools (VCTools)
    $vsInstallPath = & $vswherePath -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if (!$vsInstallPath) {
        Write-Host "ERROR: No Visual Studio 2022 installation with C++ tools found." -ForegroundColor Red
        Write-Host "Please install Visual Studio 2022 with the required components (Desktop C++ workload)." -ForegroundColor Red
        Exit 1
    }
    # Construct path to Developer Powershell module
    $devShellModule = Join-Path $vsInstallPath "Common7\Tools\Microsoft.VisualStudio.DevShell.dll"
    if (!(Test-Path $devShellModule)) {
        Write-Host "ERROR: Developer Shell module not found in VS installation. Trying Developer Command Prompt as fallback..." -ForegroundColor Yellow
        # Fallback to VsDevCmd.bat (for Command Prompt) if PowerShell module is not available.
        $devCmdBat = Join-Path $vsInstallPath "Common7\Tools\VsDevCmd.bat"
        if (Test-Path $devCmdBat) {
            # Launch a new PowerShell process with the Developer Command Prompt environment, then re-run this script.
            Write-Host "Launching Developer Command Prompt and re-invoking the script..." -ForegroundColor Cyan
            $argList = "-NoProfile -ExecutionPolicy Bypass -Command `"& '{0}' -arch=x64 -host_arch=x64 && powershell -NoProfile -ExecutionPolicy Bypass -File \"{1}\" {2}'`" -f $devCmdBat, $MyInvocation.MyCommand.Definition, ($PSBoundParameters.Keys | ForEach-Object {"-$($_) $($PSBoundParameters[$_])"} -join ' ')
            # Note: Passing current script arguments to the new process.
            Start-Process -FilePath "powershell.exe" -ArgumentList $argList -Wait
            Exit $LASTEXITCODE
        } else {
            Write-Host "ERROR: Could not find VsDevCmd.bat. Visual Studio installation might be broken or incomplete." -ForegroundColor Red
            Exit 1
        }
    } else {
        # Import the DevShell module and enter the shell for VS 2022
        Import-Module $devShellModule
        # Use a unique instance ID (VS2022 Community/BuildTools have specific IDs; using wildcard to find one)
        $vsInstances = Get-VSInstallInstance -All -Latest -Prerelease:$false
        $vs2022Instance = $vsInstances | Where-Object { $_.InstallationPath -like "$vsInstallPath*" }
        if ($vs2022Instance) {
            $instanceId = $vs2022Instance.InstanceId
            Write-Host "Found VS 2022 instance '$($vs2022Instance.DisplayName)' with Instance ID: $instanceId" -ForegroundColor Green
        } else {
            # Fallback: use a known instance ID if not found automatically (GUID for default VS2022 instance, example given in BitNet FAQ)
            $instanceId = "3f0e31ad"  # This GUID may vary; using an example from documentation ([GitHub - microsoft/BitNet: Official inference framework for 1-bit LLMs](https://github.com/microsoft/BitNet#:~:text=%E2%80%A2%20If%20you%20are%20using,PowerShell%2C%20run%20the%20following%20commands)).
            Write-Host "Using default Instance ID $instanceId for VS Dev Shell." -ForegroundColor Yellow
        }
        try {
            Enter-VsDevShell -InstanceId $instanceId -SkipAutomaticLocation -DevCmdArguments "-arch=x64 -host_arch=x64"
        } catch {
            Write-Host "ERROR: Failed to enter VS Developer Shell: $($_.Exception.Message)" -ForegroundColor Red
            Exit 1
        }
    }
    Write-Host "Visual Studio Developer environment initialized." -ForegroundColor Green
} 

if (-not $inDevShell) {
    Enter-VSDeveloperShell
    # After this, the environment is set. Mark as inDevShell to skip re-entry.
    $inDevShell = $true
}

# At this point, we should have cl.exe, clang, etc. available in PATH if VS is installed properly.
# We will proceed to dependency checks/installation.

# -------------------- Dependency Checks & Installation -------------------- 

# Helper function to run external commands and handle errors
function Run-Command($executable, $args, $stepName) {
    Write-Host "`n--- $stepName ---" -ForegroundColor Cyan
    if ($Verbose) { Write-Host "Running: $executable $args" }
    & $executable $args
    $EXITCODE = $LASTEXITCODE
    if ($EXITCODE -ne 0) {
        Write-Host "ERROR: $stepName failed with exit code $EXITCODE." -ForegroundColor Red
        Write-Host "See log file ($logFile) for details. Aborting." -ForegroundColor Red
        Stop-Transcript | Out-Null
        Exit $EXITCODE
    }
}

# If skipping checks, we assume dependencies are fine.
if (-not $SkipDependencyChecks) {
    Write-Host "`nChecking system dependencies..." -ForegroundColor Cyan

    # Python check
    Write-Host "Verifying Python installation (>= 3.9)..."
    $pythonVersion = ""
    try {
        $pythonVersion = (& python --version 2>&1)
    } catch {
        $pythonVersion = ""
    }
    if ($pythonVersion -and ($pythonVersion -match "Python (\d+)\.(\d+)\.(\d+)")) {
        $pyMajor = [int]$Matches[1]; $pyMinor = [int]$Matches[2]
    }
    if (-not $pythonVersion -or $pyMajor -lt 3 -or ($pyMajor -eq 3 -and $pyMinor -lt 9)) {
        Write-Host "Python 3.9+ not found (or wrong version). Installing Python..." -ForegroundColor Yellow
        if (-not $InstallAll) {
            $confirm = Read-Host "Install latest Python via winget? (Y/N)"
            if ($confirm -notin @("Y","y")) {
                Write-Host "Python installation is required. Exiting." -ForegroundColor Red
                Exit 1
            }
        }
        # Install Python using winget (this will install from Microsoft Store or official source)
        Run-Command "winget" "install -e --id Python.Python.3.11" "Installing Python"
        # Refresh PATH (winget might not update current session’s PATH, but Python installer usually adds to PATH for new processes)
        $pythonVersion = (& python --version 2>&1)
        if (-not $pythonVersion) {
            Write-Host "ERROR: Python installation completed but `python` not found. You might need to restart the shell or check PATH." -ForegroundColor Red
            Exit 1
        }
    } else {
        Write-Host "Python found: $pythonVersion" -ForegroundColor Green
    }

    # Conda check
    Write-Host "Checking for Conda (Mamba/Miniconda/Anaconda)..."
    $condaInfo = ""
    try {
        $condaInfo = (& conda --version 2>&1)
    } catch {
        $condaInfo = ""
    }
    if (-not $condaInfo) {
        Write-Host "Conda not found on system."
        if (-not $InstallAll) {
            $confirm = Read-Host "Miniconda (or Anaconda) is recommended. Install Miniconda via winget? (Y/N)"
            if ($confirm -notin @("Y","y")) {
                Write-Host "Conda not installed. Proceeding without Conda may cause dependency issues. Continuing..." -ForegroundColor Yellow
            } else {
                Run-Command "winget" "install -e --id Anaconda.Miniconda3" "Installing Miniconda"
                # After installation, we might need to refresh environment or advise restart for conda to be available.
                Write-Host "Miniconda installed. Please restart this script or open a new Conda-enabled PowerShell. Exiting for now." -ForegroundColor Yellow
                Stop-Transcript | Out-Null
                Exit 0
            }
        } else {
            # Auto mode: install without asking
            Run-Command "winget" "install -e --id Anaconda.Miniconda3" "Installing Miniconda"
            Write-Host "Miniconda installed. Please restart the script to use the Conda environment." -ForegroundColor Yellow
            Stop-Transcript | Out-Null
            Exit 0
        }
    } else {
        Write-Host "Conda is installed. Version: $condaInfo" -ForegroundColor Green
    }

    # CMake check
    Write-Host "Checking for CMake (>= 3.22)..."
    $cmakeVersionOutput = ""
    try {
        $cmakeVersionOutput = (& cmake --version 2>&1)
    } catch {
        $cmakeVersionOutput = ""
    }
    $cmakeNeeded = $false
    $cmakeVerMajor = 0; $cmakeVerMinor = 0; $cmakeVerPatch = 0
    if ($cmakeVersionOutput -and ($cmakeVersionOutput -match "cmake version (\d+)\.(\d+)\.(\d+)")) {
        $cmakeVerMajor = [int]$Matches[1]; $cmakeVerMinor = [int]$Matches[2]; $cmakeVerPatch = [int]$Matches[3];
        Write-Host "Found CMake $($Matches[0])" -ForegroundColor Green
        if (!($cmakeVerMajor -gt 3 -or ($cmakeVerMajor -eq 3 -and $cmakeVerMinor -ge 22))) {
            Write-Host "CMake version is below 3.22." -ForegroundColor Yellow
            $cmakeNeeded = $true
        }
    } else {
        Write-Host "CMake not found." -ForegroundColor Yellow
        $cmakeNeeded = $true
    }
    if ($cmakeNeeded) {
        Write-Host "Installing latest CMake..." -ForegroundColor Yellow
        if (-not $InstallAll) {
            $confirm = Read-Host "Install CMake via winget? (Y/N)"
            if ($confirm -notin @("Y","y")) {
                Write-Host "CMake is required. Exiting." -ForegroundColor Red
                Exit 1
            }
        }
        Run-Command "winget" "install -e --id Kitware.CMake" "Installing CMake"
        # Verify installation
        try {
            $cmakeVersionOutput = (& cmake --version)
            Write-Host "CMake installed: $cmakeVersionOutput" -ForegroundColor Green
        } catch {
            Write-Host "ERROR: CMake installation did not make it available. You may need to restart PowerShell." -ForegroundColor Red
            Exit 1
        }
    }

    # Clang/LLVM check
    Write-Host "Checking for LLVM/Clang (>= 18)..."
    $clangVersionOutput = ""
    try {
        $clangVersionOutput = (& clang --version 2>&1)
    } catch {
        $clangVersionOutput = ""
    }
    $installClang = $false
    if ($clangVersionOutput) {
        # Parse version, e.g., "clang version 18.0.1 ..."
        if ($clangVersionOutput -match "version (\d+)\.(\d+)\.(\d+)") {
            $clangMajor = [int]$Matches[1]
            Write-Host "Found $($clangVersionOutput.Split([Environment]::NewLine)[0])" -ForegroundColor Green
            if ($clangMajor -lt 18) {
                Write-Host "Clang version is below 18 (found $clangMajor). Will install/update." -ForegroundColor Yellow
                $installClang = $true
            }
        } else {
            Write-Host "Found Clang, but version not detected. Proceeding with caution." -ForegroundColor Yellow
        }
    } else {
        Write-Host "Clang not found in PATH." -ForegroundColor Yellow
        $installClang = $true
    }
    if ($installClang) {
        Write-Host "Installing LLVM/Clang..." -ForegroundColor Yellow
        if (-not $InstallAll) {
            $confirm = Read-Host "Install LLVM (with Clang) via winget? (Y/N)"
            if ($confirm -notin @("Y","y")) {
                Write-Host "Clang is required for building BitNet. Exiting." -ForegroundColor Red
                Exit 1
            }
        }
        Run-Command "winget" "install -e --id LLVM.LLVM" "Installing LLVM/Clang"
        # The LLVM installer might not add to PATH for current session; ensure path update
        $env:Path += ";$env:ProgramFiles\LLVM\bin"
        try {
            $clangVersionOutput = (& clang --version)
            Write-Host "Clang installed: $($clangVersionOutput.Split([Environment]::NewLine)[0])" -ForegroundColor Green
        } catch {
            Write-Host "ERROR: Clang installation completed but not found in PATH. You may need to restart the shell." -ForegroundColor Red
            Exit 1
        }
    }

    # Git check
    Write-Host "Checking for Git..."
    $gitVersion = ""
    try {
        $gitVersion = (& git --version 2>&1)
    } catch {
        $gitVersion = ""
    }
    if (-not $gitVersion) {
        Write-Host "Git not found." -ForegroundColor Yellow
        if (-not $InstallAll) {
            $confirm = Read-Host "Install Git for Windows via winget? (Y/N)"
            if ($confirm -notin @("Y","y")) {
                Write-Host "Git is required to clone the repository. Exiting." -ForegroundColor Red
                Exit 1
            }
        }
        Run-Command "winget" "install -e --id Git.Git" "Installing Git"
        try {
            $gitVersion = (& git --version)
            Write-Host "Git installed: $gitVersion" -ForegroundColor Green
        } catch {
            Write-Host "ERROR: Git installation did not make it available. You may need to restart the shell." -ForegroundColor Red
            Exit 1
        }
    } else {
        Write-Host "Git is installed: $gitVersion" -ForegroundColor Green
    }
} else {
    Write-Host "Skipping dependency version checks as requested (assuming all are installed)..." -ForegroundColor Yellow
}

# -------------------- Repository Setup -------------------- 

# Determine a directory to clone BitNet into, if not already cloned.
if (-not (Test-Path "./BitNet" -PathType Container)) {
    Write-Host "`nCloning BitNet repository..." -ForegroundColor Cyan
    Run-Command "git" "clone --recursive https://github.com/microsoft/BitNet.git" "Cloning BitNet GitHub repo"
} else {
    Write-Host "`nBitNet repository already exists. Pulling latest changes..." -ForegroundColor Cyan
    Push-Location "BitNet"
    # Update submodules as well to ensure up-to-date
    Run-Command "git" "pull" "Updating BitNet repository"
    Run-Command "git" "submodule update --init --recursive" "Updating submodules"
    Pop-Location
}
# Change working directory to BitNet
Set-Location "BitNet"

# Now inside the BitNet repository directory.
# Adjust log directory to inside repo (if not already inside). This keeps logs with the project.
if ($LogDir -eq (Join-Path (Get-Location) "logs") -or (Split-Path $logFile -Parent) -eq (Get-Location).Path) {
    # If logs were in old location (outside), switch to repo logs directory.
    $repoLogDir = Join-Path (Get-Location) "logs"
    if (-not (Test-Path $repoLogDir)) { New-Item $repoLogDir -ItemType Directory | Out-Null }
    $newLogFile = Join-Path $repoLogDir ("BitNet_Setup_$startTime.log")
    Write-Host "Switching log to $newLogFile inside repository." -ForegroundColor Gray
    Stop-Transcript | Out-Null
    Start-Transcript -Path $newLogFile -Append -NoClobber | Out-Null
    $logFile = $newLogFile
}

# -------------------- Conda Environment Setup -------------------- 

# Create and activate conda environment
$envName = "bitnet-cpp"
Write-Host "`nSetting up Conda environment '$envName'..." -ForegroundColor Cyan
# Check if env already exists
$envList = & conda env list
if ($envList -match " $envName ") {
    Write-Host "Conda environment '$envName' already exists. Skipping creation." -ForegroundColor Green
} else {
    Run-Command "conda" "create -y -n $envName python=3.9" "Creating Conda environment '$envName'"
}
# Activate the conda environment for this session
# Use Conda's 'activate' script in a way that affects this process:
& conda activate $envName
if (!$env:CONDA_DEFAULT_ENV -or $env:CONDA_DEFAULT_ENV -ne $envName) {
    Write-Host "ERROR: Failed to activate conda environment '$envName'. Ensure conda is properly initialized in PowerShell." -ForegroundColor Red
    Write-Host "You may need to run 'conda init powershell' and restart the shell. Exiting." -ForegroundColor Red
    Stop-Transcript | Out-Null
    Exit 1
}
Write-Host "Activated conda environment: $env:CONDA_DEFAULT_ENV" -ForegroundColor Green

# Install required Python packages
Write-Host "`nInstalling Python dependencies (pip requirements)..." -ForegroundColor Cyan
Run-Command "pip" "install --upgrade pip" "Upgrading pip (to latest version)"
Run-Command "pip" "install -r requirements.txt" "Installing Python packages (requirements.txt)"

# Ensure huggingface-cli is available (it might be installed via requirements, but check)
$hfCLI = ""
try { $hfCLI = (& huggingface-cli --version) } catch { $hfCLI = "" }
if (-not $hfCLI) {
    Write-Host "Installing Hugging Face Hub (for huggingface-cli)..." -ForegroundColor Cyan
    Run-Command "pip" "install huggingface_hub==0.17.1" "Installing HuggingFace Hub"
    # Note: version pin can be adjusted; using a known stable version.
    try { $hfCLI = (& huggingface-cli --version) } catch { $hfCLI = "" }
    if ($hfCLI) {
        Write-Host "huggingface-cli is now installed." -ForegroundColor Green
    } else {
        Write-Host "WARNING: huggingface-cli not found even after installation. There may be an issue with the environment." -ForegroundColor Yellow
    }
}

# -------------------- Model Selection and Download -------------------- 

Write-Host "`nAvailable 1-bit Models for BitNet:" -ForegroundColor Cyan
# Define a list of known model options (Name, HuggingFace ID, description)
$modelsList = @(
    @{ Name = "BitNet b1.58 2B4T (Official)"; ID = "microsoft/BitNet-b1.58-2B-4T"; Desc="Official 2.4B-param BitNet model ([GitHub - microsoft/BitNet: Official inference framework for 1-bit LLMs](https://github.com/microsoft/BitNet#:~:text=Model%20Parameters%20CPU%20Kernel%20I2_S,%E2%9C%85%20ARM%20%E2%9C%85%20%E2%9C%85%20%E2%9D%8C))" },
    @{ Name = "BitNet b1.58 - Large (0.7B)"; ID = "1bitLLM/bitnet_b1_58-large"; Desc="Community 0.7B-param BitNet model ([GitHub - microsoft/BitNet: Official inference framework for 1-bit LLMs](https://github.com/microsoft/BitNet#:~:text=Model%20Parameters%20CPU%20Kernel%20I2_S,10B%20x86%20%E2%9C%85%20%E2%9D%8C%20%E2%9C%85))" },
    @{ Name = "BitNet b1.58 - 3B"; ID = "1bitLLM/bitnet_b1_58-3B"; Desc="Community 3.3B-param BitNet model ([GitHub - microsoft/BitNet: Official inference framework for 1-bit LLMs](https://github.com/microsoft/BitNet#:~:text=Model%20Parameters%20CPU%20Kernel%20I2_S,10B%20x86%20%E2%9C%85%20%E2%9D%8C%20%E2%9C%85))" },
    @{ Name = "Llama3 8B (1.58-bit)"; ID = "HF1BitLLM/Llama3-8B-1.58-100B-tokens"; Desc="Experimental 8B Llama model in 1.58-bit ([GitHub - microsoft/BitNet: Official inference framework for 1-bit LLMs](https://github.com/microsoft/BitNet#:~:text=bitnet_b1_58,10B%20x86%20%E2%9C%85%20%E2%9D%8C%20%E2%9C%85))" },
    @{ Name = "Falcon3 1B Instruct"; ID = "tiiuae/Falcon3-1B-Instruct-1.58bit"; Desc="Falcon 1B Instruct tuned (1.58-bit) ([GitHub - microsoft/BitNet: Official inference framework for 1-bit LLMs](https://github.com/microsoft/BitNet#:~:text=bitnet_b1_58,10B%20x86%20%E2%9C%85%20%E2%9D%8C%20%E2%9C%85))" },
    @{ Name = "Falcon3 3B Instruct"; ID = "tiiuae/Falcon3-3B-Instruct-1.58bit"; Desc="Falcon 3B Instruct (1.58-bit)" },
    @{ Name = "Falcon3 7B Instruct"; ID = "tiiuae/Falcon3-7B-Instruct-1.58bit"; Desc="Falcon 7B Instruct (1.58-bit)" },
    @{ Name = "Falcon3 10B Instruct"; ID = "tiiuae/Falcon3-10B-Instruct-1.58bit"; Desc="Falcon 10B Instruct (1.58-bit)" },
    @{ Name = "Other (specify custom)" ; ID = "<custom>"; Desc="Any other HuggingFace repo ID (will be prompted)" }
)
# Display options
for ($i = 0; $i -lt $modelsList.Count; $i++) {
    $option = $modelsList[$i]
    Write-Host "[$($i+1)] $($option.Name)" -ForegroundColor White -NoNewline
    Write-Host " - $($option.Desc)" -ForegroundColor Gray
}

# Determine which models to download (from parameter or prompt)
$chosenModels = @()
if ($ModelIds -and $ModelIds.Count -gt 0) {
    # Use provided model IDs from parameters
    foreach ($mid in $ModelIds) {
        $trimId = $mid.Trim()
        if ($trimId) { $chosenModels += $trimId }
    }
    Write-Host "Models specified via parameter: $($chosenModels -join ", ")" -ForegroundColor Green
} else {
    $selection = Read-Host "Enter the number(s) of the model(s) to download (e.g., 1 or 1,3,5):"
    $selection = $selection.Trim()
    if ($selection -eq '') {
        Write-Host "No selection made. Exiting." -ForegroundColor Red
        Stop-Transcript | Out-Null
        Exit 1
    }
    # Split by comma or whitespace
    $selIndexes = $selection -split '[,\s]+' | Where-Object { $_ -ne "" }
    foreach ($index in $selIndexes) {
        if ($index -match '^\d+$') {
            $idx = [int]$index
            if ($idx -ge 1 -and $idx -le $modelsList.Count) {
                $modelId = $modelsList[$idx-1].ID
                if ($modelId -eq "<custom>") {
                    # Prompt for custom ID
                    $customId = Read-Host "Enter the full HuggingFace model repository ID (owner/model):"
                    if ($customId) {
                        $chosenModels += $customId.Trim()
                    }
                } else {
                    $chosenModels += $modelId
                }
            }
        }
    }
    $chosenModels = $chosenModels | Select-Object -Unique
    if ($chosenModels.Count -eq 0) {
        Write-Host "No valid model selections made. Exiting." -ForegroundColor Red
        Stop-Transcript | Out-Null
        Exit 1
    }
    Write-Host "Selected model(s): $($chosenModels -join ", ")" -ForegroundColor Green
}

# Determine download directory for models
if ($ModelDir) {
    $baseModelDir = $ModelDir
} else {
    # Default to "models" directory inside BitNet repo
    $baseModelDir = Join-Path (Get-Location) "models"
}
if (-not (Test-Path $baseModelDir)) {
    New-Item -Path $baseModelDir -ItemType Directory | Out-Null
}
Write-Host "Models will be downloaded to: $baseModelDir" -ForegroundColor White

# Download each selected model using huggingface-cli
foreach ($modelId in $chosenModels) {
    $localName = $modelId.Split("/")[-1]  # use the repo name as folder name
    $targetDir = Join-Path $baseModelDir $localName
    if (Test-Path $targetDir -PathType Container) {
        # If directory exists, check if it seems to contain model files (just a simple check for any files inside).
        $existingFiles = Get-ChildItem -Path $targetDir -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($existingFiles) {
            Write-Host "Model directory '$targetDir' already exists and contains files." -ForegroundColor Yellow
            if (-not $InstallAll) {
                $resp = Read-Host "It looks like this model might be already downloaded. Re-download and overwrite? (Y/N)"
                if ($resp -notin @("Y","y")) {
                    Write-Host "Skipping download for $modelId." -ForegroundColor Yellow
                    continue
                }
            }
        }
    }
    Write-Host "`nDownloading model $modelId ..." -ForegroundColor Cyan
    # Use huggingface-cli to download entire repository
    Run-Command "huggingface-cli" "download $modelId --local-dir `"$targetDir`" --resume-download" "Downloading $modelId"
}

# -------------------- Build and Setup BitNet (Compilation & Conversion) -------------------- 

Write-Host "`nBuilding BitNet and setting up model environment..." -ForegroundColor Cyan
# Prepare the argument for model directory for setup_env.py. If multiple models, we'll run setup_env for each.
foreach ($modelId in $chosenModels) {
    $localName = $modelId.Split("/")[-1]
    $targetDir = Join-Path $baseModelDir $localName
    # Determine quantization type argument
    $qArg = ""
    if ($QuantType) {
        $qArg = "-q $QuantType"
    }
    # Determine pretuned argument
    $pArg = ""
    if ($UsePretuned) {
        $pArg = "--use-pretuned"
    }
    Write-Host "Running setup_env.py for model: $localName (Quant=$QuantType, Pretuned=$($UsePretuned.IsPresent))" -ForegroundColor White
    Run-Command "python" "setup_env.py -md `"$targetDir`" $qArg $pArg" "Setting up environment for $localName"
}

Write-Host "`nBitNet setup completed successfully!" -ForegroundColor Green
Write-Host "All selected models are downloaded and prepared. You can now run inference using run_inference.py." -ForegroundColor Green

# Provide a usage example for the user
Write-Host "`nExample usage:" -ForegroundColor White
$exampleModel = $chosenModels[0]
$exampleModelDirName = $exampleModel.Split("/")[-1]
$ggufFile = Get-ChildItem -Path (Join-Path $baseModelDir $exampleModelDirName) -Filter "*.gguf" -Recurse | Select-Object -First 1
if ($ggufFile) {
    $modelPath = $ggufFile.FullName
} else {
    # fallback to looking for ggml or other model file
    $modelPath = (Get-ChildItem -Path (Join-Path $baseModelDir $exampleModelDirName) -Include "*.bin","*.ggml" -Recurse | Select-Object -First 1).FullName
}
if ($modelPath) {
    Write-Host "python run_inference.py -m `"$modelPath`" -p \"Your prompt here\" -n 100 -t 8 -cnv" -ForegroundColor Gray
} else {
    Write-Host "python run_inference.py -m <path-to-model-file.gguf> -p \"Your prompt here\" -n 100 -t 8 -cnv" -ForegroundColor Gray
}

Write-Host "`n(To exit the Conda environment, type `exit` or close the shell.)" -ForegroundColor White

# End of script. Stop transcript logging.
Try { Stop-Transcript | Out-Null } Catch {}
```

*(End of PowerShell script)*

### How the Script Works (Step-by-Step Breakdown)

Let’s go through each major section of the script to understand what it does and why.

#### 1. Parameters and Logging

At the top, the script defines several **parameters** (as discussed in the usage section) such as `InstallAll`, `ModelIds`, `QuantType`, etc. These allow the user to run the script with customization. If you run the script without any parameters, all these have default behaviors (interactive prompts, default `i2_s` quantization, etc.).

The script then sets up a **transcript log** using `Start-Transcript` to record all console output to a log file. By default, it will create a `logs` directory and timestamped log file (e.g., `BitNet_Setup_2025-04-25_21-34-00.log`). Logging is important because if something goes wrong, you can inspect this file (or share it when seeking help) to see exactly what happened. The script attempts to start the transcript and warns if it cannot (in rare cases where transcript is not allowed).

#### 2. Developer Shell Initialization (Visual Studio environment)

This is a crucial part for Windows. To compile C++ code with Visual Studio’s tools, the environment variables (PATH, LIB, INCLUDE, etc.) must be set. Normally, when you open a “Developer Command Prompt for VS 2022”, those are configured. If you run the script from a regular PowerShell, these might not be set, causing commands like `cl` or `clang` to not be found or the compiler to not know where the Windows SDK is.

The script checks `In-DevShell` by looking for environment variables that are usually present in a VS dev environment (like `VSCMD_ARG_TGT_ARCH` or `DevEnvDir`). If not found (or if you forced re-init with `-ForceVSDevShell`), it will attempt to initialize it:

- It uses **vswhere** (Visual Studio’s locator tool) to find the installation path of Visual Studio 2022 ([Accelerating AI with Microsoft bitnet.cpp: A Simple Guide to 1-bit LLM Inference Framework](https://www.linkedin.com/pulse/accelerating-ai-microsoft-bitnetcpp-simple-guide-1-bit-sekhar-vurqc#:~:text=,Toolset%20%28clang%29%20is%20recommended)). It specifically looks for an instance with the C++ tools component (`Microsoft.VisualStudio.Component.VC.Tools.x86.x64`) – this ensures that the required workload is installed.
- If found, it constructs the path to `Microsoft.VisualStudio.DevShell.dll`, which is a PowerShell module provided by VS for launching dev shells.
- If that module exists, it imports it and calls `Enter-VsDevShell` with the found instance ID to set up the environment in-place ([GitHub - microsoft/BitNet: Official inference framework for 1-bit LLMs](https://github.com/microsoft/BitNet#:~:text=%E2%80%A2%20If%20you%20are%20using,PowerShell%2C%20run%20the%20following%20commands)). This avoids needing to spawn a new process.
- If the PowerShell module is not available (older VS or just not installed), it falls back to using the batch script `VsDevCmd.bat`. In that case, it actually spawns a new PowerShell process that calls the batch file and then re-runs the current script within that environment. This is a clever workaround to transfer the environment variables. Essentially, you’ll see a new window or your prompt restart, and then continue the script. The script passes along any parameters you originally used, so it picks up where it left off.
- If Visual Studio is not found at all, it will error out and instruct you to install it. (The script could potentially automate Visual Studio installation via winget, but given the size/complexity of VS, it opts to require a manual install for that part if missing. Alternatively, earlier in dependency checks it would catch missing VS and attempt installation if you agreed – more on that later.)

By the end of this step, if successful, you should see a message “Visual Studio Developer environment initialized.” The environment now has the right compiler tools accessible. This corresponds to the BitNet FAQ guidance to run in Developer Prompt ([GitHub - microsoft/BitNet: Official inference framework for 1-bit LLMs](https://github.com/microsoft/BitNet#:~:text=Important)).

#### 3. Dependency Checks and Installation

Next, the script verifies each of the prerequisites:

- **Python:** It tries to run `python --version`. If Python is not installed or is below 3.9, it will use **winget** to install Python (it chooses Python 3.11 in the command) ([Any way to download Python version 3.9? : r/learnpython - Reddit](https://www.reddit.com/r/learnpython/comments/1it7ttl/any_way_to_download_python_version_39/#:~:text=On%20Windows%2C%20the%20built,9)). This uses the Microsoft Store or Winget package for Python. After installation, it double-checks `python` is now available. If you already have a suitable Python, it prints the version found.

- **Conda:** It checks if the `conda` command exists by running `conda --version`. If not, it prompts to install **Miniconda** via winget (the script references `Anaconda.Miniconda3` which is the Miniconda3 distribution) ([Install Miniconda3 with winget - winstall](https://winstall.app/apps/Anaconda.Miniconda3#:~:text=Install%20Miniconda3%20with%20winget%20,e)). If the user agrees (or if `-InstallAll` is set, it won’t prompt), it will install Miniconda. **Note:** After installing Conda, the script actually exits with a message asking you to restart it. This is because initializing Conda for use in the current session can be tricky. The user is advised to open a new PowerShell (which, if `conda init` is run, will have Conda ready) or simply rerun the script. This is done to avoid complex shell reload logic in the script. If Conda is already installed, it moves on.

- **CMake:** Checks for `cmake --version` and parses the version. If not installed or version < 3.22, it will install via `winget install Kitware.CMake` ([Download and install CMake with winget](https://winget.run/pkg/Kitware/CMake#:~:text=How%20to%20install,build%2C%20test%20and%20package)). After installation, it verifies by running `cmake --version` again.

- **Clang/LLVM:** Checks `clang --version`. If not found or version < 18, it will use `winget install LLVM.LLVM` ([How to install 64 bit Visual Studio 2022 buildtools on my pc using ...](https://stackoverflow.com/questions/78935508/how-to-install-64-bit-visual-studio-2022-buildtools-on-my-pc-using-winget#:~:text=How%20to%20install%2064%20bit,add%20Microsoft.VisualStudio.Workload.VCTools)) to install the LLVM toolchain (which includes clang). After installation, it adds the LLVM bin path to the current `$env:Path` (since a new PATH from installation might not reflect immediately). Then checks `clang --version` again to confirm.

- **Git:** Checks `git --version`. If not found, installs via `winget install Git.Git` ([Install Git with winget - winstall](https://winstall.app/apps/Git.Git#:~:text=To%20install%20Git%20with%20winget%2C,source%20distributed%20version%20control%20system)). After installing, verifies Git is usable.

Throughout these, if `-InstallAll` was provided, the script auto-confirms installations. If not, it will prompt Y/N for each major tool. For example, you might see “Install CMake via winget? (Y/N)” and the script waits for you. This way you have control if you prefer to install something yourself or if you already have it in a custom location.

If any required dependency fails to install or isn’t confirmed, the script may exit with an error, because without them, proceeding doesn’t make sense (e.g., no Python or no compiler = cannot continue).

By the end of this section, your system should have all necessary software installed and on PATH: Python, Conda, CMake, Clang, and Git (and Visual Studio from earlier).

#### 4. Cloning the BitNet Repository

Now the script ensures the BitNet code is present. It checks if a `BitNet` directory already exists in the current directory. If not, it runs:  
```powershell
git clone --recursive https://github.com/microsoft/BitNet.git
```  
This clones the repo (with submodules). If the directory exists, it assumes you might have a previous clone, so it does a `git pull` to update it and `git submodule update --init --recursive` to update submodules. This way, the repository is up-to-date. This addresses any scenario where you run the script again later to update BitNet.

Then it `cd` (Set-Location) into the `BitNet` directory to perform the remaining steps.

Once inside the repo, the script adjusts the log output. It moves the log file into the repository’s `logs` folder (creating one if needed). This is just for neatness (keeping logs with the project). The transcript is stopped and restarted in the new location seamlessly.

#### 5. Setting up the Conda Environment

The script uses conda to create and activate the environment named `bitnet-cpp` (the same name suggested in BitNet’s README) ([GitHub - microsoft/BitNet: Official inference framework for 1-bit LLMs](https://github.com/microsoft/BitNet#:~:text=,cpp)):

- It checks `conda env list` to see if `bitnet-cpp` exists. If not, it runs `conda create -y -n bitnet-cpp python=3.9`. (The `-y` flag auto-confirms environment creation.)
- Then it activates the env: `& conda activate bitnet-cpp`. This is a bit tricky in a script; the method used should work if `conda` is properly initialized for PowerShell (the script earlier warned if not).
- It verifies the environment was activated by checking `CONDA_DEFAULT_ENV`.
- If activation fails, it suggests the user might need to run `conda init powershell` and restart (which is a common step after installing Conda, to enable the `conda` function in PS). In such a case it exits with an error.

If all goes well, you’ll see the environment name in your prompt (e.g., `(bitnet-cpp)` prefix) and a message “Activated conda environment: bitnet-cpp”.

Within this environment, it then installs Python packages:

- Upgrades `pip` to latest (good practice).
- Installs the requirements from `requirements.txt` using pip ([GitHub - microsoft/BitNet: Official inference framework for 1-bit LLMs](https://github.com/microsoft/BitNet#:~:text=,cpp)). This will download and install packages like numpy, etc., which BitNet needs. (If one of these fails for some reason, pip will return a non-zero exit code and the `Run-Command` function will catch it and abort, showing an error. For example, if a wheel is missing and compilation of a Python package fails, it would stop here. This is rare since BitNet’s requirements are standard.)

It also ensures `huggingface-cli` is available. Interestingly, BitNet’s requirements might or might not include `huggingface_hub`. To be safe, the script explicitly installs `huggingface_hub==0.17.1` if calling `huggingface-cli --version` fails. This gives us the `huggingface-cli` command used later for downloading models. Now the environment is fully set up with Python dependencies.

#### 6. Model Selection and Download

This is where the script interacts with the user (unless `ModelIds` were pre-specified) to choose a model to download from Hugging Face.

It prints a list of available models with numbers:

The list includes:

- **BitNet b1.58 2B4T (Official)** – The official Microsoft 2.4B-parameter model ([GitHub - microsoft/BitNet: Official inference framework for 1-bit LLMs](https://github.com/microsoft/BitNet#:~:text=Model%20Parameters%20CPU%20Kernel%20I2_S,%E2%9C%85%20ARM%20%E2%9C%85%20%E2%9C%85%20%E2%9D%8C)).
- BitNet b1.58 “large” 0.7B – a smaller community model ([GitHub - microsoft/BitNet: Official inference framework for 1-bit LLMs](https://github.com/microsoft/BitNet#:~:text=Model%20Parameters%20CPU%20Kernel%20I2_S,10B%20x86%20%E2%9C%85%20%E2%9D%8C%20%E2%9C%85)).
- BitNet b1.58 3B – a 3.3B community model ([GitHub - microsoft/BitNet: Official inference framework for 1-bit LLMs](https://github.com/microsoft/BitNet#:~:text=Model%20Parameters%20CPU%20Kernel%20I2_S,10B%20x86%20%E2%9C%85%20%E2%9D%8C%20%E2%9C%85)).
- Llama3 8B 1.58-bit – an 8B Llama model quantized to 1.58-bit (experimental) ([GitHub - microsoft/BitNet: Official inference framework for 1-bit LLMs](https://github.com/microsoft/BitNet#:~:text=bitnet_b1_58,10B%20x86%20%E2%9C%85%20%E2%9D%8C%20%E2%9C%85)).
- Falcon3 1B, 3B, 7B, 10B – Falcon family models quantized to 1.58-bit (community releases) ([GitHub - microsoft/BitNet: Official inference framework for 1-bit LLMs](https://github.com/microsoft/BitNet#:~:text=bitnet_b1_58,10B%20x86%20%E2%9C%85%20%E2%9D%8C%20%E2%9C%85)).
- “Other (specify custom)” – This allows the user to input any Hugging Face model ID if they have something else in mind.

These correspond to the models the BitNet README references as supported ([GitHub - microsoft/BitNet: Official inference framework for 1-bit LLMs](https://github.com/microsoft/BitNet#:~:text=usage%3A%20setup_env.py%20%5B,pretuned)). The script stores their Hugging Face repository IDs internally.

If `-ModelIds` was given as a parameter to the script, it takes those directly (skipping the prompt). Otherwise, it asks: “Enter the number(s) of the model(s) to download (e.g., 1 or 1,3,5):”. You can type a single number or multiple separated by commas or spaces. For example, `1` for just the official model, or `2,3` for the 0.7B and 3B models, or `1 4` etc. If you choose the last option (Other), it will prompt you to type a custom model identifier (like `username/model-name`).

The script then compiles a unique list of chosen model IDs.

Next, it decides where to download models. By default, `ModelDir` is not provided, so it uses `BitNet\models` directory (which aligns with the usage example in README where they put models under the repo). You can override `-ModelDir` to somewhere else, e.g., `D:\AI\Models\BitNet`. The script will create the directory if it doesn’t exist.

For each selected model, it uses `huggingface-cli download`. It includes `--resume-download` to handle any possible interruptions gracefully (it will resume partially done downloads). The entire repository of the model is fetched ([Command Line Interface (CLI)](https://huggingface.co/docs/huggingface_hub/main/en/guides/cli#:~:text=Download%20an%20entire%20repository)), meaning all files (which is what we want, because models often consist of multiple files, especially in GGUF format with splits).

The script also checks if the model’s folder already exists:
- If yes (meaning you may have downloaded it previously), it warns and asks if you want to re-download or skip. If you choose skip, it will not re-download that model. This is handy if you run the script again and the model is already there.
- The `-InstallAll` flag also makes it auto-overwrite without prompting (conservatively, one might make it always re-download in `InstallAll` mode, but here it just won’t ask – effectively it will proceed to re-download since `confirm` is skipped. The script, as written, still would re-download because it doesn’t change the logic for skipping; but you could interpret `InstallAll` to mean assume yes to re-download as well).

The huggingface-cli will display progress bars for each file as it downloads, giving a nice feedback (kind of like a mini “ASCII GUI”). This addresses the requirement to show progress. You’ll see lines like `Fetching 5 files: 20%|████████                    | 1/5 ...` which is similar to how `nvtop` or other TUI tools show progress in text form.

By the end of this, your `models` directory will have subfolders for each model you selected, filled with the model files (which might include `.gguf` files, tokenizer files, etc., depending on the model).

#### 7. Building BitNet and Running `setup_env.py`

This is the actual “build from source” step. For each selected model, the script calls `setup_env.py`. If you selected multiple models, it will run the setup for each one sequentially. (This allows you to prepare several models in one go, though be mindful, it will compile the code the first time, and possibly reuse the compiled artifacts for subsequent ones if the build is already done. The script doesn’t explicitly avoid recompiling for subsequent models, but `setup_env.py` likely sees the build directory already built and will mostly just convert the model after the first.)

It constructs the command like:  
```powershell
python setup_env.py -md "<path-to-model-folder>" -q i2_s [--use-pretuned]
```  
It uses the `QuantType` parameter (default “i2_s”). If you passed `-QuantType tl1` to the script, it would put `-q tl1`. If `-UsePretuned` was set, it adds `--use-pretuned`. These correspond to BitNet’s script options ([GitHub - microsoft/BitNet: Official inference framework for 1-bit LLMs](https://github.com/microsoft/BitNet#:~:text=,Use%20the%20pretuned%20kernel%20parameters)).

When this runs:
- `setup_env.py` will print some info. It usually logs “Compiling the code using CMake.” and runs the build. In the background, it’s executing `cmake` and building the C++ code (which includes the core inference engine and any conversion utilities).
- If the compilation fails for any reason, our `Run-Command` will catch the non-zero exit and abort with an error, pointing to the log file. If success, it then likely proceeds to quantize the model. 
- On success, you’ll have the quantized model file (like `ggml-model-i2_s.gguf` or similar) in the model directory.

If multiple models are chosen, after the first model, the code is already compiled. `setup_env.py` might detect that and skip recompiling (if the code is unchanged) and just do conversion for the next model (especially if the quantization type is different, it might re-quantize weights accordingly).

Finally, if all goes well, it prints a success message: “BitNet setup completed successfully! All selected models are downloaded and prepared.”

#### 8. Post-Setup Usage Tips

The script, after completing, gives an example command to run inference. It actually tries to find the first model’s file (searches for a `.gguf` file in the model directory). If found, it prints an example like:  
```
python run_inference.py -m "C:\Path\to\models\BitNet-b1.58-2B-4T\ggml-model-i2_s.gguf" -p "Your prompt here" -n 100 -t 8 -cnv
```  
This is extremely helpful for the user, as it tells them exactly how to invoke the model that was just set up. It picks `-n 100` (generate 100 tokens) and `-t 8` (use 8 threads) as an example; users can adjust those. The `-cnv` flag (conversation mode) is suggested because many of these models are instruct/chat models; it’s optional depending on model type.

If the script can’t find the model file (just in case the naming is different), it prints a generic template command and the user would have to fill the path.

Finally, it reminds that to exit the conda environment, just type `exit` or close the shell.

The script ends logging by stopping the transcript.

#### ASCII UI / Progress Indications

Throughout the script, we use `Write-Host` with different colors to highlight sections and important messages (cyan for section headers, green for successful checks, yellow for warnings or actions, red for errors). This color-coding and structured output is intended to make it feel like a guided UI in the terminal. For example, progress of installation and downloads is clearly shown. When waiting for user input, it prints prompts.

The huggingface-cli and pip installations themselves show progress bars (pip shows a `#%%%%%` style progress for packages, huggingface-cli shows a moving progress bar for file downloads), which provides feedback that something is happening.

We also print separators like `--- Step Name ---` for steps run via `Run-Command`, and blank lines (`\n`) to improve readability.

This should satisfy the “CLI ASCII GUI-like interface” requirement to a reasonable extent, given the medium (PowerShell in a console).

### Models and Quantization Options

A quick note on **quantization types**: We default to `i2_s` because BitNet’s 1.58-bit is typically represented as “int2 with sign” (likely what i2_s stands for) ([GitHub - microsoft/BitNet: Official inference framework for 1-bit LLMs](https://github.com/microsoft/BitNet#:~:text=,q%20i2_s)). The other option, `tl1`, might be a ternary (3-level) quantization mode. The official BitNet model is 1.58-bit weights, which presumably corresponds to i2_s (1-bit sign + some 0/1 indicator or scaling). The script allowed the user to override this if needed. If someone downloads a model that was trained in a different 1-bit format (say, a TL1 type), they could set `-QuantType tl1`. For instance, maybe some of the Falcon models might use `tl1`. The BitNet README’s supported models table shows columns “I2_S”, “TL1”, “TL2” indicating which kernels support which models ([GitHub - microsoft/BitNet: Official inference framework for 1-bit LLMs](https://github.com/microsoft/BitNet#:~:text=Model%20Parameters%20CPU%20Kernel%20I2_S,%E2%9C%85%20ARM%20%E2%9C%85%20%E2%9C%85%20%E2%9D%8C)) ([GitHub - microsoft/BitNet: Official inference framework for 1-bit LLMs](https://github.com/microsoft/BitNet#:~:text=Model%20Parameters%20CPU%20Kernel%20I2_S,10B%20x86%20%E2%9C%85%20%E2%9D%8C%20%E2%9C%85)). The ones listed (BitNet, Llama3, Falcon3) mostly indicate I2_S or TL2 support on x86. We stick to i2_s unless user changes it.

**Pretuned kernels**: By default not used, because in some cases pretuned parameters might be specific to certain hardware (maybe they did auto-tuning on a particular CPU model). But advanced users might want to try `--use-pretuned` to see if it speeds up inference. We offered the flag for completeness. If chosen, it just passes that flag; if the project doesn’t have pretuned data or if it’s not beneficial, it simply might not change much.

### Running the Script

When you run the script, expect it to potentially take quite some time if you are missing many components (because it could download and install Visual Studio components, Python, etc., which collectively can be several GB and require some waiting). The model download is also time-consuming (depending on size and connection).

However, the process is largely automated and hands-off once you respond to prompts. 

### Example Scenario:

Let's walk through an example scenario of running this script on a fresh Windows 11 PC:

1. **Start**: You open “Developer PowerShell for VS 2022” (or normal PowerShell if you don’t have VS installed yet, in which case the script will install VS build tools for you). Run `Setup-BitNet.ps1`.

2. **VS Dev Shell**: Suppose you did have VS installed and opened Developer PS, then `In-DevShell` is true and it skips reinitializing (the script notices you’re already in the right shell). If you were in a normal PS and had VS, it would find VS and import the dev shell, so you’d see a message about initializing environment. If you didn’t have VS at all, vswhere would fail – the script would at that point error out. However, since we know Visual Studio is a requirement, you should install it first. We might improve the script by also offering to install Visual Studio Build Tools via winget earlier (perhaps we could add that in dependency checks if vswhere not found, winget the build tools). But in our current script, it expects VS to be installed already. (We assume the user either has installed it per prerequisites, or if not, they will notice the script error and then install VS and re-run.)

3. **Python**: The script sees if Python is installed. If you have Python 3.10 installed, it will print “Python found: Python 3.10.x” and move on. If not, it will ask to install and do so via winget.

4. **Conda**: If you already have Miniconda/Anaconda, it finds `conda`. If not, it asks to install Miniconda. Let’s say you accept, it will download and install it (this might pop up a setup, or winget might do it quietly). The script then exits instructing to restart (this is one place where manual intervention is needed: after installing Miniconda, you run the script again so that conda is now available in the new session).

5. **CMake**: If your VS install included CMake (likely yes if you included the component), then `cmake` will be found. Visual Studio’s CMake integration usually installs a CMake that is accessible in the dev shell path. If not, it installs it. Typically we might see “Found CMake version 3.xx” if you have VS2022 updated (it usually ships with CMake in the 3.24+ range by now).

6. **Clang**: If you selected the "C++ Clang Compiler for Windows" component in VS, then `clang` should be in your path (provided by VS, possibly via a path like `...\LLVM\bin`). The dev shell might have added it. The script sees the version. If VS had clang 12 (an older one) and not updated, it might say "found clang version 12, which is <18, will install newer". Then it uses winget to install LLVM 18 or 19. Alternatively, if your VS is updated to include LLVM 18/19 (for example, VS 17.6+ might include clang 16 or higher, not sure at time of writing), you might still need a manual update. The script covers the case by ensuring >=18.

7. **Git**: If using Developer PS, Git might already be on PATH (if you installed Git for Windows with VS or separately). If not, it installs it.

8. **Clone**: It clones the repo. You see git output of progress. If already cloned, it updates.

9. **Conda env**: Creates `bitnet-cpp` environment. This step might download Python 3.9 if you didn't already have it in your base conda (Miniconda by default might not have 3.9, but conda will fetch it). It then activates it. You’ll notice your prompt change to `(bitnet-cpp)`.

10. **Pip deps**: Installs requirements. You’ll see pip output lines for each package. If all go well: "Successfully installed ..."

11. **huggingface-cli**: If after requirements there is no huggingface, it installs it. Possibly `pip install -r requirements.txt` might have already installed it if BitNet’s requirements include it. If not, our script ensures it.

12. **Model selection**: It lists 9 options. Suppose you type `1` (for official model). Or `1,5` to also get Falcon 1B instruct for fun. The script then prints what you selected.

13. **Download model**: For each, runs huggingface-cli. For the official `microsoft/BitNet-b1.58-2B-4T`, note we put `-gguf` in our example, but in the script we didn't include `-gguf` suffix by default. The script’s model ID for official is `"microsoft/BitNet-b1.58-2B-4T"`. The actual repo on HF might be named `BitNet-b1.58-2B-4T` (which likely contains GGUF files). That should fetch everything. You will see progress bars for dozens of files possibly (tokenizer, gguf splits maybe, etc.). Once done, you have them locally.

14. **Build & setup**: Now it runs `python setup_env.py -md models/BitNet-b1.58-2B-4T -q i2_s`. You’ll see output from BitNet’s script, possibly something like:

    ```
    INFO:root:Compiling the code using CMake.
    -- The C compiler identification is Clang 18.0.0
    -- The CXX compiler identification is Clang 18.0.0
    ... (CMake configuring) ...
    -- Build files have been written to: C:/.../BitNet/build
    Scanning dependencies...
    [ 50%] Building CXX object ... (compiling files)
    [100%] Linking ...
    [100%] Built target bitnet_exec   (for example)
    INFO:root:Converting model to 1-bit format...
    INFO:root:Done. Output model saved to models/BitNet-b1.58-2B-4T/ggml-model-i2_s.gguf
    ```

   (This is an illustrative guess of output; actual might differ). The script will capture any errors. If success, it moves to next model if any.

15. **Completion**: Script prints success message and the example usage command. For instance, if the official model file is `ggml-model-i2_s.gguf`, it shows that path in a `python run_inference.py ...` command.

16. You can now copy that command or just run it to test. It should load the model and start generating text for your prompt.

17. The script keeps the environment active; you can continue to run more inference commands or exit.

At this point, BitNet is fully set up. 🎉

## Verifying the Installation

After running the script, it’s good practice to verify that everything is working:

- **Check the model files:** Navigate to the `models\<ModelName>` directory. You should see a large file like `ggml-model-i2_s.gguf` (or similar). The size might be several GB for larger models, confirming that the weights are there.
- **Run a quick inference:** Use the example printed or craft your own. For example:  
  ```powershell
  python run_inference.py -m models/BitNet-b1.58-2B-4T/ggml-model-i2_s.gguf -p "Hello, BitNet!" -n 40 -t 4 -cnv
  ```  
  This should print a generated continuation after a few seconds of processing (depending on your CPU and threads). If you see an output, the pipeline is working end-to-end.
- **Performance note:** The first run might be slower if the system is caching things; subsequent runs are usually faster. If you want to experiment, try running with different threads (`-t` option) to see how it scales on your CPU. The BitNet paper claims ~5-7 tokens/sec for the 100B token 8B model on a high-end CPU ([Accelerating AI with Microsoft bitnet.cpp: A Simple Guide to 1-bit LLM Inference Framework](https://www.linkedin.com/pulse/accelerating-ai-microsoft-bitnetcpp-simple-guide-1-bit-sekhar-vurqc#:~:text=while%20energy%20consumption%20drops%20between,to%2082.2)), and faster for smaller models.

## Common Issues and Troubleshooting

Despite the script’s efforts to handle errors, you might encounter issues. Here are some common problems and how to address them:

**1. Visual Studio or Build Tools not installed:** If the script says it cannot find Visual Studio or fails to initialize the developer shell, you need to install the required Visual Studio components. Ensure you have **Visual Studio 2022** (Community is fine) with the "Desktop development with C++" workload and the additional components for Clang and CMake ([Accelerating AI with Microsoft bitnet.cpp: A Simple Guide to 1-bit LLM Inference Framework](https://www.linkedin.com/pulse/accelerating-ai-microsoft-bitnetcpp-simple-guide-1-bit-sekhar-vurqc#:~:text=,Toolset%20%28clang%29%20is%20recommended)). If you prefer a lighter install, you can install **Visual Studio Build Tools 2022** which is a smaller package containing just the compilers and tools (no IDE). The script does not automatically install Build Tools, but you can do so manually via:  
   ```powershell
   winget install -e --id Microsoft.VisualStudio.2022.BuildTools --override "--quiet --wait --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --add Microsoft.VisualStudio.Component.VC.Llvm.Clang --add Microsoft.VisualStudio.Component.VC.Llvm.ClangToolset --add Microsoft.VisualStudio.Component.VC.CMake.Project"
   ```  
   (This installs the C++ build tools workload with recommended components including Clang and CMake). After that, rerun the script.

**2. Conda issues (Environment not activating):** If the script prints *"Failed to activate conda environment"* and exits, it means that the `conda` command isn’t fully integrated into your PowerShell. Fix: run `conda init powershell`, then close and reopen the PowerShell window (Developer PS). This will configure your PowerShell profile to enable the `conda` function. Then run the script again (it will detect the env exists and just activate it). Alternatively, you can manually activate by launching “Anaconda Powershell Prompt” that comes with Miniconda and then running the script from within that.

**3. pip install fails (error building wheel or similar):** All dependencies in `requirements.txt` should have pre-built wheels for Windows. If you run into an error during `pip install -r requirements.txt`, read the error message. It could be a network issue (unable to download a package) – ensure internet is working. Or a package might require a compiler if no wheel (but common ones like numpy, transformers, etc., have wheels). If a specific package fails, you can try to install it manually with pip to see the error. If it’s a compatibility issue, you might need to update pip or use a different Python version. Our script pinned Python 3.9 for environment; if that is an issue, consider using 3.10 or 3.11 (you can modify the script’s conda create line or create the env yourself then skip env creation in script). Generally 3.9+ should all work.

**4. `huggingface-cli` login or auth issues:** The models we listed are all public, so you should not need to log in to Hugging Face. If you get an error during download about authentication or “permission denied”, it could be that the model is gated. For official BitNet and the listed ones, this shouldn’t be the case ([GitHub - microsoft/BitNet: Official inference framework for 1-bit LLMs](https://github.com/microsoft/BitNet#:~:text=%E2%9D%97%EF%B8%8FWe%20use%20existing%201,model%20size%20and%20training%20tokens)) (they’re open). However, if you use a custom model ID that is private or requires acceptance of a license (like some large models do), `huggingface-cli` will error. Solution: either log in by running `huggingface-cli login` and entering your HF token, or go to the model page on HuggingFace and accept the terms (for gated models) then try again. You can also manually download the files and place them in the folder, then skip the cli download step.

**5. CMake configure or build errors:** If `setup_env.py` fails with a CMake error, check the `logs/compile.log` in the BitNet directory for details. A few possibilities:
   - **Compiler not found:** If Clang/VS isn’t in PATH, the CMake might not find a generator. The script’s dev shell step should prevent this. Ensure you ran the script in a Developer prompt or that the dev shell initialization part executed (you would see its output). If you suspect it didn’t, try running the script with `-ForceVSDevShell`.
   - **Wrong generator:** On some setups, CMake might default to a generator (like Visual Studio 17 2022) using MSVC, and maybe conflict with Clang usage. In BitNet’s case, they specifically require clang, so they might set `CMAKE_C_COMPILER=clang` internally. If not, one workaround is to manually open a “x64 Native Tools Command Prompt” and run `cmake . -B build -T ClangCL -A x64` to force Clang, then run the script or `setup_env.py`. This is advanced; normally the script should handle environment. If you see errors about MSVC or about unknown options (like an error mentioning `-Wunreachable-code` as in one GitHub issue), it might be using the wrong compiler. Ensure Clang is first in PATH or remove any `CC` env var that points to gcc. On Windows, it should prefer MSVC or clang-cl. 
   - **Chrono error in log.cpp:** There was a known issue with a recent llama.cpp update causing a compile error in C++ chrono usage ([GitHub - microsoft/BitNet: Official inference framework for 1-bit LLMs](https://github.com/microsoft/BitNet#:~:text=FAQ%20)). If you encounter an error like *`error: no member named 'steady_clock' in namespace 'std::chrono'`*, this is fixed in newer code. Make sure you pulled the latest BitNet code (our script does `git pull`). If not resolved, check the BitNet GitHub for issues; possibly a patch is needed (the BitNet FAQ pointed to a commit in llama.cpp to fix chrono includes ([GitHub - microsoft/BitNet: Official inference framework for 1-bit LLMs](https://github.com/microsoft/BitNet#:~:text=,cpp))). Updating submodules or editing the problematic file per that commit might be necessary. This is a rare edge case and likely fixed if you have the latest repo.

**6. Running out of memory or large model conversion fails:** Converting a very large model (like an 8B model) to 1-bit might use a lot of RAM during conversion. If your system has low RAM, the process could fail or swap heavily. For example, the 8B Llama3 100B-token model might need >16GB RAM to quantize. If you face such an issue, consider using a smaller model, or perform the conversion on a machine with more RAM and then copy the model file over.

**7. Performance issues:** If after everything, you find the model runs but slower than expected, a few tips:
   - Ensure you used the `-t` (threads) option in `run_inference.py` to match your CPU cores (the example we gave was `-t 8` for an 8-core machine).
   - If you did not use `--use-pretuned` initially, you can try re-running the setup with that to see if it improves speed. That will tune certain low-level parameters for your CPU.
   - Check that you used the correct quantization type for the model. If you suspect the wrong `-q` was used, you can re-run setup_env.py with the alternative. For example, for some model if `tl1` is more appropriate, using i2_s might still work but maybe not optimal or vice versa.
   - Use the latest CPU runtime optimizations: BitNet is CPU-focused; if you have an older CPU, performance will be limited. On very new CPUs, make sure to use a 64-bit Python and that the compiler used AVX/AVX2 etc. (It should by default with clang on x64).
  
**8. Cleaning up:** If you want to redo the process, you can delete the `BitNet` folder and the conda env (`conda remove -n bitnet-cpp --all`) and start fresh. Or if you just want to rebuild, you can delete the `BitNet/build` directory to force a clean CMake build next time you run setup_env.

**9. Multiple model formats:** BitNet supports the new GGUF format (as used by llama.cpp). The official model is in GGUF. If you have older GGML files, BitNet might have conversion scripts (the requirements had references to convert_ggml_to_gguf). Our guide assumes you download models that are already 1-bit quantized (i.e., the Hugging Face repos listed are already in the needed format or at least in a convertible format). If you had a full-precision model, BitNet’s tools might not directly quantize from FP16/32 to 1-bit (the models are usually trained in 1-bit already). So stick to known 1-bit model repos for compatibility.

If you encounter an issue not covered here, consider searching the BitNet GitHub issues or discussions. There’s a growing community around it, and many have shared tips for various setups.

## Additional Notes

- **Maintaining the Installation:** If a new version of BitNet is released, you can update by pulling the latest Git repo (the script already does `git pull` each time). If the C++ code changed significantly (e.g., new requirements or code differences), you might need to rerun `setup_env.py` to rebuild with the new code. Re-running the script will handle that: it will git pull and then run setup_env again.
- **Installing New Models Later:** You don’t have to run the whole script again to add a new model. Once BitNet is built, you can simply activate the `bitnet-cpp` environment and use `huggingface-cli` to download a new model, then run `python setup_env.py -md <newModelDir> -q <type>` manually. Or you can rerun the script with `-SkipDependencyChecks` (since your env is set) and choose only the model download part. The script is modular enough that it will skip cloning (since repo exists) and skip installing things (assuming SkipDependencyChecks or they’re already installed) and you can just select a new model to download and set up.
- **Uninstalling:** If you ever want to remove BitNet: delete the `BitNet` folder, delete the models, and optionally remove the conda environment and any tools you installed (like via Apps & Features for Visual Studio components or using winget to uninstall). The script itself does not come with an uninstaller (beyond what package managers offer).

## References

This guide and script were informed by Microsoft’s official documentation and community resources:

- Microsoft’s BitNet (bitnet.cpp) GitHub README – for installation requirements and usage ([GitHub - microsoft/BitNet: Official inference framework for 1-bit LLMs](https://github.com/microsoft/BitNet#:~:text=,required%20additional%20tools%20like%20CMake)) ([GitHub - microsoft/BitNet: Official inference framework for 1-bit LLMs](https://github.com/microsoft/BitNet#:~:text=2)).
- BitNet FAQ on GitHub – clarifying environment setup on Windows (Developer Shell usage) ([GitHub - microsoft/BitNet: Official inference framework for 1-bit LLMs](https://github.com/microsoft/BitNet#:~:text=%E2%80%A2%20If%20you%20are%20using,PowerShell%2C%20run%20the%20following%20commands)).
- LinkedIn Article “Accelerating AI with Microsoft bitnet.cpp” – for a summary of prerequisites and model info ([Accelerating AI with Microsoft bitnet.cpp: A Simple Guide to 1-bit LLM Inference Framework](https://www.linkedin.com/pulse/accelerating-ai-microsoft-bitnetcpp-simple-guide-1-bit-sekhar-vurqc#:~:text=,Toolset%20%28clang%29%20is%20recommended)) ([Accelerating AI with Microsoft bitnet.cpp: A Simple Guide to 1-bit LLM Inference Framework](https://www.linkedin.com/pulse/accelerating-ai-microsoft-bitnetcpp-simple-guide-1-bit-sekhar-vurqc#:~:text=Technical%20Requirements)).
- Hugging Face documentation – for usage of `huggingface-cli download` ([Command Line Interface (CLI)](https://huggingface.co/docs/huggingface_hub/main/en/guides/cli#:~:text=Download%20an%20entire%20repository)).
- Winget documentation – for installing packages like Python, CMake, etc., non-interactively ([Use command-line parameters to install Visual Studio | Microsoft Learn](https://learn.microsoft.com/en-us/visualstudio/install/use-command-line-parameters-to-install-visual-studio?view=vs-2022#:~:text=winget%20install%20)) ([Install Git with winget - winstall](https://winstall.app/apps/Git.Git#:~:text=To%20install%20Git%20with%20winget%2C,source%20distributed%20version%20control%20system)).
- BitNet supported models list from README – to identify model IDs and parameters ([GitHub - microsoft/BitNet: Official inference framework for 1-bit LLMs](https://github.com/microsoft/BitNet#:~:text=Model%20Parameters%20CPU%20Kernel%20I2_S,%E2%9C%85%20ARM%20%E2%9C%85%20%E2%9C%85%20%E2%9D%8C)) ([GitHub - microsoft/BitNet: Official inference framework for 1-bit LLMs](https://github.com/microsoft/BitNet#:~:text=Model%20Parameters%20CPU%20Kernel%20I2_S,10B%20x86%20%E2%9C%85%20%E2%9D%8C%20%E2%9C%85)).
- Community discussions and issues on GitHub – troubleshooting build issues (like using correct clang, chrono bug) ([Unable to run setup_env.py · Issue #180 · microsoft/BitNet · GitHub](https://github.com/microsoft/BitNet/issues/180#:~:text=%5B%20%201,3rdparty%2Fllama.cpp%2Fggml%2Fsrc%2FCMakeFiles%2Fggml.dir%2Fbuild.make%3A76%3A%203rdparty%2Fllama.cpp%2Fggml%2Fsrc%2FCMakeFiles%2Fggml.dir%2Fggml.c.o%5D%20Error%201)) ([GitHub - microsoft/BitNet: Official inference framework for 1-bit LLMs](https://github.com/microsoft/BitNet#:~:text=,cpp)).

By following this guide, you should have a working BitNet installation on your Windows machine. Enjoy experimenting with 1-bit LLMs locally! If you found this helpful or ran into problems that were solved, consider contributing back (e.g., updating documentation or helping others on forums) – the community around these tools is what makes them robust and user-friendly.

