use csv::StringRecord;

const DB_FILE: &[u8] = include_bytes!("./MesenNesDB.txt");

fn main() -> Result<(), Box<dyn std::error::Error>> {
    env_logger::init();

    let mut reader = csv::ReaderBuilder::new()
        .has_headers(false)
        .comment(Some(b'#'))
        .trim(csv::Trim::Fields)
        .from_reader(DB_FILE);

    for record in reader.records() {
        let game_info: GameInfo = (&record?).into();
        log::info!("Parsed game info: {:?}", game_info);
    }

    Ok(())
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[derive(Default)]
pub enum NesMirroring {
    Horizontal,  // h
    Vertical,    // v
    ScreenAOnly, // 0
    ScreenBOnly, // 1
    FourScreens, // 4
    #[default]
    Unspecified,
}

impl From<&str> for NesMirroring {
    fn from(value: &str) -> Self {
        match value {
            "h" => Self::Horizontal,
            "v" => Self::Vertical,
            "0" => Self::ScreenAOnly,
            "1" => Self::ScreenBOnly,
            "4" => Self::FourScreens,
            _ => {
                log::debug!("Unknown mirroring type: {}", value);
                Self::default()
            }
        }
    }
}


#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(u8)]
#[derive(Default)]
pub enum NesInputType {
    #[default]
    Unspecified = 0,
    StandardControllers = 1,
    FourScore = 2,
    FourPlayerAdapter = 3,
    VsSystem = 4,
    VsSystemSwapped = 5,
    VsSystemSwapAb = 6,
    VsZapper = 7,
    Zapper = 8,
    TwoZappers = 9,
    BandaiHypershot = 10,
    PowerPadSideA = 11,
    PowerPadSideB = 12,
    FamilyTrainerSideA = 13,
    FamilyTrainerSideB = 14,
    ArkanoidControllerNes = 15,
    ArkanoidControllerFamicom = 16,
    DoubleArkanoidController = 17,
    KonamiHyperShot = 18,
    PachinkoController = 19,
    ExcitingBoxing = 20,
    JissenMahjong = 21,
    PartyTap = 22,
    OekaKidsTablet = 23,
    BarcodeBattler = 24,
    MiraclePiano = 25,
    PokkunMoguraa = 26,
    TopRider = 27,
    DoubleFisted = 28,
    Famicom3dSystem = 29,
    DoremikkoKeyboard = 30,
    Rob = 31,
    FamicomDataRecorder = 32,
    TurboFile = 33,
    BattleBox = 34,
    FamilyBasicKeyboard = 35,
    Pec586Keyboard = 36,
    Bit79Keyboard = 37,
    SuborKeyboard = 38,
    SuborKeyboardMouse1 = 39,
    SuborKeyboardMouse2 = 40,
    SnesMouse = 41,
    GenericMulticart = 42,
    SnesControllers = 43,
    RacermateBicycle = 44,
    UForce = 45,
    RobStackUp = 46,
    CityPatrolmanLightgun = 47,
    SharpC1CassetteInterface = 48,
    StandardControllerSwappedButtons = 49,
    ExcaliburSudokuPad = 50,
    AblPinball = 51,
    GoldenNuggetCasino = 52,
    KedaKeyboard = 53,
    SuborKeyboardMouse3 = 54,
    PortTestController = 55,
    BandaiMultiGamePlayer = 56,
    VenomTvDance = 57,
    LgTvRemote = 58,
    FcnsController = 59,
}

impl From<&str> for NesInputType {
    fn from(value: &str) -> Self {
        match value.parse::<u8>().ok() {
            Some(0) => Self::Unspecified,
            Some(1) => Self::StandardControllers,
            Some(2) => Self::FourScore,
            Some(3) => Self::FourPlayerAdapter,
            Some(4) => Self::VsSystem,
            Some(5) => Self::VsSystemSwapped,
            Some(6) => Self::VsSystemSwapAb,
            Some(7) => Self::VsZapper,
            Some(8) => Self::Zapper,
            Some(9) => Self::TwoZappers,
            Some(10) => Self::BandaiHypershot,
            Some(11) => Self::PowerPadSideA,
            Some(12) => Self::PowerPadSideB,
            Some(13) => Self::FamilyTrainerSideA,
            Some(14) => Self::FamilyTrainerSideB,
            Some(15) => Self::ArkanoidControllerNes,
            Some(16) => Self::ArkanoidControllerFamicom,
            Some(17) => Self::DoubleArkanoidController,
            Some(18) => Self::KonamiHyperShot,
            Some(19) => Self::PachinkoController,
            Some(20) => Self::ExcitingBoxing,
            Some(21) => Self::JissenMahjong,
            Some(22) => Self::PartyTap,
            Some(23) => Self::OekaKidsTablet,
            Some(24) => Self::BarcodeBattler,
            Some(25) => Self::MiraclePiano,
            Some(26) => Self::PokkunMoguraa,
            Some(27) => Self::TopRider,
            Some(28) => Self::DoubleFisted,
            Some(29) => Self::Famicom3dSystem,
            Some(30) => Self::DoremikkoKeyboard,
            Some(31) => Self::Rob,
            Some(32) => Self::FamicomDataRecorder,
            Some(33) => Self::TurboFile,
            Some(34) => Self::BattleBox,
            Some(35) => Self::FamilyBasicKeyboard,
            Some(36) => Self::Pec586Keyboard,
            Some(37) => Self::Bit79Keyboard,
            Some(38) => Self::SuborKeyboard,
            Some(39) => Self::SuborKeyboardMouse1,
            Some(40) => Self::SuborKeyboardMouse2,
            Some(41) => Self::SnesMouse,
            Some(42) => Self::GenericMulticart,
            Some(43) => Self::SnesControllers,
            Some(44) => Self::RacermateBicycle,
            Some(45) => Self::UForce,
            Some(46) => Self::RobStackUp,
            Some(47) => Self::CityPatrolmanLightgun,
            Some(48) => Self::SharpC1CassetteInterface,
            Some(49) => Self::StandardControllerSwappedButtons,
            Some(50) => Self::ExcaliburSudokuPad,
            Some(51) => Self::AblPinball,
            Some(52) => Self::GoldenNuggetCasino,
            Some(53) => Self::KedaKeyboard,
            Some(54) => Self::SuborKeyboardMouse3,
            Some(55) => Self::PortTestController,
            Some(56) => Self::BandaiMultiGamePlayer,
            Some(57) => Self::VenomTvDance,
            Some(58) => Self::LgTvRemote,
            Some(59) => Self::FcnsController,
            _ => {
                log::debug!("Unknown input type: {}", value);
                Self::default()
            }
        }
    }
}


#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[derive(Default)]
pub enum GameSystem {
    NesNtsc,
    NesPal,
    Famicom,
    Dendy,
    VsSystem,
    Playchoice,
    Fds,
    FamicomNetworkSystem,
    FamicloneDecimal,
    Um6578,
    Vt01RedCyan,
    Vt02,
    Vt03,
    Vt09,
    Vt32,
    Vt369,
    #[default]
    Unknown,
}


impl From<&str> for GameSystem {
    fn from(value: &str) -> Self {
        match value {
            "Dendy" => Self::Dendy,
            "FamicloneDecimal" => Self::FamicloneDecimal,
            "Famicom" => Self::Famicom,
            "NesNtsc" => Self::NesNtsc,
            "NesPal" => Self::NesPal,
            "Playchoice" => Self::Playchoice,
            "UM6578" => Self::Um6578,
            "VT01RedCyan" => Self::Vt01RedCyan,
            "VT02" => Self::Vt02,
            "VT03" => Self::Vt03,
            "VT09" => Self::Vt09,
            "VT32" => Self::Vt32,
            "VT369" => Self::Vt369,
            "VsSystem" => Self::VsSystem,
            _ => {
                log::debug!("Unknown system type: {}", value);
                Self::default()
            }
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(u8)]
#[derive(Default)]
pub enum VsSystemType {
    #[default]
    Default = 0,
    RbiBaseballProtection = 1,
    TkoBoxingProtection = 2,
    SuperXeviousProtection = 3,
    IceClimberProtection = 4,
    VsDualSystem = 5,
    RaidOnBungelingBayProtection = 6,
}


impl From<&str> for VsSystemType {
    fn from(value: &str) -> Self {
        match value.parse::<u8>().ok() {
            Some(0) => Self::Default,
            Some(1) => Self::RbiBaseballProtection,
            Some(2) => Self::TkoBoxingProtection,
            Some(3) => Self::SuperXeviousProtection,
            Some(4) => Self::IceClimberProtection,
            Some(5) => Self::VsDualSystem,
            Some(6) => Self::RaidOnBungelingBayProtection,
            _ => {
                log::debug!("Unknown VS system type: {}", value);
                Self::default()
            }
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(u8)]
#[derive(Default)]
pub enum PpuModel {
    #[default]
    Ppu2C02 = 0,
    Ppu2C03 = 1,
    Ppu2C04A = 2,
    Ppu2C04B = 3,
    Ppu2C04C = 4,
    Ppu2C04D = 5,
    Ppu2C05A = 6,
    Ppu2C05B = 7,
    Ppu2C05C = 8,
    Ppu2C05D = 9,
    Ppu2C05E = 10,
}


impl From<&str> for PpuModel {
    fn from(value: &str) -> Self {
        match value.parse::<u8>().ok() {
            Some(0) => Self::Ppu2C02,
            Some(1) => Self::Ppu2C03,
            Some(2) => Self::Ppu2C04A,
            Some(3) => Self::Ppu2C04B,
            Some(4) => Self::Ppu2C04C,
            Some(5) => Self::Ppu2C04D,
            Some(6) => Self::Ppu2C05A,
            Some(7) => Self::Ppu2C05B,
            Some(8) => Self::Ppu2C05C,
            Some(9) => Self::Ppu2C05D,
            Some(10) => Self::Ppu2C05E,
            _ => {
                log::debug!("Unknown VS PPU model: {}", value);
                Self::default()
            }
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[derive(Default)]
pub enum BusConflict {
    Yes,
    No,
    #[default]
    Unspecified,
}


impl From<&str> for BusConflict {
    fn from(value: &str) -> Self {
        match value {
            "Y" => Self::Yes,
            "N" => Self::No,
            _ => {
                log::debug!("Unknown bus conflict: {}", value);
                Self::Unspecified
            }
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
struct GameInfo {
    crc: u32,
    system: GameSystem,
    board: Option<String>,
    pcb: Option<String>,
    chip: Option<String>,
    mapper_id: Option<u16>,
    prg_rom_size: u32,
    chr_rom_size: Option<u32>,
    chr_ram_size: Option<u32>,
    work_ram_size: u32,
    save_ram_size: u32,
    has_battery: bool,
    mirroring: NesMirroring,
    input_type: NesInputType,
    bus_conflict: BusConflict,
    submapper_id: Option<String>,
    vs_system_type: VsSystemType,
    ppu_model: PpuModel,
}

impl From<&StringRecord> for GameInfo {
    fn from(line: &StringRecord) -> Self {
        log::debug!("Parsing line: {:?}", line);
        GameInfo {
            crc: line
                .get(0)
                .filter(|s| !s.is_empty())
                .and_then(|s| u32::from_str_radix(s, 16).ok())
                .expect("Missing CRC"),
            system: line
                .get(1)
                .filter(|s| !s.is_empty())
                .map(|value| value.into())
                .expect("Missing System"),
            board: line.get(2).filter(|s| !s.is_empty()).map(str::to_owned),
            pcb: line.get(3).filter(|s| !s.is_empty()).map(str::to_owned),
            chip: line.get(4).filter(|s| !s.is_empty()).map(str::to_owned),
            mapper_id: line
                .get(5)
                .filter(|s| !s.is_empty())
                .and_then(|s| s.parse::<u16>().ok()),
            prg_rom_size: line
                .get(6)
                .filter(|s| !s.is_empty())
                .and_then(to_size)
                .expect("Missing PRG ROM Size"),
            chr_rom_size: line.get(7).filter(|s| !s.is_empty()).and_then(to_size),
            chr_ram_size: line.get(8).filter(|s| !s.is_empty()).and_then(to_size),
            work_ram_size: line
                .get(9)
                .filter(|s| !s.is_empty())
                .and_then(to_size)
                .expect("Missing Work RAM Size"),
            save_ram_size: line
                .get(10)
                .filter(|s| !s.is_empty())
                .and_then(to_size)
                .expect("Missing Save RAM Size"),
            has_battery: line
                .get(11)
                .filter(|s| !s.is_empty())
                .is_some_and(|s| s == "1"),
            mirroring: line
                .get(12)
                .map(|value| value.into())
                .expect("Missing Mirroring"),
            input_type: line
                .get(13)
                .map(|value| value.into())
                .expect("Missing Input Type"),
            bus_conflict: line
                .get(14)
                .map(|value| value.into())
                .expect("Missing Bus Conflict"),
            submapper_id: line.get(15).filter(|s| !s.is_empty()).map(str::to_owned),
            vs_system_type: line
                .get(16)
                .map(|value| value.into())
                .expect("Missing VS System Type"),
            ppu_model: line
                .get(17)
                .map(|value| value.into())
                .expect("Missing VS PPU Model"),
        }
    }
}

/**
 * Converts a string value to a size in bytes.
 * If the value starts with 'b', it is treated as bytes.
 * Otherwise, it is treated as kilobytes and converted to bytes.
 */
fn to_size(value: &str) -> Option<u32> {
    if value.is_empty() {
        return None;
    }
    if value.starts_with("b") {
        return value.strip_prefix("b").and_then(|v| v.parse::<u32>().ok())
    }
    value.parse::<u32>().ok().map(|v| v * 1024)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_to_size() {
        assert_eq!(to_size("b1024"), Some(1024));
        assert_eq!(to_size("2048"), Some(2048 * 1024));
    }

    #[test]
    fn test_ppu_model() {
        assert_eq!(PpuModel::from("0"), PpuModel::Ppu2C02);
        assert_eq!(PpuModel::from("2"), PpuModel::Ppu2C04A);
        assert_eq!(PpuModel::from("10"), PpuModel::Ppu2C05E);
        assert_eq!(PpuModel::from("unknown"), PpuModel::Ppu2C02);
    }

    #[test]
    fn test_nes_mirroring() {
        assert_eq!(NesMirroring::from("h"), NesMirroring::Horizontal);
        assert_eq!(NesMirroring::from("v"), NesMirroring::Vertical);
        assert_eq!(NesMirroring::from("0"), NesMirroring::ScreenAOnly);
        assert_eq!(NesMirroring::from("1"), NesMirroring::ScreenBOnly);
        assert_eq!(NesMirroring::from("4"), NesMirroring::FourScreens);
        assert_eq!(NesMirroring::from("unknown"), NesMirroring::Unspecified);
    }

    #[test]
    fn test_nes_input_type() {
        assert_eq!(NesInputType::from("0"), NesInputType::Unspecified);
        assert_eq!(NesInputType::from("1"), NesInputType::StandardControllers);
        assert_eq!(NesInputType::from("59"), NesInputType::FcnsController);
        assert_eq!(NesInputType::from("60"), NesInputType::Unspecified);
        assert_eq!(NesInputType::from("unknown"), NesInputType::Unspecified);
    }

    #[test]
    fn test_game_system() {
        assert_eq!(GameSystem::from("NesNtsc"), GameSystem::NesNtsc);
        assert_eq!(GameSystem::from("Famicom"), GameSystem::Famicom);
        assert_eq!(GameSystem::from("VT369"), GameSystem::Vt369);
        assert_eq!(GameSystem::from("unknown"), GameSystem::Unknown);
    }

    #[test]
    fn test_vs_system_type() {
        assert_eq!(VsSystemType::from("0"), VsSystemType::Default);
        assert_eq!(VsSystemType::from("5"), VsSystemType::VsDualSystem);
        assert_eq!(
            VsSystemType::from("6"),
            VsSystemType::RaidOnBungelingBayProtection
        );
        assert_eq!(VsSystemType::from("7"), VsSystemType::Default);
        assert_eq!(VsSystemType::from("unknown"), VsSystemType::Default);
    }

    #[test]
    fn test_bus_conflict() {
        assert_eq!(BusConflict::from("Y"), BusConflict::Yes);
        assert_eq!(BusConflict::from("N"), BusConflict::No);
        assert_eq!(BusConflict::from("unknown"), BusConflict::Unspecified);
    }

    #[test]
    fn test_game_info_from_record() {
        let record = StringRecord::from(vec![
            "1A2B3C4D",
            "Famicom",
            "HVC-TLROM",
            "HVC-TLROM-01",
            "MMC3C",
            "42",
            "128",
            "b2048",
            "8",
            "16",
            "b4096",
            "1",
            "v",
            "59",
            "Y",
            "submapper",
            "5",
            "10",
        ]);

        let game_info = GameInfo::from(&record);

        assert_eq!(
            game_info,
            GameInfo {
                crc: 0x1A2B3C4D,
                system: GameSystem::Famicom,
                board: Some("HVC-TLROM".to_owned()),
                pcb: Some("HVC-TLROM-01".to_owned()),
                chip: Some("MMC3C".to_owned()),
                mapper_id: Some(42),
                prg_rom_size: 128 * 1024,
                chr_rom_size: Some(2048),
                chr_ram_size: Some(8 * 1024),
                work_ram_size: 16 * 1024,
                save_ram_size: 4096,
                has_battery: true,
                mirroring: NesMirroring::Vertical,
                input_type: NesInputType::FcnsController,
                bus_conflict: BusConflict::Yes,
                submapper_id: Some("submapper".to_owned()),
                vs_system_type: VsSystemType::VsDualSystem,
                ppu_model: PpuModel::Ppu2C05E,
            }
        );
    }
}
