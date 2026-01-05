# SIM Registration Machine - Assembly Language Project

## Overview
This is an 8086 assembly language program that simulates a SIM card registration system. Users can register with their National ID (NID) and fingerprint password, then purchase and customize SIM cards with numbers starting with "017".

## Features
1. **User Registration** - Register with 10-digit NID and 4-digit fingerprint password
2. **Customize SIM Number** - Choose last 4 digits of SIM number (017XXXX format)
3. **Buy New SIM Card** - Purchase SIM cards (random or customized)
4. **Check SIM Count** - View how many SIMs you own (max 8)
5. **Show Available SIMs** - Display all available SIM numbers in the system

## SIM Number Format
- All SIM numbers follow the format: **017XXXX**
- First 3 digits are fixed: **017**
- Last 4 digits can be customized (0000-9999)
- Numbers are stored internally as: 170000 + XXXX (e.g., 0171234 = 171234)

## Data Structures

### User Data
- `current_nid` - Stores user's 10-digit National ID
- `current_fp` - Stores user's 4-digit fingerprint password
- `user_sim_stack` - Array to store up to 8 SIM numbers (32-bit double words)
- `user_sim_count` - Counter for number of SIMs owned
- `customized_sim` - Stores customized SIM number for next purchase
- `has_customized` - Flag indicating if user has customized a number

### SIM Number Array
- `sim_numbers` - Pre-defined array of 10 available SIM numbers
- Numbers: 171234, 175678, 179012, 173456, 177890, 172345, 176789, 170123, 174567, 178901
- These represent: 0171234, 0175678, etc.

## Function Documentation

### Main Program Functions

#### `MAIN PROC`
**Purpose**: Entry point of the program
**Logic**:
- Initializes data segment
- Displays main menu in a loop
- Routes user choice to appropriate function
- Handles invalid input

#### `DISPLAY_MENU PROC`
**Purpose**: Displays the main menu with all options
**Logic**:
- Prints menu header and all 6 options
- Uses DOS interrupt 21H function 09H for string output

#### `GET_CHOICE PROC`
**Purpose**: Gets single character input from user
**Logic**:
- Uses DOS interrupt 21H function 01H
- Returns character in AL register

---

### Registration Functions

#### `REGISTER_USER PROC`
**Purpose**: Handles user registration with NID and fingerprint
**Logic**:
1. Prompts for 10-digit NID using buffered input (INT 21H, AH=0AH)
2. Copies NID from buffer to `current_nid` storage
3. Prompts for 4-digit fingerprint password
4. Copies password to `current_fp` storage
5. Displays success message and registered NID

**Input Method**: Buffered input (reads entire string at once)
- NID: 10 digits
- Password: 4 digits

**Error Handling**: None (accepts any input, validation can be added)

---

### SIM Customization Functions

#### `CUSTOMIZE_SIM_NUMBER PROC`
**Purpose**: Allows user to customize last 4 digits of SIM number
**Logic**:
1. Checks if user is registered
2. Checks if user has reached maximum (8 SIMs)
3. Prompts for 4-digit input using buffered input
4. Validates input:
   - Must be exactly 4 characters
   - All characters must be digits (0-9)
5. Converts string to number (0-9999)
6. Builds full SIM number: 170000 + 4-digit input
7. Checks if number already exists in user's SIMs
8. Validates number is in range (170000-179999)
9. Stores customized number for next purchase
10. Displays customized number in 017XXXX format

**32-bit Number Handling**:
- 170000 = 2 * 65536 + 38928 (requires 32-bit)
- Stores in DX:AX (high:low words)

**Error Cases Handled**:
- User not registered
- Maximum SIMs reached
- Invalid input (not 4 digits)
- Non-digit characters
- Number already owned
- Number out of range

---

### SIM Purchase Functions

#### `BUY_NEW_SIM PROC`
**Purpose**: Handles SIM card purchase
**Logic**:
1. Checks if user is registered
2. Checks if maximum limit reached (8 SIMs)
3. Prompts for fingerprint verification
4. Reads fingerprint using buffered input
5. Compares with stored fingerprint
6. If verified:
   - Checks if user has customized a number
   - If customized: uses customized number
   - If not: calls `SELECT_RANDOM_SIM` to pick from array
7. Stores SIM number in user's stack
8. Increments SIM count
9. Displays purchased SIM number

**Stack Implementation**:
- Uses array `user_sim_stack` as stack
- Stores 32-bit values (double words)
- Index calculation: `index * 4` (since each entry is 4 bytes)

