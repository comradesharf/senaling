mod emulator;
mod game_info;
mod rom_file;

#[unsafe(no_mangle)]
pub extern "C" fn load_rom(file: &rom_file::RomFile) {
    file.size();
}
