#!/bin/bash
set -eo pipefail

# --- 1. Install Zsh and Dependencies ---
echo "--- 1. Installing Zsh and Dependencies (zsh, git, curl, nano, jq) ---"
apt-get update
apt-get install -y zsh git curl nano jq

# --- 2. Install Oh My Zsh ---
echo "--- 2. Installing Oh My Zsh ---"
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Optional: Set Zsh as default shell (requires re-login)
chsh -s $(which zsh)

# --- 3. Install and Configure Zsh Plugins ---
echo "--- 3. Installing Zsh Plugins ---"
ZSH_CUSTOM="/root/.oh-my-zsh/custom"

# Clone zsh-autosuggestions
echo "Cloning zsh-autosuggestions..."
git clone https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM}/plugins/zsh-autosuggestions

# Clone zsh-syntax-highlighting
echo "Cloning zsh-syntax-highlighting..."
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting

# Activate the plugins in the .zshrc file
# This sed command finds the plugins line (e.g., plugins=(git)) and replaces it 
# with the git, autosuggestions, and syntax-highlighting plugins.
echo "Activating zsh-autosuggestions and zsh-syntax-highlighting..."
sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/g' /root/.zshrc

# --- 4. Install Task ---
echo "--- 4. Installing Task ---"
curl -1sLf 'https://dl.cloudsmith.io/public/task/task/setup.deb.sh' | sudo -E bash
apt install task

# --- 5. Configure VS Code Terminal ---
echo "--- 5. Configuring VS Code Terminal Settings ---"
# Define the target path (VS Code remote settings file)
VSCODE_SETTINGS_PATH="/root/.vscode-server/data/Machine/settings.json"
VSCODE_SETTINGS_DIR=$(dirname "$VSCODE_SETTINGS_PATH")

# Create the directory if it doesn't exist
mkdir -p "$VSCODE_SETTINGS_DIR"

# Ensure the settings file exists (if not, create it with a basic structure)
if [ ! -f "$VSCODE_SETTINGS_PATH" ]; then
    echo "{}" > "$VSCODE_SETTINGS_PATH"
fi

# Define the JSON configuration fragment for zsh login shell
VSCODE_CONFIG_FRAGMENT='
{
    "terminal.integrated.profiles.linux": {
        "zsh_new_process": {
            "path": "/bin/zsh", 
            "args": ["-l", "-i"] 
        }
    },
    "terminal.integrated.defaultProfile.linux": "zsh_new_process"
}
'

# Use jq to merge the fragment into the existing settings.json file
echo "$VSCODE_CONFIG_FRAGMENT" | jq -s '.[0] * .[1]' "$VSCODE_SETTINGS_PATH" - > temp.json && mv temp.json "$VSCODE_SETTINGS_PATH"

echo "Zsh and VS Code settings configured successfully!"

# --- 6. Clone Repository ---
echo "--- 6. Cloning layered-segmentation repository ---"
cd /workspace
git clone https://github.com/sagiahrac/layered-segmentation.git

# --- 7. Create env ---
echo "7. Creating virtual environment using Task..."
cd /workspace/layered-segmentation
task create-venv

# Cleanup packages (optional but recommended)
rm -rf /var/lib/apt/lists/*