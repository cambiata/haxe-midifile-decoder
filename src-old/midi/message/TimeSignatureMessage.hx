package midi.message;

import midi.message.Message;
import midi.message.MetaEventMessage;
import midi.message.MetaEventMessageType;

class TimeSignatureMessage extends MetaEventMessage {
	
	var numerator(default, null):UInt;
	var denominator(default, null):UInt;
	
	var clocksPerBeat(default, null):UInt;
	var thirtySecondthsPerQuarter(default, null):UInt;
	
	public function new (numerator:UInt, denominator:UInt, clocksPerBeat:UInt, thirtySecondthsPerQuarter:UInt) {
		super(MetaEventMessageType.TIME_SIGNATURE);
		
		this.numerator = numerator;
		this.denominator = denominator;
		this.clocksPerBeat = clocksPerBeat;
		this.thirtySecondthsPerQuarter = thirtySecondthsPerQuarter;
	}
	
	override public function toString () :String {
		return "[TimeSignatureMessage(numerator=" + numerator + " denominator=" + denominator + " clocksPerBeat=" + clocksPerBeat + " thirtySecondthsPerQuarter=" + thirtySecondthsPerQuarter + ")]";
	}
}