**Error Cases Handled**:
- User not registered
- Maximum SIMs reached (8)
- Fingerprint verification failed

#### `SELECT_RANDOM_SIM PROC`
**Purpose**: Selects a random SIM number from available array
**Logic**:
1. Uses `user_sim_count` as index (simple pseudo-random)
2. If index exceeds array size, resets to 0
3. Calculates array offset: `index * 4` (double word size)
4. Retrieves 32-bit number from array
5. Returns in DX:AX (high:low words)

**Note**: This is a simple selection algorithm. For true randomness, use system time or other methods.

---

### Display Functions

#### `DISPLAY_NUMBER PROC`
**Purpose**: Displays a 32-bit number in decimal format
**Logic**:
1. Checks if high word (DX) is 0
2. If DX = 0: uses simple 16-bit division
3. If DX ≠ 0: uses 32-bit division algorithm
4. Converts number to string by repeated division by 10
5. Pushes digits onto stack
6. Pops and displays digits in correct order

**32-bit Division Algorithm**:
- Divides high word first
- Then divides low word with remainder
- Handles carry between divisions

#### `DISPLAY_SIM_NUMBER PROC`
**Purpose**: Displays SIM number in 017XXXX format
**Logic**:
1. Displays "017" prefix directly
2. Extracts last 4 digits: `number % 10000`
3. Converts 4-digit number to string
4. Pads with leading zeros if needed (e.g., 0123 instead of 123)
5. Displays the 4 digits

**Example**: 
- Input: 171234 (stored value)
- Output: 0171234 (displayed)

---

### Utility Functions

#### `CHECK_SIM_COUNT PROC`
**Purpose**: Displays how many SIMs the user owns
**Logic**:
1. Checks if user is registered
2. Retrieves `user_sim_count`
3. Displays count using `DISPLAY_NUMBER`
4. Shows message: "You have X SIM(s) registered."

**Error Handling**: Shows error if user not registered

#### `SHOW_AVAILABLE_SIMS PROC`
**Purpose**: Displays all available SIM numbers in the system
**Logic**:
1. Loops through `sim_numbers` array
2. For each number:
   - Retrieves 32-bit value
   - Calls `DISPLAY_SIM_NUMBER` to show in 017XXXX format
   - Adds comma separator (except last)
3. Displays all numbers in a list

**Output Format**: 0171234, 0175678, 0179012, ...

---

### Validation Functions

#### `CHECK_NUMBER_EXISTS PROC`
**Purpose**: Checks if a SIM number already exists in user's SIM stack
**Input**: DX:AX = 32-bit number to check
**Output**: AX = 1 if exists, 0 if not
**Logic**:
1. Saves input number in DI (low) and BP (high)
2. Loops through `user_sim_stack`
3. For each entry:
   - Compares low word (AX) with DI
   - If match, compares high word (DX) with BP
   - If both match, returns 1 (found)
4. If loop completes, returns 0 (not found)

**32-bit Comparison**: Compares both high and low words separately

