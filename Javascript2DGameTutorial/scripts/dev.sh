#!/bin/bash

# JavaScript 2D Game - Development Script

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to check if Python is available
check_python() {
    if command -v python3 &> /dev/null; then
        PYTHON_CMD="python3"
    elif command -v python &> /dev/null; then
        PYTHON_CMD="python"
    else
        print_warning "Python not found. Please install Python 3."
        exit 1
    fi
}

# Function to start development server
start_dev_server() {
    print_status "Starting development server..."
    print_status "Game will be available at: http://localhost:8000/public/"
    print_status "Press Ctrl+C to stop the server"
    
    cd "$(dirname "$0")/.."
    $PYTHON_CMD -m http.server 8000
}

# Function to run code quality checks
run_lint() {
    print_status "Running ESLint..."
    if command -v npx &> /dev/null; then
        npx eslint src/js/**/*.js
        print_success "Linting completed!"
    else
        print_warning "npx not found. Install Node.js to use linting."
    fi
}

# Function to format code
format_code() {
    print_status "Formatting code with Prettier..."
    if command -v npx &> /dev/null; then
        npx prettier --write src/**/*.{js,css}
        print_success "Code formatting completed!"
    else
        print_warning "npx not found. Install Node.js to use formatting."
    fi
}

# Function to open game in browser
open_browser() {
    print_status "Opening game in browser..."
    if command -v open &> /dev/null; then
        open http://localhost:8000/public/
    elif command -v xdg-open &> /dev/null; then
        xdg-open http://localhost:8000/public/
    else
        print_warning "Could not open browser automatically."
        print_status "Please open: http://localhost:8000/public/"
    fi
}

# Main script
main() {
    local COMMAND=$1
    
    case $COMMAND in
        "start"|"dev")
            check_python
            start_dev_server
            ;;
        "lint")
            run_lint
            ;;
        "format")
            format_code
            ;;
        "open")
            open_browser
            ;;
        "help"|"--help"|"-h")
            echo "Usage: $0 {start|dev|lint|format|open}"
            echo ""
            echo "Commands:"
            echo "  start, dev  - Start development server"
            echo "  lint        - Run ESLint code quality check"
            echo "  format      - Format code with Prettier"
            echo "  open        - Open game in browser"
            echo "  help        - Show this help message"
            ;;
        *)
            print_warning "Unknown command: $COMMAND"
            echo "Use '$0 help' for usage information."
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@" 