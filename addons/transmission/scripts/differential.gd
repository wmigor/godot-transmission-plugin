@tool
@abstract
extends TransmissionComponent
class_name Differential


@abstract
func apply_torque(delta: float, torque: float) -> void

@abstract
func get_axle_inertia() -> float

@abstract
func get_axle_angular_velocity() -> float

@abstract
func get_axle_torque() -> float

@abstract
func before_simulation(delta: float, input_steering: float) -> void

@abstract
func after_simulation(delta: float, free: bool, input_brake: float, input_hand_brake: float) -> void

@abstract
func switch() -> void

@abstract
func get_type_name() -> String
