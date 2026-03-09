use std::fs::{self, File};
use std::io::{BufRead, BufReader, Read, Write};
use tui::widgets::ListState;

//CHANGED ADD INSTRUCTION
//todo fix movt 620, change reg line 50, implment v 325, add new oppcodes,fix reg locaitons 222, make pc a register line 32,add r instructions instead of just i.

pub struct CPU {
    pub state: ListState,

    //state reached by HALT
    pub stop_state: bool,

    //vector of all instructions executed for UI
    pub prog_mem: Vec<String>,

    //raw contents of mem file
    pub raw_mem: Vec<String>,

    //start address of data in memory
    pub data_start: u32,

    //last memory address written to
    pub last_w: u32,

    //last memory address read from
    pub last_r: u32,

    //last program counter location
    pub last_pc: u32,

    //program counter
    pub program_counter: u32, //remove and make register

    //unused
    pub status: u16,

    //negative flag
    pub N: u8,

    //carry flag
    pub C: u8,

    //zero flag
    pub Z: u8,

    //overflow flag
    pub V: u8,

    //register array
    pub register: [u32; 0x10], //increase number

    //memory vector
    pub memory: Vec<u32>,
}

//methods belonging to CPU struct
impl CPU {
    //initializing default values
    pub fn new(memory_size: u32) -> Self {
        CPU {
            state: ListState::default(),

            stop_state: false,

            prog_mem: Vec::new(),

            raw_mem: Vec::new(),

            data_start: 0,

            last_w: 0,

            last_r: 0,

            last_pc: 0,

            program_counter: 0,

            status: 0,

            N: 0,

            C: 0,

            Z: 0,

            V: 0,

            register: [0; 16],

            //vector of length 0x50 filled with zeros
            memory: vec![0; memory_size as usize],
        }
    }

    pub fn setup(&mut self, file_path: String) {
        //open mem file
        let mem_file = fs::read_to_string(file_path).expect("Unable to read file");

        //parse memory file
        let reader = BufReader::new(mem_file.as_bytes());

        //vector to contain program
        let mut program: Vec<u32> = Vec::new();

        //start address to write to set to 0 by default
        let mut start_addr: u32 = 0;

        //read every line in mem file
        for line in reader.lines() {
            //add every line to raw mem vector for display
            self.raw_mem.push(line.as_ref().unwrap().to_string());

            //remove all whitespace from line
            let data_line = line.unwrap().to_string().replace(' ', "");

            //if line starts with '@' it indicates new write address
            if data_line.starts_with('@') {
                //if not first line in program
                if program.len() > 0 {
                    //load section of program read into memory at new write address
                    self.load(&program, start_addr);
                    //clear program vector
                    program.clear();
                } else {
                    self.data_start = u32::from_str_radix(&data_line.replace('@', ""), 16).unwrap();
                }
                //set new write address from line as int from hex
                start_addr = u32::from_str_radix(&data_line.replace('@', ""), 16).unwrap();
            } else {
                //add line to program vector as int from hex
                program.push(u32::from_str_radix(&data_line, 16).unwrap());
            }
        }
        //loads current program section into memory
        self.load(&program, start_addr);
    }

    //loads program into memory array
    pub fn load(&mut self, program: &Vec<u32>, addr: u32) {
        //address to start writing to
        let mut n = addr;

        //iterate through program vector and add to memory
        for e in program {
            self.memory[n as usize] = *e;
            n = n + 4;
        }
    }

    //writes to memory array
    pub fn write(&mut self, addr: u32, data: u32) {
        self.memory[addr as usize] = data;
        self.last_w = addr;
    }

    //reads from memory array
    pub fn read(&mut self, addr: u32) -> u32 {
        self.last_r = addr;
        self.memory[addr as usize]
    }

    ///////////////
    //  Run CPU  //
    ///////////////