#### `CHECK_IN_AVAILABLE_ARRAY PROC`
**Purpose**: Checks if a number exists in the available SIM array
**Input**: DX:AX = 32-bit number to check
**Output**: AX = 1 if exists, 0 if not
**Logic**:
- Similar to `CHECK_NUMBER_EXISTS` but searches `sim_numbers` array
- Currently not used in customization (only checks user's SIMs)

#### `CHECK_AVAILABILITY PROC`
**Purpose**: Placeholder function for availability checking
**Note**: Currently just displays "available" message. Can be extended for more complex validation.

---

## Program Flow

### Registration Flow
```
1. User selects option 1
2. Enter 10-digit NID (all at once)
3. Enter 4-digit password (all at once)
4. System stores credentials
5. Displays registered NID
6. Returns to main menu
```

### Customization Flow
```
1. User selects option 2
2. System checks: registered? max SIMs?
3. Enter 4 digits (all at once)
4. System validates: exactly 4 digits? all numeric?
5. Builds number: 170000 + 4-digit input
6. Checks if number already owned
7. If available: stores for next purchase
8. Displays customized number
9. Returns to main menu
```

### Purchase Flow
```
1. User selects option 3
2. System checks: registered? max SIMs?
3. Enter fingerprint password (all at once)
4. System verifies password
5. If verified:
   - Check if customized number exists
   - If yes: use customized number
   - If no: pick random from array
6. Store SIM in user's stack
7. Increment count
8. Display purchased SIM number
9. Returns to main menu
```

---

## Input/Output Methods

### Buffered Input (INT 21H, AH=0AH)
**Used for**: NID, fingerprint password, customization digits
**Format**: 
```
Buffer structure:
[Max Length][Actual Length][Data...]
```

**Example**:
- Buffer: `[11][10]['1','2','3'...]`
- First byte: maximum length (11 for NID)
- Second byte: actual length entered
- Remaining bytes: actual characters

### Character Input (INT 21H, AH=01H)
**Used for**: Menu choice selection
**Returns**: Single character in AL register

### String Output (INT 21H, AH=09H)
**Used for**: Displaying messages
**Requires**: String must end with '$' terminator

### Character Output (INT 21H, AH=02H)
**Used for**: Displaying single characters
**Input**: Character in DL register

---

## Error Handling

### Corner Cases Handled

1. **User Not Registered**
   - Checked in: Buy SIM, Customize, Check Count
   - Action: Display error message

2. **Maximum SIMs Reached (8)**
   - Checked in: Buy SIM, Customize
   - Action: Display "Maximum limit reached" message

3. **Invalid Input**
   - Customization: Not exactly 4 digits
   - Action: Display error message

4. **Non-Digit Characters**
   - Customization: Characters not 0-9
   - Action: Display error message

5. **Number Already Owned**
   - Customization: Number exists in user's SIMs
   - Action: Display "not available" message

6. **Number Out of Range**
   - Customization: Number not in 170000-179999
   - Action: Display error message

7. **Fingerprint Verification Failed**
   - Buy SIM: Password doesn't match
   - Action: Display error message

8. **Empty Input**
   - Handled by checking buffer length
   - Action: Treats as invalid input

---

## Memory Layout

### Data Segment
- **Menu strings**: Static messages
- **Input buffers**: Temporary storage for user input
- **SIM array**: Pre-defined available numbers
- **User data**: Current session data
- **Stack**: User's purchased SIMs (max 8)

### Stack Segment
- Used for: Function calls, register preservation, digit conversion

---

## Technical Details

### 32-bit Number Handling
Since SIM numbers (170000-179999) exceed 16-bit range (65535), the program uses:
- **Double Words (DD)**: 32-bit storage
- **DX:AX pairs**: High word in DX, low word in AX
- **Array indexing**: Multiply by 4 (4 bytes per double word)

### Number Conversion
- **String to Number**: Repeated multiplication by 10 and addition
- **Number to String**: Repeated division by 10, push digits, pop and display

### Stack Implementation
- Uses array as stack structure
- Index = `user_sim_count`
- Offset = `index * 4` (double word size)
- Stores 32-bit values

---

## Compilation and Execution

### Requirements
- emu8086 or compatible 8086 assembler
- DOS environment or DOS emulator

### Compilation
1. Open `mycode.asm` in emu8086
2. Assemble the code
3. Run the program

### Usage
1. Run the program
2. Select option 1 to register
3. Enter NID (10 digits) and password (4 digits)
4. Use other options as needed:
   - Option 2: Customize SIM number
   - Option 3: Buy SIM card
   - Option 4: Check SIM count
   - Option 5: Show available SIMs
   - Option 6: Exit

---

## Future Enhancements

1. **True Random Number Generation**: Use system time for random SIM selection
2. **Input Validation**: Validate NID format and password strength
3. **SIM Management**: Add option to view all owned SIMs
4. **Delete SIM**: Allow users to remove SIMs
5. **Persistent Storage**: Save data to file
6. **Multiple Users**: Support multiple user accounts
7. **SIM Number Pool**: Dynamically generate available numbers
8. **Better Error Messages**: More descriptive error handling

---

## Code Structure Summary

```
MAIN
├── DISPLAY_MENU
├── GET_CHOICE
├── REGISTER_USER
│   └── (Buffered input for NID and password)
├── CUSTOMIZE_SIM_NUMBER
│   ├── (Input validation)
│   ├── CHECK_NUMBER_EXISTS
│   └── DISPLAY_SIM_NUMBER
├── BUY_NEW_SIM
│   ├── (Fingerprint verification)
│   ├── SELECT_RANDOM_SIM (if not customized)
│   └── DISPLAY_SIM_NUMBER
├── CHECK_SIM_COUNT
│   └── DISPLAY_NUMBER
└── SHOW_AVAILABLE_SIMS
    └── DISPLAY_SIM_NUMBER
```

---

## Author Notes

This project demonstrates:
- 8086 assembly language programming
- DOS interrupt handling
- 32-bit number manipulation
- Stack data structure implementation
- Input validation and error handling
- Menu-driven program design
- String and number conversion algorithms

---

## License

Educational project for CSE 341 course.
