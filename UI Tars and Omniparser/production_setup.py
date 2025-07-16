#!/usr/bin/env python3
"""
Production Setup Script for OmniTool
Performs pre-flight checks and setup for production deployment
"""

import os
import sys
import subprocess
import importlib
import socket
from pathlib import Path


def check_python_version():
    """Check if Python version is compatible."""
    if sys.version_info < (3, 8):
        print("❌ Python 3.8+ is required")
        return False
    print(f"✅ Python {sys.version.split()[0]} detected")
    return True


def check_dependencies():
    """Check if required dependencies are installed."""
    required_packages = [
        'gradio', 'requests', 'anthropic', 'openai', 
        'numpy', 'opencv-python', 'torch'
    ]
    
    # Map package names to their corresponding module names
    package_to_module = {
        'opencv-python': 'cv2'
    }
    
    missing = []
    for package in required_packages:
        module_name = package_to_module.get(package, package.replace('-', '_'))
        try:
            importlib.import_module(module_name)
            print(f"✅ {package}")
        except ImportError:
            print(f"❌ {package} (missing)")
            missing.append(package)
    
    if missing:
        print(f"\n🔧 Install missing packages:")
        print(f"pip install {' '.join(missing)}")
        return False
    
    return True


def check_ports():
    """Check if required ports are available."""
    ports_to_check = [7888, 8000, 5000]
    
    for port in ports_to_check:
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                s.bind(('localhost', port))
                print(f"✅ Port {port} available")
        except OSError:
            print(f"⚠️  Port {port} is in use")
    
    return True


def check_model_weights():
    """Check if OmniParser model weights exist."""
    weights_dir = Path("weights")
    required_paths = [
        weights_dir / "icon_detect" / "model.pt",
        weights_dir / "icon_caption_florence" / "model.safetensors"
    ]
    
    all_exist = True
    for path in required_paths:
        if path.exists():
            print(f"✅ {path}")
        else:
            print(f"❌ {path} (missing)")
            all_exist = False
    
    if not all_exist:
        print("\n🔧 Download model weights:")
        print("./setup_weights.ps1  # On Windows")
        print("# Or manually from: https://huggingface.co/microsoft/OmniParser-v2.0")
    
    return all_exist


def create_directories():
    """Create necessary directories."""
    dirs = ["tmp/outputs", "logs", ".anthropic"]
    
    for dir_path in dirs:
        Path(dir_path).mkdir(parents=True, exist_ok=True)
        print(f"✅ Created directory: {dir_path}")
    
    return True


def check_environment_variables():
    """Check for important environment variables."""
    env_vars = [
        "OPENAI_API_KEY", "ANTHROPIC_API_KEY", 
        "GROQ_API_KEY", "DASHSCOPE_API_KEY"
    ]
    
    found_any = False
    for var in env_vars:
        if os.getenv(var):
            print(f"✅ {var} is set")
            found_any = True
        else:
            print(f"⚠️  {var} not set")
    
    if not found_any:
        print("\n💡 Set at least one API key environment variable")
    
    return True


def main():
    """Run all production setup checks."""
    print("🚀 OmniTool Production Setup")
    print("=" * 40)
    
    checks = [
        ("Python Version", check_python_version),
        ("Dependencies", check_dependencies), 
        ("Ports", check_ports),
        ("Model Weights", check_model_weights),
        ("Directories", create_directories),
        ("Environment Variables", check_environment_variables),
    ]
    
    all_passed = True
    for name, check_func in checks:
        print(f"\n📋 {name}:")
        if not check_func():
            all_passed = False
    
    print("\n" + "=" * 40)
    if all_passed:
        print("🎉 All checks passed! Ready for production.")
        print("\n🚀 Start the application:")
        print("python omnitool/gradio/app_new.py")
    else:
        print("⚠️  Some checks failed. Please fix the issues above.")
        return 1
    
    return 0


if __name__ == "__main__":
    sys.exit(main())