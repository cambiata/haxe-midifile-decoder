package midi;

import haxe.io.Bytes;
import haxe.io.BytesInput;

import midi.message.MessageStatus;
import midi.message.SystemMessageType;
import midi.message.MetaEventMessageType;
using MidiFileDecoder.ByteInputTools;

class MidiFileDecoder
{
	public function new () { }

	public function decodeBytes (midifile:Bytes) :MidiFile
	{
		var input:BytesInput = new BytesInput(midifile);

		input.bigEndian = true;
		var head = input.readString(4);
		if (head != 'MThd') throw "Invalid Midi file header";
		var headerSize = input.readInt32();
		if (headerSize != 0x00000006) throw "Invalid Midi file header size";
		var format:UInt = input.readInt16();
		var numTracks:UInt = input.readInt16();
		var timeDivision:UInt = input.readInt16();

		var tracks:Array<MidiTrack> = new Array<MidiTrack>();

		var eventDelta:UInt;
		var previousStatusByte:UInt = 0;

		var i:UInt = 0;
		for (i in 0...numTracks)
		{
			//events = new Array<MIDITrackEvent>();
			var events: Array<MidiTrackEvent> = [];
			
			var trackHeader = input.readString(4);
			if (trackHeader != "MTrk") throw "Invalid Midi track header tag at track "  + i;

			// last byte might be a null byte
			if (input.length - input.position == 0)   break;

			var trackSize = input.readInt32();
			var trackEnd = input.position + trackSize;
			var trackTime = 0;
			while (input.position < trackEnd)
			{
				eventDelta = readVariableLengthUint(input);
				trackTime += eventDelta;
				var dataAtPosition = input.getByteAtPosition();
				if (midi.message.MessageStatus.isStatus(dataAtPosition & 0xF0))
				{
					previousStatusByte = dataAtPosition;
				}
				
				//var message:Message = decodeMessage( input, true, previousStatusByte);
				var message:MidiMessage =decodeMessage(input, true, previousStatusByte);
				
				var event:MidiTrackEvent = { time:trackTime, message:message };
				events.push(event);
			}
			var track = new MidiTrack(events);
			tracks.push(track);
		}
		return new MidiFile(format, timeDivision, tracks);
	}

	function readVariableLengthUint (input:BytesInput) :UInt
	{
		var temp:Array<UInt> = [];
		var byte:Int;
		do {
			byte = input.readByte();
			temp.push(byte);
		}
		while (byte & 0x80 != 0);

		var value:UInt = 0;
		var e:Int = temp.length -1;
		while (e >= 0)
		{
			var b2 = temp.shift() <<24>> 24 ; // convert to signed char Int8
			value += (b2 & 0x7F) << (7*e);
			e--;
		}
		return value;
	}

	/*
	public function decodeMessages (input:BytesInput) :Array<Message>
	{
		var messages:Array<Message> = new Array<Message>();
		while (input.position < input.length)
		{
			messages.push(decodeMessage(input));
		}
		return messages;
	}
	*/
	
	
	public function decodeMessage ( input:BytesInput, inFile:Bool = false, previousStatusByte:UInt = 0) :MidiMessage
	{
		var byte:UInt;
		var status:UInt;
		var lsb:UInt;

		// Need to use the bytes as unsigned. This can be done
		// by using ByteArray's readUnsignedByte() or by masking
		// the bits we care about: readByte() & OxFF
		byte = input.readByte() & 0xFF;
		// trace('==== XInput: ' + byte);

		// isolate the first and second 4-bits
		status = byte & 0xF0;

		// for midi running status: see http://everything2.com/user/arfarf/writeups/MIDI+running+status
		if (inFile && !MessageStatus.isStatus(status))
		{
			// back up the data stream
			input.position--;
			byte = previousStatusByte;
			status = byte & 0xF0;
		}
		// channel or system message type
		lsb = byte & 0x0F;


		switch (status)
		{
			case MessageStatus.NOTE_ON, MessageStatus.NOTE_OFF, MessageStatus.KEY_PRESSURE:
				var byte1 = input.readUnsignedByte();
				var byte2 = input.readUnsignedByte();
				
				var octave:Int = Math.floor(byte1 / 12) - 1;
				var pitch:UInt =  cast(byte1, UInt);
				var note:String = MidiNote.toString(cast( pitch % 12, MidiNote ));
				var velocity:UInt = cast(byte2, UInt);
				return MidiMessage.VoiceMessage(status, lsb, octave, pitch, note, velocity);

			case MessageStatus.CONTROL_CHANGE, MessageStatus.PITCH_BEND:
				var byte1 = input.readUnsignedByte();
				var byte2 = input.readUnsignedByte();

				return MidiMessage.ChannelMessage(status, lsb,byte1, byte2);
				
				//var message = new ChannelMessage(status, lsb,byte1, byte2);
				//return message;

			case MessageStatus.PROGRAM_CHANGE, MessageStatus.CHANNEL_PRESSURE:
				var byte1 = input.readUnsignedByte();
				
				return MidiMessage.ChannelMessage(status, lsb, byte1, 0);
				//var message =  new ChannelMessage(status, lsb, byte1);
				//return message;

			case MessageStatus.SYSTEM:
				
				var message =  createSystemMessage(lsb, input, inFile);
				
				return message;

			default:// not supported or some major problem
				return MidiMessage.InvalidMessage(status);
		}
	}	
	
	
	function createSystemMessage (type:Int, input:BytesInput, inFile:Bool = false) :MidiMessage
	{
		switch (type)
		{
			case SystemMessageType.SONG_POSITION:
				var byte1 = input.readUnsignedByte();
				var byte2 = input.readUnsignedByte();
				return MidiMessage.SystemMessage(type,byte1, byte2);
				//return new SystemMessage(type,byte1, byte2);

			case SystemMessageType.SONG_SELECT:
				var byte1 = input.readUnsignedByte();
				return MidiMessage.SystemMessage(type, byte1, 0);
				//return new SystemMessage(type, byte1);

			case SystemMessageType.SYSTEM_RESET:
				return inFile ? createMetaEventMessage( input) : MidiMessage.SystemMessage(type, 0, 0);

			case SystemMessageType.SYS_EX_START:
				return createSystemExclusiveMessage(type,  input);

			default:
				return MidiMessage.SystemMessage(type, 0, 0);
				//return new SystemMessage(type);
		}
	}	
	

	

