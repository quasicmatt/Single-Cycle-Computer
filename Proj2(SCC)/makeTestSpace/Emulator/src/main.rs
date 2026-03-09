use serde_json::Value;
use spinners::{Spinner, Spinners};
use std::{env, fs::File, io::Read};
mod emulator;
mod ui;

pub fn main() {
    let args: Vec<String> = env::args().collect();
    let file_path = &args[1];
    let mode = &args[2];

    let config_file = "src/config.json";
    //open config file
    let mut file = File::open(config_file).unwrap();
    let mut raw_config_data = String::new();
    file.read_to_string(&mut raw_config_data).unwrap();

    let config_data: Value = serde_json::from_str(&raw_config_data).unwrap();

    let memory: u64 = config_data["memory"].as_u64().unwrap();
    let tick: u64 = config_data["tickRate"].as_u64().unwrap();

    //ui size variables
    let column_one: u64 = config_data["uiColumnOneSize"].as_u64().unwrap();
    let column_two: u64 = config_data["uiColumnTwoSize"].as_u64().unwrap();
    let column_three: u64 = config_data["uiColumnThreeSize"].as_u64().unwrap();
    let column_four: u64 = config_data["uiColumnFourSize"].as_u64().unwrap();
    let pc_block_height: u64 = config_data["uiProgramCounterHeight"].as_u64().unwrap();
    let registers_block_height: u64 = config_data["uiRegistersHeight"].as_u64().unwrap();

    //run in headless mode or pass execution to UI
    if mode == "-h" {
        print!("\n\n");
        let mut sp = Spinner::new(Spinners::SimpleDotsScrolling, "EXECUTING PROGRAM".into());
        let mut cpu = emulator::CPU::new(memory.try_into().unwrap());
        cpu.setup(file_path.to_string());
        //higher run count can result in faster execution
        while !cpu.stop_state {
            cpu.run(5);
        }
        sp.stop_with_message("DONE".into());
    } else if mode == "-b" {
        //cycles to run for
        let cycles: u32 = args[3].parse::<u32>().unwrap();
        print!("\n\n");
        let mut sp = Spinner::new(Spinners::SimpleDotsScrolling, "EXECUTING PROGRAM".into());
        let mut cpu = emulator::CPU::new(memory.try_into().unwrap());
        cpu.setup(file_path.to_string());
        //higher run count can result in faster execution
        cpu.run(cycles);
        cpu.stop_state = true;
        cpu.run(1);
        sp.stop_with_message("DONE".into());
    } else {
        //check for better way to convert u64 to u32
        ui::start(
            file_path.to_string(),
            memory.try_into().unwrap(),
            tick,
            column_one,
            column_two,
            column_three,
            column_four,
            pc_block_height,
            registers_block_height,
        )
        .unwrap();
    }
}
