#!/bin/bash

# OCaml Test Runner Script
# Assignment 4: Stack-based Evaluator for Combinatory Logic

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}================================${NC}"
echo -e "${YELLOW}OCaml Assignment 4 Test Runner${NC}"
echo -e "${YELLOW}================================${NC}\n"

# Check if OCaml is installed
if ! command -v ocaml &> /dev/null; then
    echo -e "${RED}Error: OCaml is not installed${NC}"
    echo "Please install OCaml first"
    exit 1
fi

echo -e "${GREEN}✓ OCaml found: $(ocaml -version)${NC}\n"

# Copy files to working directory if they exist in uploads
if [ -f "/mnt/user-data/uploads/Ass4.ml" ]; then
    echo "Copying Ass4.ml from uploads..."
    cp /mnt/user-data/uploads/Ass4.ml .
fi

if [ -f "/mnt/user-data/uploads/tests.ml" ]; then
    echo "Copying tests.ml from uploads..."
    cp /mnt/user-data/uploads/tests.ml .
fi

echo ""

# Check if required files exist
if [ ! -f "Ass4.ml" ]; then
    echo -e "${RED}Error: Ass4.ml not found${NC}"
    exit 1
fi

if [ ! -f "tests.ml" ]; then
    echo -e "${RED}Error: tests.ml not found${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Found Ass4.ml${NC}"
echo -e "${GREEN}✓ Found tests.ml${NC}\n"

# Clean up old compiled files
echo "Cleaning up old compiled files..."
rm -f *.cmi *.cmo *.cmx *.o a.out
echo ""

# Run the tests
echo -e "${YELLOW}Running tests...${NC}\n"
echo "========================================"

if ocaml tests.ml; then
    echo "========================================"
    echo -e "\n${GREEN}✓ All tests completed successfully!${NC}\n"
    exit 0
else
    echo "========================================"
    echo -e "\n${RED}✗ Tests failed!${NC}\n"
    exit 1
fi