#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

NEXUS_HOME="$HOME/.nexus"
PROVER_ID_FILE="$NEXUS_HOME/prover-id"
SESSION_NAME="nexus-prover"
PROGRAM_DIR="$NEXUS_HOME/src/generated"
ARCH=$(uname -m)
OS=$(uname -s)
REPO_BASE="https://github.com/nexus-xyz/network-api/raw/refs/tags/0.4.0/clients/cli"

setup_directories() {
    mkdir -p "$PROGRAM_DIR"
    ln -sf "$PROGRAM_DIR" "$NEXUS_HOME/src/generated"
}

check_dependencies() {
    if ! command -v tmux &> /dev/null; then
        echo -e "${YELLOW}tmux is not installed, installing...${NC}"
        if [ "$OS" = "Darwin" ]; then
            if ! command -v brew &> /dev/null; then
                echo -e "${RED}Please install Homebrew first: https://brew.sh${NC}"
                exit 1
            fi
            brew install tmux
        elif [ "$OS" = "Linux" ]; then
            if command -v apt &> /dev/null; then
                sudo apt update && sudo apt install -y tmux
            elif command -v yum &> /dev/null; then
                sudo yum install -y tmux
            else
                echo -e "${RED}Unrecognized package manager. Please install tmux manually.${NC}"
                exit 1
            fi
        fi
    fi
}

download_program_files() {
    local files="cancer-diagnostic fast-fib"
    
    for file in $files; do
        local target_path="$PROGRAM_DIR/$file"
        if [ ! -f "$target_path" ]; then
            echo -e "${YELLOW}Downloading $file...${NC}"
            curl -L "$REPO_BASE/src/generated/$file" -o "$target_path"
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}$file downloaded successfully.${NC}"
                chmod +x "$target_path"
            else
                echo -e "${RED}Failed to download $file.${NC}"
            fi
        fi
    done
}

download_prover() {
    local prover_path="$NEXUS_HOME/prover"
    if [ ! -f "$prover_path" ]; then
        if [ "$ARCH" = "x86_64" ]; then
            echo -e "${YELLOW}Downloading AMD64 Prover...${NC}"
            curl -L "https://github.com/qzz0518/nexus-run/releases/download/v0.4.0/prover-amd64" -o "$prover_path"
        elif [ "$ARCH" = "arm64" ]; then
            echo -e "${YELLOW}Downloading ARM64 Prover...${NC}"
            curl -L "https://github.com/qzz0518/nexus-run/releases/download/v0.4.0/prover-arm64" -o "$prover_path"
        else
            echo -e "${RED}Unsupported architecture: $ARCH${NC}"
            exit 1
        fi
        chmod +x "$prover_path"
        echo -e "${GREEN}Prover downloaded successfully.${NC}"
    fi
}

download_files() {
    download_prover
    download_program_files
}

generate_prover_id() {
    local temp_output=$(mktemp)
    tail -f "$temp_output" &
    local tail_pid=$!
    
    "./prover" beta.orchestrator.nexus.xyz > "$temp_output" 2>&1 &
    local prover_pid=$!
    
    while ! grep -q "Success! Connection complete!" "$temp_output" 2>/dev/null; do
        if ! kill -0 $prover_pid 2>/dev/null; then
            break
        fi
        sleep 1
    done
    
    kill $prover_pid 2>/dev/null
    kill $tail_pid 2>/dev/null
    
    local prover_id=$(grep -o 'Your current prover identifier is [^ ]*' "$temp_output" | cut -d' ' -f6)
    if [ -n "$prover_id" ]; then
        echo "$prover_id" > "$PROVER_ID_FILE"
        echo -e "${GREEN}Generated and saved new Prover ID: $prover_id${NC}"
    else
        echo -e "${RED}Failed to generate Prover ID.${NC}"
    fi
    rm "$temp_output"
}

start_prover() {
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        echo -e "${YELLOW}Prover is already running.${NC}"
        return
    fi
    
    cd "$NEXUS_HOME" || exit
    
    if [ ! -f "$PROVER_ID_FILE" ]; then
        echo -e "${YELLOW}Enter your Prover ID.${NC}"
        echo -e "${YELLOW}If you don't have one, press Enter to generate it automatically.${NC}"
        read -p "Prover ID > " input_id
        
        if [ -n "$input_id" ]; then
            echo "$input_id" > "$PROVER_ID_FILE"
            echo -e "${GREEN}Saved Prover ID: $input_id${NC}"
        else
            echo -e "${YELLOW}Automatically generating a new Prover ID...${NC}"
            generate_prover_id
        fi
    fi
    
    tmux new-session -d -s "$SESSION_NAME" "cd '$NEXUS_HOME' && ./prover beta.orchestrator.nexus.xyz"
    echo -e "${GREEN}Prover started successfully.${NC}"
}

check_status() {
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        echo -e "${GREEN}Prover is running. Opening log window...${NC}"
        echo -e "${YELLOW}Tip: Close the terminal to exit; do not use Ctrl+C.${NC}"
        sleep 2
        tmux attach-session -t "$SESSION_NAME"
    else
        echo -e "${RED}Prover is not running.${NC}"
    fi
}

show_prover_id() {
    if [ -f "$PROVER_ID_FILE" ]; then
        local id=$(cat "$PROVER_ID_FILE")
        echo -e "${GREEN}Current Prover ID: $id${NC}"
    else
        echo -e "${RED}Prover ID not found.${NC}"
    fi
}

set_prover_id() {
    read -p "Enter new Prover ID: " new_id
    if [ -n "$new_id" ]; then
        echo "$new_id" > "$PROVER_ID_FILE"
        echo -e "${GREEN}Prover ID updated successfully.${NC}"
    else
        echo -e "${RED}Prover ID cannot be empty.${NC}"
    fi
}

stop_prover() {
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        tmux kill-session -t "$SESSION_NAME"
        echo -e "${GREEN}Prover stopped successfully.${NC}"
    else
        echo -e "${RED}Prover is not running.${NC}"
    fi
}

cleanup() {
    echo -e "\n${YELLOW}Cleaning up...${NC}"
    exit 0
}

trap cleanup SIGINT SIGTERM

while true; do
    echo -e "\n${YELLOW}=== Nexus Prover Management Tool ===${NC}"
    echo -e "${GREEN}Author: Zerah${NC}"
    
    echo "1. Install and Start Nexus"
    echo "2. Check Current Status"
    echo "3. View Prover ID"
    echo "4. Set Prover ID"
    echo "5. Stop Nexus"
    echo "6. Exit"
    
    read -p "Choose an action [1-6]: " choice
    case $choice in
        1)
            setup_directories
            check_dependencies
            download_files
            start_prover
            ;;
        2)
            check_status
            ;;
        3)
            show_prover_id
            ;;
        4)
            set_prover_id
            ;;
        5)
            stop_prover
            ;;
        6)
            echo -e "\n${GREEN}Thanks for using!${NC}"
            cleanup
            ;;
        *)
            echo -e "${RED}Invalid selection.${NC}"
            ;;
    esac
done
