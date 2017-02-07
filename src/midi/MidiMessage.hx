package midi;
import haxe.io.Bytes;
import midi.MidiNote;
import midi.Status;

/**
 * @author Jonas Nyström
 */

enum MidiMessage
{
	ChannelMessage(status:Status, channel:Int, data1:Int, data2:Int);
	DataMessage (status:Status, data1:Int, data2:Int );
	EndTrackMessage;
	InvalidMessage(status:Status);
	KeySignatureMessage(accidentals:Int, minor:Bool);
	PortNumberMessage( port:UInt);
	SequenceNumberMessage(value1:UInt, value2:UInt);
	SetTempoMessage(microsecondsPerQuarter:UInt);  // , tempo:Int, bpm:Float, bps:Float
	SystemExclusiveMessage (type:UInt, data:Bytes);
	SystemMessage (type:Int, data1:Int, data2:Int );
	TextMessage(type:Int, text:String);
	TimeSignatureMessage(numerator:UInt, denominator:UInt, clocksPerBeat:UInt, thirtySecondthsPerQuarter:UInt);
	//VoiceMessage(status:Status, channel:Int, octave:Int, pitch:UInt, note:String, velocity:UInt);
	VoiceMessage(status:Status, channel:Int, pitch:UInt, velocity:UInt);
}