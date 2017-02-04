package midi;

/**
 * Status
 * @author Jonas Nyström
 */
@:enum abstract Status(String) 
{
	var NOTE_OFF = 'NOTE_OFF';//				: Int =	0x80;
	var NOTE_ON	 = 'NOTE_ON';//			: Int =	0x90;
	var KEY_PRESSURE = 'KEY_PRESSURE';//			: Int =	0xA0;
	var CONTROL_CHANGE = 'CONTROL_CHANGE';//		: Int =	0xB0;
	var PROGRAM_CHANGE = 'PROGRAM_CHANGE';//		: Int =	0xC0;
	var CHANNEL_PRESSURE	 = 'CHANNEL_PRESSURE';//	: Int =	0xD0;
	var PITCH_BEND = 'PITCH_BEND';//			: Int =	0xE0;
	var SYSTEM	 = 'SYSTEM';//			: Int =	0xF0;
	var INVALID	 = 'INVALID';//			: Int =	0x00;
	
	@:from static public function fromInt(val:Int) {
		return switch val {
		case 0x80:NOTE_OFF;
		case 0x90: NOTE_ON;
		case 0xA0: KEY_PRESSURE;
		case 0xB0: CONTROL_CHANGE;
		case 0xC0: PROGRAM_CHANGE;
		case 0xD0: CHANNEL_PRESSURE;
		case 0xE0: PITCH_BEND;
		case 0xF0: SYSTEM;
		case 0x00: INVALID;
		case _: 
			throw "Unknown status: " + val;
			INVALID;			
		}		
		
	}
	
	
}