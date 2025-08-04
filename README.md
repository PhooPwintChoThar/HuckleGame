# Hurkle Game - README Documentation

## Student Information
- **Full Name:** [Your Full Name]
- **Student ID:** [Your Student ID]
- **Date of Submission:** January 8, 2025

## How to Compile and Run

# To Assemble:
as -o hurkle.o hurkle.s

# To Link:
ld -o hurkle hurkle.o

# To Run:
./hurkle


## Design and Implementation Details

### Program Structure
The program is organized into eight main subroutines as required:

1. **`initialize_game`**
   - **Purpose:** Sets up the initial game state
   - **Input:** None
   - **Output:** Initializes hurkle_x, hurkle_y (random coordinates 0-9), and guess_count (0)
   - **Implementation:** Calls `init_random` to seed PRNG, then generates two random coordinates using `generate_one_random_number`

2. **`init_random`**
   - **Purpose:** Initializes the random number generator with a cryptographically secure seed
   - **Input:** None
   - **Output:** Returns 0 on success, -1 on error
   - **Implementation:** Opens `/dev/urandom`, reads 4 bytes for seed, initializes PRNG state

3. **`generate_one_random_number`**
   - **Purpose:** Generates a uniformly distributed random number between 0-9
   - **Input:** None
   - **Output:** Random number (0-9) in r0
   - **Implementation:** Uses Linear Congruential Generator with rejection sampling for uniform distribution

2. **`game_loop`**
   - **Purpose:** Controls the main flow of the game
   - **Input:** None
   - **Output:** Manages the game until win/lose condition
   - **Implementation:** Increments guess count, calls other subroutines, checks win/lose conditions
   - **Flow:** 
     - Checks if maximum guesses (10) reached
     - Increments guess counter
     - Calls `get_player_guess` to get user input
     - Checks for exact match (win condition)
     - Calls `process_feedback` for hints
     - Loops until game ends

3. **`get_player_guess`**
   - **Purpose:** Handles all player interaction
   - **Input:** None (reads from stdin)
   - **Output:** Sets player_x and player_y variables
   - **Implementation:** 
     - Prints "Enter X Y: " prompt using `print_string`
     - Reads user input into buffer using sys_read syscall
     - Parses ASCII input to extract two single-digit coordinates
     - Skips whitespace and handles basic input formatting

4. **`process_feedback`**
   - **Purpose:** Compares guess to Hurkle location and provides hints
   - **Input:** Uses player_x, player_y, hurkle_x, hurkle_y variables
   - **Output:** Prints directional and proximity hints
   - **Implementation:**
     - Compares Y coordinates: prints "↑ Too high!" or "↓ Too low!"
     - Compares X coordinates: prints "← Too far left!" or "→ Too far right!"
     - Calculates Manhattan distance: |GX - HX| + |GY - HY|
     - If distance ≤ 2, prints "You are very close!"

5. **`print_string`**
   - **Purpose:** General-purpose string printing helper
   - **Input:** r0 = address of null-terminated string
   - **Output:** Prints string to stdout
   - **Implementation:**
     - Calculates string length by searching for null terminator
     - Uses sys_write syscall (r7=#4) to output to stdout

6. **`int_to_str`**
   - **Purpose:** Converts integers to printable ASCII strings
   - **Input:** r0 = integer to convert
   - **Output:** Stores result in num_buffer
   - **Implementation:**
     - Converts integer to string by repeatedly dividing by 10
     - Builds string backwards, then copies to buffer
     - Handles special case of zero

### Key Design Choices

1. **Random Number Generation:** Implemented a professional-grade random number generator using:
   - **Seed Source:** `/dev/urandom` for cryptographically secure seeding
   - **Algorithm:** Linear Congruential Generator (LCG) with parameters from glibc
   - **Distribution:** Rejection sampling to ensure uniform distribution over [0-9]
   - **Fallback:** If `/dev/urandom` fails, uses fixed coordinates (5,3) for testing

2. **Input Parsing:** The program expects single-digit coordinates (0-9) separated by space. It skips whitespace characters and converts ASCII digits to integers by subtracting '0'.

3. **Memory Management:** Uses static data section for all variables and buffers. No dynamic memory allocation needed.

4. **Error Handling:** Robust random number initialization with fallback. Basic input validation assumes user follows the format.

5. **Modular Design:** Each subroutine has a single responsibility and communicates through registers and global variables, following ARM calling conventions.


## Challenges Faced

### 1. **Architecture Compatibility**
- **Problem:** Assignment requires 32-bit ARM assembly, but my device only supports 64-bit ARM (AArch64) architecture
- **Solution:** Set up a Raspberry Pi with Raspberry Pi OS, which natively supports 32-bit ARM assembly development and execution

### 2. **Development Environment Setup**
- **Problem:** Local development tools on my device cannot natively assemble and run 32-bit ARM code
- **Solution:** 
  - Flashed Raspberry Pi OS to micro SD card using Raspberry Pi Imager
  - Pre-configured WiFi credentials and SSH access during OS customization
  - Established seamless SSH connection using `ssh username@raspberrypi.local` over local network
  - Created efficient development workflow between MacBook (editing) and Raspberry Pi (compilation/testing)

### 3. **System Call Interface and ARM Assembly Syntax**
- **Problem:** Different operating systems and architectures use different syscall numbers and calling conventions
- **Solution:** Used Linux ARM syscall numbers (sys_read=3, sys_write=4, sys_exit=1) with software interrupt instruction `swi 0`, which are standard for Raspberry Pi OS (32-bit ARM Linux)

### 4. **String Parsing and Number Conversion**
- **Problem:** Converting ASCII input to integers and integers back to strings for output
- **Solution:** Implemented manual parsing routines with careful handling of ASCII values and null terminators

### 5. **Random Number Generation Quality**
- **Problem:** Assignment requires truly random Hurkle placement, but simple LCG can be predictable
- **Solution:** Implemented cryptographically secure seeding from `/dev/urandom` with rejection sampling for uniform distribution

### 6. **Assembly Syntax and Register Management**
- **Problem:** 32-bit ARM assembly has specific syntax requirements and register usage conventions
- **Solution:** Careful attention to ARM assembly syntax, proper use of stack operations (push/pop), and systematic register allocation throughout subroutines

### 7. **Debugging Assembly Code**
- **Problem:** Limited debugging tools compared to high-level languages
- **Solution:** Added systematic commenting and used simple test cases to verify each subroutine individually

## Testing Notes

The program has been designed to handle:
- Valid input: "3 7", "0 9", "5 5"
- Coordinates from 0-9 as specified
- Up to 10 guesses maximum
- All four directional hints and proximity feedback
- Proper win/lose message formatting

## Game Flow Example

1. Program starts, generates random Hurkle coordinates
2. Player enters coordinates: "3 5"
3. Program compares to Hurkle location and provides hints
4. Process repeats until player finds Hurkle or runs out of guesses
5. Appropriate win/lose message displayed with game statistics

## Video record
https://drive.google.com/drive/folders/1vfPCpzXgzcwa3EjmBkDPojjXLTSsTgoq?usp=share_link

