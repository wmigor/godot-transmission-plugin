extends Node2D

@onready var motor := $Motor as MotorView
@onready var shaft1 := $Motor/InputShaft as ShaftView
@onready var shaft2 := $Motor/InputShaft/CentralDifferential/LeftShaft as ShaftView
@onready var shaft3 := $Motor/InputShaft/CentralDifferential/RightShaft as ShaftView

var av: float
var time: float


func _physics_process(delta: float) -> void:
	var old := motor.angular_velocity
	motor.update_velocity(delta)
	_solve2x2()
	#for i in 20:
		#motor.update(delta)
	time += delta
	if old < 1 and motor.angular_velocity >= 1:
		print("shaft time: ", time)
	old = av
	av += motor.input_torque * delta
	if old < 1 and av >= 1:
		print("av time: ", time)
	
	#print(av, ' ', input_shaft.angular_velocity, ' ', 0.5 * ($InputShaft/CentralDifferential/LeftShaft.angular_velocity + $InputShaft/CentralDifferential/RightShaft.angular_velocity))
	#print(int(rad_to_deg(input_shaft.angle)), ' ', int(rad_to_deg(0.5 * $InputShaft/CentralDifferential/RightShaft.angle)))


func _solve2x2() -> void:
	var inertia_matrix := DenseMatrix.zero(4)
	inertia_matrix.set_element(0, 0, motor.inertia)
	inertia_matrix.set_element(1, 1, shaft1.inertia)
	inertia_matrix.set_element(2, 2, shaft2.inertia)
	inertia_matrix.set_element(3, 3, shaft3.inertia)

	var jacobian := DenseMatrix.from_packed_array(PackedFloat64Array([
		1.0, -motor.gear, 0.0, 0.0,
		0.0, -2.0, 1.0, 1.0
	]), 2, 4)

	var a := jacobian.multiply_dense(inertia_matrix.inverse()).multiply_dense(jacobian.transposed())
	var b := VectorN.from_packed_array([
		-(motor.angular_velocity - motor.gear * shaft1.angular_velocity),
		-(-2.0 * shaft1.angular_velocity + shaft2.angular_velocity + shaft3.angular_velocity)
	]).column_vector()
	var x := a.solve(b)
	if x != null:
		var r := x.to_packed_array()
		motor.angular_velocity += r[0] / motor.inertia
		shaft1.angular_velocity += -motor.gear * r[0] / shaft1.inertia
		shaft1.angular_velocity += -2.0 * r[1] / shaft1.inertia
		shaft2.angular_velocity += 1.0 * r[1] / shaft2.inertia
		shaft3.angular_velocity += 1.0 * r[1] / shaft3.inertia
