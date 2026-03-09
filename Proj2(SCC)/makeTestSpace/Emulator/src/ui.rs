use crate::emulator::{self, CPU};

use crossterm::{
    event::{self, DisableMouseCapture, EnableMouseCapture, Event, KeyCode},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use std::{
    error::Error,
    io,
    time::{Duration, Instant},
};
use tui::{
    backend::{Backend, CrosstermBackend},
    layout::{Constraint, Corner, Direction, Layout},
    style::{Color, Style},
    text::Spans,
    widgets::{Block, Borders, List, ListItem, Paragraph},
    Frame, Terminal,
};

pub fn start(
    file_path: String,
    memory_size: u32,
    tick_rate: u64,
    col_one: u64,
    col_two: u64,
    col_three: u64,
    col_four: u64,
    pc_height: u64,
    register_height: u64,
) -> Result<(), Box<dyn Error>> {
    // setup terminal
    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen, EnableMouseCapture)?;
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;

    // create app and run it
    let tick_rate = Duration::from_millis(tick_rate);
    let app = emulator::CPU::new(memory_size);
    let res = run_app(
        &mut terminal,
        app,
        tick_rate,
        file_path,
        col_one,
        col_two,
        col_three,
        col_four,
        pc_height,
        register_height,
    );

    // restore terminal
    disable_raw_mode()?;
    execute!(
        terminal.backend_mut(),
        LeaveAlternateScreen,
        DisableMouseCapture
    )?;
    terminal.show_cursor()?;

    if let Err(err) = res {
        println!("{:?}", err)
    }

    Ok(())
}

fn run_app<B: Backend>(
    terminal: &mut Terminal<B>,
    mut app: CPU,
    tick_rate: Duration,
    file_path: String,
    col_one: u64,
    col_two: u64,
    col_three: u64,
    col_four: u64,
    pc_height: u64,
    register_height: u64,
) -> io::Result<()> {
    let mut last_tick = Instant::now();
    //counter for scrolling
    let mut n = 0;
    //freerun bool
    let mut free_run = false;
    let mut regType = 0 as u8;
    //instantiates CPU
    app.setup(file_path);

    ////////////////////
    //  Main UI Loop  //
    ////////////////////

    loop {
        //draw UI
        terminal.draw(|f| {
            ui(
                f,
                &mut app,
                col_one,
                col_two,
                col_three,
                col_four,
                pc_height,
                register_height,
                regType,
            )
        })?;

        let timeout = tick_rate
            .checked_sub(last_tick.elapsed())
            .unwrap_or_else(|| Duration::from_secs(0));

        if crossterm::event::poll(timeout)? {
            //handle input events
            if let Event::Key(key) = event::read()? {
                match key.code {
                    KeyCode::Char('q') => return Ok(()),
                    //toggle freerun
                    KeyCode::Char('f') => free_run = !free_run,
                    //toggle for reg display
                    KeyCode::Char('u') => regType = 0,
                    KeyCode::Char('s') => regType = 1,
                    KeyCode::Char('h') => regType = 2,
                    

                    //step through program
                    KeyCode::Enter => {
                        if !app.stop_state {
                            app.run(1);
                            if n >= 45 {
                                app.prog_mem.remove(0);
                            }
                            n = n + 1;
                        }
                    }
                    //default case
                    _ => {}
                }
            }
        }
        //actions to run every tick
        if last_tick.elapsed() >= tick_rate {
            //run if freerun enabled
            if free_run && !app.stop_state {
                //this simulates scrolling
                if n >= 45 {
                    app.prog_mem.remove(0);
                }
                //runs the CPU for one cycle
                app.run(1);
                n = n + 1;
            }
            last_tick = Instant::now();
        }
    }
}