	function createMetaEventMessage (input:BytesInput) :MidiMessage
	{
		var type:UInt = input.readUnsignedByte();
		var len:UInt = readVariableLengthUint( input);
		switch (type)
		{
			case MetaEventMessageType.TEXT,
					MetaEventMessageType.COPYRIGHT,
					MetaEventMessageType.TRACK_NAME,
					MetaEventMessageType.INSTRUMENT_NAME,
					MetaEventMessageType.LYRIC,
					MetaEventMessageType.MARKER,
					MetaEventMessageType.CUE_POINT,
					MetaEventMessageType.PROGRAM_NAME,
					MetaEventMessageType.DEVICE_NAME:

				var utfBytesStr:String = input.readString(len);
				return MidiMessage.TextMessage(type,utfBytesStr);

			case MetaEventMessageType.MIDI_PORT:
				var byte = input.readUnsignedByte();
				return MidiMessage.PortNumberMessage(byte);

			case MetaEventMessageType.SET_TEMPO:
				return createSetTempoMessage( input);

			case MetaEventMessageType.KEY_SIGNATURE:
				return createKeySignatureMessage( input);

			case MetaEventMessageType.TIME_SIGNATURE:
				return createTimeSignatureMessage( input);

			case MetaEventMessageType.END_OF_TRACK:
				return MidiMessage.EndTrackMessage;

			case MetaEventMessageType.SEQUENCE_NUM:
				var byte1 = input.readUnsignedByte();
				var byte2 = input.readUnsignedByte();
				return MidiMessage.SequenceNumberMessage(byte1, byte2);

			default:
				return MidiMessage.InvalidMessage(MessageStatus.INVALID);
		}
	}	
	


	function createSetTempoMessage (input:BytesInput) :MidiMessage
	{
		var a:UInt = input.readUnsignedByte();
		var b:UInt = input.readUnsignedByte();
		var c:UInt = input.readUnsignedByte();

		var microsecondsPerQuarter:UInt = c | (b << 8) | (a << 16);
		
				
		var tempo = Std.int(microsecondsPerQuarter / 24000);
		
		//this gives strange fractionnal dusts but haven't found a better calculus...
		//for a good result, we should round bpm then redivide by 60 for bps
		var bpm = 60000000.0 / microsecondsPerQuarter;
		var bps = (60000000.0/60.0) / microsecondsPerQuarter;
		
		return MidiMessage.SetTempoMessage(microsecondsPerQuarter, tempo, bpm, bps);
	}	

	function createSystemExclusiveMessage (type:UInt,  input:BytesInput) :MidiMessage
	{
		throw "SystemExclusiveMessage - Not implemented";
		return null;
	}	

	function createKeySignatureMessage ( input:BytesInput) :MidiMessage
	{

		var numAccidentals:Int = input.readByte();
		// 0 for major, 1 for minor
		var isMinor:Bool = input.readUnsignedByte() == 1;
		return MidiMessage.KeySignatureMessage(numAccidentals, isMinor);
	}	
	


	function createTimeSignatureMessage (input:BytesInput) :MidiMessage
	{
		var numerator:UInt = input.readUnsignedByte();
		var denominator:UInt = cast(Math.pow(2, input.readUnsignedByte()));// time sig denominator is represented as the power to which 2 should be raised
		var clocksPerClick:UInt = input.readUnsignedByte();
		var thirtySecondthsPerQuarter:UInt = input.readUnsignedByte();
		return MidiMessage.TimeSignatureMessage(numerator, denominator, clocksPerClick, thirtySecondthsPerQuarter);
	}	
	

}

class ByteInputTools
{
	static public function readUnsignedByte(input:BytesInput):UInt return input.readByte()  & 0xFF;

	static public function getByteAtPosition(input:BytesInput):Int
	{
		var dataAtPosition = input.readByte();
		input.position--;
		return dataAtPosition;
	}
}