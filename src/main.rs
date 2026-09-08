mod game_info;

use anyhow::Result;

fn main() -> Result<()> {
    env_logger::init();

    for game_info in game_info::read_database()? {
        log::debug!("{:?}", game_info);
    }

    Ok(())
}
