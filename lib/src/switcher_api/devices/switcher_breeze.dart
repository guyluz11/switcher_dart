//  """Abstraction for switcher thermostat devices.

//     Args:
//         mode: the mode of the thermostat.
//         temperature: the current temperature in celsius.
//         target_temperature: the current target temperature in celsius.
//         fan_level: the current fan level in celsius.
//         swing: the current swing state.
//         remote_id: the id of the remote used to control this thermostat
//     """

//     mode: ThermostatMode
//     temperature: float
//     target_temperature: int
//     fan_level: ThermostatFanLevel
//     swing: ThermostatSwing
//     remote_id: str

/// Enum class representing the thermostat device's position.
enum SwitcherThermostatModeTypes {
  auto, // "01", "auto"
  dry, // "02", "dry"
  fan, // "03", "fan"
  cool, // "04", "cool"
  heat, // "05", "heat"
}

/// Enum class representing the thermostat device's fan level.
enum SwitcherThermostatFanLevel {
  low, // "1", "low"
  medium, // "2", "medium"
  high, // "3", "high"
  auto, // "0", "auto"
}

/// Enum class representing the thermostat device's swing state.
enum SwitcherThermostatSwing {
  off, // "0", "off"
  on, // "1", "on"
}

/// Enum class representing the shutter device's position.
enum SwitcherShutterDirection {
  stop, // "0000", "stop"
  up, // "0100", "up"
  down, // "0001", "down"
}