fn ui<B: Backend>(
    f: &mut Frame<B>,
    app: &mut CPU,
    col_one: u64,
    col_two: u64,
    col_three: u64,
    col_four: u64,
    pc_height: u64,
    register_height: u64,
    regType: u8,
) {
    //storage and changing of UI percentages should be handle better
    //u64 shouldn't be conveted to u16 here
    //create four columns for layout
    let chunks = Layout::default()
        .direction(Direction::Horizontal)
        .constraints(
            [
                Constraint::Percentage(col_one.try_into().unwrap()),
                Constraint::Percentage(col_two.try_into().unwrap()),
                Constraint::Percentage(col_three.try_into().unwrap()),
                Constraint::Percentage(col_four.try_into().unwrap()),
            ]
            .as_ref(),
        )
        .split(f.size());

    //splits column one into three chuncks
    let sub_chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints(
            [
                Constraint::Percentage(pc_height.try_into().unwrap()),
                Constraint::Percentage(register_height.try_into().unwrap()),
                Constraint::Percentage(20),
            ]
            .as_ref(),
        )
        .split(chunks[0]);

    //splits column two into two chuncks
    let sub_chunks_instr = Layout::default()
        .direction(Direction::Vertical)
        .constraints([Constraint::Percentage(96), Constraint::Percentage(4)].as_ref())
        .split(chunks[1]);

    //////////////////////////////////
    //  Code for CPU Memory widget  //
    //////////////////////////////////

    //create new list item vector for memory
    let mut items: Vec<ListItem> = Vec::new();
    //index variable
    let mut n = app.data_start;
    //iterate through cpu memory
    for e in &app.memory[app.data_start as usize..] {
        let address = app.data_start + n - app.data_start;
        //format to hex
        let hex = format!("            | {:#010X} | {:#010X} |", address, e);
        //convert hex to spans
        let lines = vec![Spans::from(hex.to_string())];
        //set text color based on index
        let mut s = Style::default();
        //last read memory address
        if n == app.last_r {
            s = Style::default().fg(Color::Green);
        }
        //last written memory address
        if n == app.last_w {
            s = Style::default().fg(Color::LightRed);
        }
        //last memory address program counter was at
        if n == app.last_pc {
            s = Style::default().fg(Color::LightYellow);
        }
        //push lines into memory display vector as list items
        items.push(ListItem::new(lines).style(s));

        n += 1;
    }

    //create new list using vector of items and add styling
    let items = List::new(items).block(Block::default().borders(Borders::ALL).title("Memory"));

    //render the list as a widget in chunck 2
    f.render_widget(items, chunks[2]);

    /////////////////////////////////
    //  Code for CPU Flags widget  //
    /////////////////////////////////

    //create vector of list items for flags
    let mut flags: Vec<ListItem> = Vec::new();

    //push flags to vector with blanck line after
    let flag = format!(" Negative Flag (N): {}", app.N.to_string());
    flags.push(ListItem::new(Spans::from(flag)).style(Style::default().fg(Color::Blue)));
    flags.push(ListItem::new(" "));

    let flag = format!(" Zero Flag (Z):     {}", app.Z.to_string());
    flags.push(ListItem::new(Spans::from(flag)).style(Style::default().fg(Color::Blue)));
    flags.push(ListItem::new(" "));

    let flag = format!(" Carry Flag (C):    {}", app.C.to_string());
    flags.push(ListItem::new(Spans::from(flag)).style(Style::default().fg(Color::Blue)));
    flags.push(ListItem::new(" "));

    let flag = format!(" Overflow Flag (V): {}", app.V.to_string());
    flags.push(ListItem::new(Spans::from(flag)).style(Style::default().fg(Color::Blue)));
    flags.push(ListItem::new(" "));

    //create flag list using flags vector
    let flag_list =
        List::new(flags).block(Block::default().borders(Borders::ALL).title("Variables"));

    //render flag widget in column one block two
    f.render_widget(flag_list, sub_chunks[2]);

    ///////////////////////////////////////
    //  Code for Program Counter widget  //
    ///////////////////////////////////////

    //create vector for program counter
    let mut variables: Vec<ListItem> = Vec::new();

    //format and style pc and push to vector
    let program_counter = format!(" Program Counter: {}", app.program_counter.to_string());
    variables.push(
        ListItem::new(Spans::from(program_counter)).style(Style::default().fg(Color::Yellow)),
    );
    variables.push(ListItem::new(" "));

    //create program counter list for rendering
    let new_list = List::new(variables)
        .block(Block::default().borders(Borders::ALL).title("PC"))
        .start_corner(Corner::TopLeft);

    //render program counter in column one chunck one
    f.render_widget(new_list, sub_chunks[0]);

    /////////////////////////////////////
    //  Code for CPU Registers widget  //
    /////////////////////////////////////

    //counter for register number
    let mut n = 0;
    //create vector for registers and iterate through
    let events: Vec<ListItem> = app
        .register
        .iter()
        .map(|i| {
            //add formatting registers
            let value;
            if regType==0{ 
                value=format!("  Register {}: {}", n, (*i as u32).to_string());
            }
            else if regType==1{ 
                value=format!("  Register {}: {}", n, (*i as i32).to_string());
            }
            else { 
                value=format!("  Register {}: 0x{:X}", n, *i );
            }
            let lines = vec![Spans::from(value)];
            n = n + 1;

            //push registers to vector
            ListItem::new(lines).style(Style::default().fg(Color::White))
        })
        .collect();
    
    //create list for register widget
    let reg_title;
    if regType == 0 {
        reg_title = "Registers (unsigned)";
    } else if regType == 1 {
        reg_title = "Registers (signed)";
    } else {
        reg_title = "Registers (hex)";
    }
    let events_list = 
        List::new(events).block(Block::default().borders(Borders::ALL).title(reg_title));
    
    //render register widget in column one row two
    f.render_widget(events_list, sub_chunks[1]);

    ////////////////////////////////////
    //  Code for instructions widget  //
    ////////////////////////////////////

    //create vector of list items for instructions
    let mut instr: Vec<ListItem> = Vec::new();

    //iterate through program memory
    for e in &app.prog_mem {
        let lines = vec![Spans::from("            ".to_owned() + &e.to_string())];
        let mut s = Style::default();
        //set text color based on instruction
        if e.contains("Branch Taken") {
            s = Style::default().fg(Color::Blue);
        } else if e.contains("b") || e.contains("B") {
            s = Style::default().fg(Color::LightYellow);
        } else if e.contains("HALT") {
            s = Style::default().fg(Color::Red);
        } else if e.contains("LOAD") {
            s = Style::default().fg(Color::Green);
        } else if e.contains("STOR") {
            s = Style::default().fg(Color::LightRed);
        } else if e.contains("Condition Met") {
            s = Style::default().fg(Color::Blue);
        }
        //push instructions to instruction vector
        instr.push(ListItem::new(lines).style(s));
    }

    //create instruction list from instruction vector
    let instr_list =
        List::new(instr).block(Block::default().borders(Borders::ALL).title("Instructions"));

    //render the instruction list in column 2
    f.render_widget(instr_list, sub_chunks_instr[0]);

    ///////////////////////////////////
    //  Code for Memory File widget  //
    ///////////////////////////////////

    //ceate vector for raw memory file
    let mut raw_mem: Vec<ListItem> = Vec::new();

    raw_mem.push(ListItem::new(" "));

    //iterate through raw mem vector
    for e in &app.raw_mem {
        let lines = vec![Spans::from("  ".to_owned() + &e.to_string())];

        //text color yellow when line starts with '@'
        let s = match e.starts_with('@') {
            true => Style::default().fg(Color::Yellow),
            false => Style::default().fg(Color::White),
        };
        raw_mem.push(ListItem::new(lines).style(s));
    }

    //create memory list for widget
    let mem_list =
        List::new(raw_mem).block(Block::default().borders(Borders::ALL).title("Mem File"));

    //render raw memory widget
    f.render_widget(mem_list, chunks[3]);

    //////////////////////////////////
    //  Current Instruction Widget  //
    //////////////////////////////////

    // create new paragraph for current instruction widget based on last PC
    let curr_instr = Paragraph::new(format!(
        "Hex: {:#X}   Binary : {:b}",
        app.memory[app.program_counter as usize], app.memory[app.program_counter as usize]
    ))
    .block(Block::default().borders(Borders::ALL).title("Instruction"));

    //render current instruction widget in column two row two
    f.render_widget(curr_instr, sub_chunks_instr[1]);
}