    pub fn run(&mut self, mut count: u32) {
        //runs number of cycles specified in count
        while count > 0 && !self.stop_state {
            //space used for instruction vector
            let spc = " ";

            /////////////////////////
            //  Fetch instruction  //
            /////////////////////////

            let instruction: u32;

            //increments program counter
            if self.status == 0 {
                instruction = self.memory[self.program_counter as usize];
                self.status = 1;
            } else {
                self.program_counter += 4;
                instruction = self.memory[self.program_counter as usize];
            }

            //adds PC value to variable for displaying last PC location
            self.last_pc = self.program_counter;
            
            //setting r15 as pc might want to make this nicer later
            self.register[15 as usize] = self.program_counter;

            //bitmask for relevant opcode bits
            let opcode = ((instruction & 0b1111_1110_0000_0000_0000_0000_0000_0000) >> 25) as u8;

            //bitmask for bit used to represent I vs R types
            let mode = ((instruction & 0b0100_0000_0000_0000_0000_0000_0000_0000) >> 30) as u8;

            //bitmask for bit indicating setting flags
            //left in incase wanted to be used in future but unneeded in curent version of code
            //let set_flags = ((instruction & 0b0001_0000_0000_0000_0000_0000_0000_0000) >> 28) as u8;

            //bitmask for destination register 
            //update masks
            let destination =
                ((instruction & 0b0000_0001_1110_0000_0000_0000_0000_0000) >> 21) as u32;

            //bitmask for source regitser
            let source = ((instruction & 0b0000_0000_0001_1110_0000_0000_0000_0000) >> 17) as u32;

            //bitmask for optional register
            let op2 = ((instruction & 0b0000_0000_0000_0001_1110_0000_0000_0000) >> 13) as u32;

            //bitmask for immediate or offset
            let immediate = (instruction & 0b0000_0000_0000_0000_1111_1111_1111_1111) as i16;

            ////////////////////
            // execute opcode //
            ////////////////////

            match opcode {
                 0x00 => {
                    //MOV
                    //without this you get overflow in code. this should eventually be removed because i is meant to be signed in class ISA
                    self.prog_mem.push(format!(
                        "MOV({})    R{}   {:#X}",
                        opcode, destination, immediate
                    ));
                    self.register[destination as usize] = (immediate as u32) & 0b0000_0000_0000_0000_1111_1111_1111_1111;
                }

                0x1 => {
                    //MOVT
                    //without this you get overflow in code. this should eventually be removed because i is meant to be signed in class ISA
                    
                    let value = ((immediate as u32) & 0b0000_0000_0000_0000_1111_1111_1111_1111) << 16;

                    self.prog_mem.push(format!(
                        "MOVT({})    R{}   {:#X}",
                        opcode, destination, immediate
                    ));
                    self.register[destination as usize] =
                        (value | (self.register[destination as usize] & 0b0000_0000_0000_0000_1111_1111_1111_1111)) as u32; //add a bit map to wipe the top values
                }

                0x6 =>{
                    //MOVF

                    let value = (self.N << 3) + (self.Z << 2) + (self.C << 1) + self.V;
                    self.prog_mem.push(format!(
                        "MOVF({})    R{}",
                        opcode, destination,
                    ));
                    self.register[destination as usize] = value as u32;
                }

                0xE =>{
                    //SAVF
                    let value = self.register[destination as usize] as u32;
                    self.prog_mem.push(format!(
                        "SAVF({})    R{}",
                        opcode, destination,
                    ));
                    if (value & 0b0000_0000_0000_0000_0000_0000_0000_1000)!=0{
                        self.N =1 as u8;
                    }
                    else{
                        self.N =0 as u8;
                    }
                    if (value & 0b0000_0000_0000_0000_0000_0000_0000_0100)!=0{
                        self.Z=1 as u8;
                    } 
                    else{
                        self.Z =0 as u8;
                    }
                    if (value & 0b0000_0000_0000_0000_0000_0000_0000_0010)!=0{
                        self.C=1 as u8;
                    }
                    else{
                        self.C =0 as u8;
                    }
                    self.V=(value & 0b0000_0000_0000_0000_0000_0000_0000_0001) as u8;
                }


               0x64 => {
                    //NOP
                    self.prog_mem.push(format!("NOP({})", opcode));
                }

                0x40 => {
                    //LOAD

                    self.prog_mem.push(format!(
                        "LOAD({}) R{}   R{}   {:#X}",
                        opcode, destination, source, immediate
                    ));
                    // immediate is divided by four because memory array increments by 1 instead of 4
                    self.register[destination as usize] =
                        self.read(self.register[source as usize] + immediate as u32);
                }

                0x41 => {
                    //STOR

                    self.prog_mem.push(format!(
                        "STOR({}) R{}   R{}   {:#X}",
                        opcode, destination, source, immediate
                    ));
                    // immediate is divided by four because memory array increments by 1 instead of 4
                    self.write(
                        self.register[source as usize] + immediate as u32,
                        self.register[destination as usize],
                    );
                }

                0x30 | 0x10 => {
                    //MUL
                    let result; //product
                    let mult; //changes based on reg vs imm
                    if mode > 0 {   //reg version
                        self.prog_mem.push(format!(
                            "MUL({})  R{}   R{}   R{}",
                            opcode, destination, source, op2
                        ));
                        mult = self.register[op2 as usize];
                    } else {    //imm version
                        self.prog_mem.push(format!(
                            "MUL({})  R{}   R{}   {:#X}",
                            opcode, destination, source, immediate
                        ));
                        mult = immediate as u32;
                    }
                    //ignoring the overflow output for MUL
                    result = self.register[source as usize].overflowing_mul(mult).0;
                    self.register[destination as usize] = result;
                }

                0x38 | 0x18 => {
                    //MULS
                    let result; //product
                    let overflow;   //signed overflow
                    let carry;  //unsigned carry
                    let mult;   //changes based on reg vs imm

                    if mode > 0 {   //reg version
                        self.prog_mem.push(format!(
                            "MULS({})  R{}   R{}   R{}",
                            opcode, destination, source, op2
                        ));
                        mult = self.register[op2 as usize];
                    } else {    //imm version
                        self.prog_mem.push(format!(
                            "MULS({})  R{}   R{}   {:#X}",
                            opcode, destination, source, immediate
                        ));
                        mult = immediate as u32;
                    }
                    //finding result and C flag w/ unsigned multiplication
                    (result, carry) = self.register[source as usize].overflowing_mul(mult);
                    //casting to i32 to find V flag, ignoring sum
                    overflow = (self.register[source as usize] as i32).overflowing_mul(mult as i32).1;
                    self.register[destination as usize] = result;

                    //flag maths
                    self.Z = (result == 0) as u8;
                    self.N = ((result as i32) < 0) as u8;
                    self.C = carry as u8;
                    self.V = overflow as u8;
                }

                0x31 | 0x11 => {
                    //ADD
                    let result; //sum
                    let addend; //changes based on reg vs imm

                    if mode > 0 {   //reg version
                        self.prog_mem.push(format!(
                            "ADD({})  R{}   R{}   R{}",
                            opcode, destination, source, op2
                        ));
                        addend = self.register[op2 as usize];
                    } else {    //imm version
                       self.prog_mem.push(format!(
                        "ADD({})  R{}   R{}   {:#X}",
                        opcode, destination, source, immediate
                        ));
                        addend = immediate as u32;
                    }
                    //ignoring the overflow output for ADD
                    result = self.register[source as usize].overflowing_add(addend).0;
                    self.register[destination as usize] = result;
                }

                0x39 | 0x19 => {
                    //ADDS
                    let result;
                    let overflow;  //signed overflow
                    let carry;     //unsigned carry
                    let addend; //signed and unsigned versions

                    if mode > 0 {   //reg version
                        self.prog_mem.push(format!(
                            "ADDS({})    R{}   R{}   R{}",
                            opcode, destination, source, op2
                        ));
                        addend = self.register[op2 as usize] as u32;
                       
                    } else {    //imm version
                        self.prog_mem.push(format!(
                            "ADDS({})    R{}   R{}   {:#X}",
                            opcode, destination, source, immediate
                        ));
                        addend = immediate as u32; 
                      
                    }
                    //finding result and C flag w/ unsigned addition
                    (result,carry) = self.register[source as usize].overflowing_add(addend);
                    //casting to i32 to find V flag, ignoring sum
                    overflow = (self.register[source as usize] as i32).overflowing_add(addend as i32).1;
                    self.register[destination as usize] = result;

                    //flag maths
                    self.Z = (result == 0) as u8;
                    self.N = ((result as i32) < 0) as u8;
                    self.C = carry as u8;
                    self.V = overflow as u8;
                }

                0x12 | 0x32 => {
                    //SUB
                    let result;
                    let subend;
                    if mode > 0 {
                        //let op2 = ((instruction & 0b0000_0000_0000_0111_0000_0000_0000_0000) >> 16) as u32;
                        self.prog_mem.push(format!(
                            "SUB({})   R{}   R{}   R{}",
                            opcode, destination, source, op2
                            
                        ));
                        subend=self.register[op2 as usize] as u32;
                    } else {
                        self.prog_mem.push(format!(
                            "SUB({})   R{}   R{}   {:#X}",
                            opcode, destination, source, immediate
                        ));
                        subend = immediate as u32;
                    }
                    result = self.register[source as usize].overflowing_sub(subend).0;
                    self.register[destination as usize] = result;
                }

                0x1A | 0x3A => {
                    //CMP/SUBS

                    let result;
                    let carry;
                    let subend;
                    let overflow;
                   if mode > 0 {
                        self.prog_mem.push(format!(
                            "SUBS({})  R{}   R{}   R{}",
                            opcode, destination, source, op2
                            
                        ));
                        subend=self.register[op2 as usize] as u32;
                    } else {
                        self.prog_mem.push(format!(
                            "SUBS({})  R{}   R{}   {:#X}",
                            opcode, destination, source, immediate
                        ));
                       
                        subend=immediate as u32;
                    }
                    (result, carry) =
                            self.register[source as usize].overflowing_sub(subend);
                    overflow=
                            (self.register[source as usize] as i32).overflowing_sub(subend as i32).1;
                    self.register[destination as usize] = result;        
                    self.Z= (result==0) as u8;
                    self.N= ((result as i32) < 0) as u8;
                    self.C= carry as u8;
                    self.V=overflow as u8;
                }
                
                0x33 | 0x13 => {
                    //AND
                    if mode > 0{
                        self.prog_mem.push(format!(
                            "AND({})   R{}   R{}   R{}",
                            opcode, destination, source, op2
                        ));
                        self.register[destination as usize] =
                            self.register[source as usize] & self.register[op2 as usize];
                    }
                    else{
                        self.prog_mem.push(format!(
                            "AND({})   R{}   R{}   {:#X}",
                            opcode, destination, source, immediate
                        ));
                        self.register[destination as usize] =
                            self.register[source as usize] & immediate as u32;
                    }
                }
                
                //ANDS should set N and Z flags and C and V should be 0
                0x3B | 0x1B => {
                    //ANDS
                    if mode > 0{
                        self.prog_mem.push(format!(
                            "ANDS({})   R{}   R{}   R{}",
                            opcode, destination, source, op2
                        ));
                        self.register[destination as usize] =
                            self.register[source as usize] & self.register[op2 as usize];
                    }
                    else{
                        self.prog_mem.push(format!(
                            "ANDS({})   R{}   R{}   {:#X}",
                            opcode, destination, source, immediate
                        ));
                        self.register[destination as usize] =
                            self.register[source as usize] & immediate as u32;
                    }
                    self.Z= (self.register[destination as usize] == 0) as u8;
                    self.N= ((self.register[destination as usize] as i32) < 0) as u8;
                    self.V=0;
                    self.C=0;
                }

                0x34|0x14 => {
                    //OR
                    if mode > 0{
                        self.prog_mem.push(format!(
                            "OR({})   R{}   R{}   R{}",
                            opcode, destination, source, op2
                        ));
                        self.register[destination as usize] =
                            self.register[source as usize] | self.register[op2 as usize];
                    }
                    else{
                        self.prog_mem.push(format!(
                            "OR({})   R{}   R{}   {:#X}",
                            opcode, destination, source, immediate
                        ));
                        self.register[destination as usize] =
                            self.register[source as usize] | immediate as u32;
                    }
                }

                0x3C|0x1C => {
                    //ORS
                    if mode > 0{
                        self.prog_mem.push(format!(
                            "ORS({})   R{}   R{}   R{}",
                            opcode, destination, source, op2
                        ));
                        self.register[destination as usize] =
                            self.register[source as usize] | self.register[op2 as usize];
                    }
                    else{
                        self.prog_mem.push(format!(
                            "ORS({})   R{}   R{}   {:#X}",
                            opcode, destination, source, immediate
                        ));
                        self.register[destination as usize] =
                            self.register[source as usize] | immediate as u32;
                    }
                    self.Z= (self.register[destination as usize] == 0) as u8;
                    self.N= ((self.register[destination as usize] as i32) < 0) as u8;
                    self.V=0;
                    self.C=0;
                }

                0x35|0x15 => {
                    //XOR
                    if mode > 0{
                        self.prog_mem.push(format!(
                            "XOR({})   R{}   R{}   R{}",
                            opcode, destination, source, op2
                        ));
                        self.register[destination as usize] =
                            self.register[source as usize] ^ self.register[op2 as usize];
                    }
                    else{
                        self.prog_mem.push(format!(
                            "XOR({})   R{}   R{}   {:#X}",
                            opcode, destination, source, immediate
                        ));
                        self.register[destination as usize] =
                            self.register[source as usize] ^ immediate as u32;
                    }                 
                }

                0x3D|0x1D => {
                    //XORS
                    if mode > 0{
                        self.prog_mem.push(format!(
                            "XORS({})   R{}   R{}   R{}",
                            opcode, destination, source, op2
                        ));
                        self.register[destination as usize] =
                            self.register[source as usize] ^ self.register[op2 as usize];
                    }
                    else{
                        self.prog_mem.push(format!(
                            "XORS({})   R{}   R{}   {:#X}",
                            opcode, destination, source, immediate
                        ));
                        self.register[destination as usize] =
                            self.register[source as usize] ^ immediate as u32;
                    }
                    self.Z= (self.register[destination as usize] == 0) as u8;
                    self.N= ((self.register[destination as usize] as i32) < 0) as u8;
                    self.V=0;
                    self.C=0;                 
                }

                0x36 =>{
                    //NOT
                    self.prog_mem
                        .push(format!("NOT({})   R{}   R{}",opcode, destination, source));
                    
                    self.register[destination as usize] = !(self.register[source as usize] as u32);
                }

                0x60 => {
                    //B

                    self.prog_mem
                        .push(format!("B({})      {}", opcode, immediate));
                    self.prog_mem.push(spc.to_string());
                    self.prog_mem.push(format!("Branch Taken\n"));

                    //removed first instructions for smooth scrollin in UI
                    self.prog_mem.remove(0);
                    self.prog_mem.remove(0);
                    self.program_counter =
                        (self.program_counter as i32 - 4 + (immediate) as i32) as u32;
                     self.register[15 as usize] = self.program_counter;
                }

                0x61 => {
                    //b.cond

                    //bitmask for condition specified
                    let condition =
                        ((instruction & 0b0000_0001_1110_0000_0000_0000_0000_0000) >> 21) as u32;

                    //TODO fix print spacing and add extra renove for all conds
                    match condition {
                        0x0 => {
                            self.prog_mem
                                .push(format!("b.eq({}) {}", opcode, immediate));
                            if self.Z == 1 {
                                self.prog_mem.push(format!("Condition Met\n"));
                                self.prog_mem.remove(0);
                                self.program_counter =
                                    (self.program_counter as i32 - 4 + (immediate) as i32) as u32;
                            }
                        }

                        0x1 => {
                            self.prog_mem
                                .push(format!("b.ne({})  {}", opcode, immediate));
                            if self.Z == 0 {
                                self.prog_mem.push(format!("Condition Met\n"));
                                self.prog_mem.remove(0);
                                self.program_counter =
                                    (self.program_counter as i32 - 4 + (immediate) as i32) as u32;
                            }
                        }

                        0x2 => {
                            self.prog_mem
                                .push(format!("b.hs({}) {}", opcode, immediate));
                            if self.C == 1 {
                                self.prog_mem.push(format!("Condition Met\n"));
                                self.prog_mem.remove(0);
                                self.program_counter =
                                    (self.program_counter as i32 - 4 + (immediate) as i32) as u32;
                            }
                        }

                        0x3 => {
                            self.prog_mem
                                .push(format!("b.lo({}) {}", opcode, immediate));
                            if self.C == 0 {
                                self.prog_mem.push(format!("Condition Met\n"));
                                self.prog_mem.remove(0);
                                self.program_counter =
                                    (self.program_counter as i32 + ((immediate) - 4) as i32) as u32;
                            }
                        }

                        0x4 => {
                            self.prog_mem
                                .push(format!("b.mi({}) {}", opcode, immediate));
                            if self.N == 1 {
                                self.prog_mem.push(format!("Condition Met\n"));
                                self.prog_mem.remove(0);
                                self.program_counter =
                                    (self.program_counter as i32 + (immediate - 4) as i32) as u32;
                            }
                        }

                        0x5 => {
                            self.prog_mem
                                .push(format!("b.pl({})  {}", opcode, immediate));
                            if self.N == 0 {
                                self.prog_mem.push(format!("Condition Met\n"));
                                self.prog_mem.remove(0);
                                self.program_counter =
                                    (self.program_counter as i32 + ((immediate) - 4) as i32) as u32;
                            }
                        }

                        0x6 => {
                            self.prog_mem
                                .push(format!("b.vs({})  {}", opcode, immediate));
                            if self.V == 1 {
                                self.prog_mem.push(format!("Condition Met\n"));
                                self.prog_mem.remove(0);
                                self.program_counter =
                                    (self.program_counter as i32 + ((immediate) - 4) as i32) as u32;
                            }
                        }

                        0x7 => {
                            self.prog_mem
                                .push(format!("b.vc({})  {}", opcode, immediate));
                            if self.V == 0 {
                                self.prog_mem.push(format!("Condition Met\n"));
                                self.prog_mem.remove(0);
                                self.program_counter =
                                    (self.program_counter as i32 + ((immediate) - 4) as i32) as u32;
                            }
                        }

                        0x8 => {
                            self.prog_mem
                                .push(format!("b.hi({})  {}", opcode, immediate));
                            if self.Z == 0 && self.C == 1 {
                                self.prog_mem.push(format!("Condition Met\n"));
                                self.prog_mem.remove(0);
                                self.program_counter =
                                    (self.program_counter as i32 + ((immediate) - 4) as i32) as u32;
                            }
                        }

                        0x9 => {
                            self.prog_mem
                                .push(format!("b.ls({})  {}", opcode, immediate));
                            if !(self.Z == 0 && self.C == 1) {
                                self.prog_mem.push(format!("Condition Met\n"));
                                self.prog_mem.remove(0);
                                self.program_counter =
                                    (self.program_counter as i32 + ((immediate) - 4) as i32) as u32;
                            }
                        }

                        0xA => {
                            self.prog_mem
                                .push(format!("b.ge({})  {}", opcode, immediate));
                            if self.N == self.V {
                                self.prog_mem.push(format!("Condition Met\n"));
                                self.prog_mem.remove(0);
                                self.program_counter =
                                    (self.program_counter as i32 + ((immediate) - 4) as i32) as u32;
                            }
                        }

                        0xB => {
                            self.prog_mem
                                .push(format!("b.lt({})  {}", opcode, immediate));
                            if self.N != self.V {
                                self.prog_mem.push(format!("Condition Met\n"));
                                self.prog_mem.remove(0);
                                self.program_counter =
                                    (self.program_counter as i32 + ((immediate) - 4) as i32) as u32;
                            }
                        }

                        0xC => {
                            self.prog_mem
                                .push(format!("b.gt({})  {}", opcode, immediate));
                            if self.Z == 0 && self.N == self.V {
                                self.prog_mem.push(format!("Condition Met\n"));
                                self.prog_mem.remove(0);
                                self.program_counter =
                                    (self.program_counter as i32 + ((immediate) - 4) as i32) as u32;
                            }
                        }

                        0xD => {
                            self.prog_mem
                                .push(format!("b.le({})  {}", opcode, immediate));
                            if !(self.Z == 0 && self.N == self.V) {
                                self.prog_mem.push(format!("Condition Met\n"));
                                self.prog_mem.remove(0);
                                self.program_counter =
                                    (self.program_counter as i32 + ((immediate) - 4) as i32) as u32;
                            }
                        }

                        0xE => {
                            self.prog_mem
                                .push(format!("b.al({})  {}", opcode, immediate));
                            self.prog_mem.push(format!("Condition Met\n"));
                            self.prog_mem.remove(0);
                            self.program_counter =
                                (self.program_counter as i32 + ((immediate) - 4) as i32) as u32;
                        }

                        0xF => {
                            self.prog_mem
                                .push(format!("b.nv({})  {}", opcode, immediate));
                            self.prog_mem.push(format!("Condition Met\n"));
                            self.prog_mem.remove(0);
                            self.program_counter =
                                (self.program_counter as i32 + ((immediate) - 4) as i32) as u32;
                        }

                        _ => {
                            self.prog_mem
                                .push(format!("Invalid Condition: {}", condition));
                        }
                    }
                    self.register[15 as usize] = self.program_counter;
                }

                0x62 =>{
                    //BR
                    self.prog_mem
                        .push(format!("BR({})   R{}  {:X}", opcode, destination, immediate));
                    self.prog_mem.push(spc.to_string());
                    self.prog_mem.push(format!("Branch Taken\n"));

                    self.program_counter =
                        (self.register[destination as usize] as i32 + ((immediate) - 4) as i32) as u32;
                    self.register[15 as usize] = self.program_counter;
                }

                0x68 => {
                    //HALT

                    self.prog_mem.push(format!("HALT({})", opcode));
                    //stop execution
                    self.stop_state = true;

                    break;
                }

                0x4 => {
                    //LSL

                    self.prog_mem
                        .push(format!("LSL({})   R{}   R{}", opcode, source, destination));
                    self.register[destination as usize] =
                        self.register[source as usize] << immediate as u32;
                }

                0x5 => {
                    //LSR

                    self.prog_mem
                        .push(format!("LSR({})   R{}   R{}", opcode, source, destination));
                    self.register[destination as usize] =
                        self.register[source as usize] >> immediate as u32;
                }

                0x2 => {
                    //CLR

                    self.prog_mem
                        .push(format!("CLR({})   {}   {}", opcode, source, destination));
                    self.register[destination as usize] = 0;
                }

                0x3 => {
                    //SET

                    self.prog_mem
                        .push(format!("SET({})  {}   {}", opcode, source, destination));
                    self.register[destination as usize] = 0b1111_1111_1111_1111_1111_1111_1111_1111;
                }
                //default case invalid opcode
                _ => {
                    self.prog_mem.push(format!("Invalid Opcode: {}", opcode));
                }
            }
            //decrement cycle count
            self.register[14 as usize]=0;
            count = count - 1;
        }
        let data: Vec<String> = self.memory.iter().map(|n| n.to_string()).collect();

        let mut rel_file = File::create("./dataoutput.csv").expect("unable to create file");
        let mut full_file = File::create("./memoutput.csv").expect("unable to create file");
        write!(rel_file, "Address,Value").unwrap();
        write!(full_file, "Address,Value").unwrap();

        let mut output_index = 0;

        for item in &data {
            if item != "0" && output_index % 4 == 0 {
                write!(
                    rel_file,
                    "\n{:#010X},{:#010X}",
                    output_index,
                    &item.parse::<u32>().unwrap()
                )
                .unwrap();

                write!(
                    full_file,
                    "\n{:#010X},{:#010X}",
                    output_index,
                    &item.parse::<u32>().unwrap()
                )
                .unwrap();
            } else if output_index % 4 == 0 {
                write!(
                    full_file,
                    "\n{:#010X},{:#010X}",
                    output_index,
                    &item.parse::<u32>().unwrap()
                )
                .unwrap();
            }
            output_index += 1;
        }
    }
}
