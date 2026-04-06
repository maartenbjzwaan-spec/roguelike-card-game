extends Node

## Manages seed-based randomness with separate streams for each game subsystem.
## Each stream uses its own RandomNumberGenerator so that activity in one system
## (e.g. card draws) does not affect the sequence of another (e.g. map generation).

enum Stream {
	CARD_DRAWS,
	COMBAT_REWARDS,
	ITEMS,
	ENEMY_ATTACKS,
	MAP_GENERATION,
}

var run_seed: int = 0

var _rngs: Dictionary = {}

func _ready() -> void:
	new_run()

## Starts a new run with the given seed. Pass -1 (default) to generate a random seed.
func new_run(seed_value: int = -1) -> void:
	if seed_value < 0:
		var base_rng := RandomNumberGenerator.new()
		base_rng.randomize()
		run_seed = base_rng.randi()
	else:
		run_seed = seed_value
	_init_streams()

## Initialises every stream RNG from the run seed. Each stream gets a unique
## derived seed so that their sequences are independent.
func _init_streams() -> void:
	_rngs.clear()
	for stream_id: int in Stream.values():
		var rng := RandomNumberGenerator.new()
		# Derive a per-stream seed by combining the run seed with the stream id.
		rng.seed = run_seed + stream_id * 7919  # 7919 is an arbitrary prime offset
		_rngs[stream_id] = rng

## Returns the RandomNumberGenerator for a given stream.
func get_rng(stream: Stream) -> RandomNumberGenerator:
	return _rngs[stream] as RandomNumberGenerator

## Convenience: return a random integer in [0, max_exclusive) for a stream.
func randi_range_stream(stream: Stream, max_exclusive: int) -> int:
	var rng: RandomNumberGenerator = _rngs[stream]
	return rng.randi() % max_exclusive

## Convenience: Fisher-Yates shuffle an array in-place using a specific stream.
func shuffle_array(stream: Stream, array: Array) -> void:
	var rng: RandomNumberGenerator = _rngs[stream]
	for i: int in range(array.size() - 1, 0, -1):
		var j: int = rng.randi() % (i + 1)
		var tmp: Variant = array[i]
		array[i] = array[j]
		array[j] = tmp
