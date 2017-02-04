package midi;

import haxe.io.Bytes;
import haxe.io.BytesInput;
import midi.message.*;
import midi.MIDITrack2;

using MidiFileDecoder.ByteInputTools;

class MidiFileDecoder2
{
	public function new () { }

	public function decodeBytes (midifile:Bytes) :MIDIFile2
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

		var tracks:Array<MIDITrack2> = new Array<MIDITrack2>();
		
		var trackHeader:Int;
		var trackSize:UInt;
		var trackEnd:UInt;
		var trackTime:UInt;
		//var events:Array<MIDITrackEvent>;
		
		//var xevents: Array<TrackEvent>;
		
		var event:MIDITrackEvent;
		var eventDelta:UInt;
		//var message:Message;
		var previousStatusByte:UInt = 0;

		var i:UInt = 0;
		for (i in 0...numTracks)
		{
			var events = new Array<MIDITrackEvent>();
			var xevents: Array<MIDITrackEvent> = [];
			
			var trackHeader = input.readString(4);
			if (trackHeader != "MTrk") throw "Invalid Midi track header tag at track "  + i;

			// last byte might be a null byte
			if (input.length - input.position == 0)   break;

			trackSize = input.readInt32();
			trackEnd = input.position + trackSize;
			trackTime = 0;
			while (input.position < trackEnd)
			{
				eventDelta = readVariableLengthUint(input);
				trackTime += eventDelta;
				var dataAtPosition = input.getByteAtPosition();
				if (MessageStatus.isStatus(dataAtPosition & 0xF0))
				{
					previousStatusByte = dataAtPosition;
				}
				var message:Message = decodeMessage( input, true, previousStatusByte);
				//xDecodeMessage(input, true, previousStatusByte);
				event = new MIDITrackEvent(trackTime, message);
				events.push(event);
			}
			var track = new MIDITrack2(events);
			tracks.push(cast track);
		}
		return new MIDIFile2(format, timeDivision, tracks);
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

	public function decodeMessages (input:BytesInput) :Array<Message>
	{
		var messages:Array<Message> = new Array<Message>();
		while (input.position < input.length)
		{
			messages.push(decodeMessage(input));
		}
		return messages;
	}

	public function decodeMessage ( input:BytesInput, inFile:Bool = false, previousStatusByte:UInt = 0) :Message
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

		// MIDI Realtime messages can appear ANYWHERE, even
		// between the two data bytes of a Voice message.
		// TODO: set up handling of real time messages

		switch (status)
		{
			case MessageStatus.NOTE_ON, MessageStatus.NOTE_OFF, MessageStatus.KEY_PRESSURE:
				var byte1 = input.readUnsignedByte();
				var byte2 = input.readUnsignedByte();
				var message = new VoiceMessage(status, lsb, byte1, byte2);
				return message;

			case MessageStatus.CONTROL_CHANGE, MessageStatus.PITCH_BEND:
				var byte1 = input.readUnsignedByte();
				var byte2 = input.readUnsignedByte();

				var message = new ChannelMessage(status, lsb,byte1, byte2);
				return message;

			case MessageStatus.PROGRAM_CHANGE, MessageStatus.CHANNEL_PRESSURE:
				var byte1 = input.readUnsignedByte();
				var message =  new ChannelMessage(status, lsb, byte1);
				return message;

			case MessageStatus.SYSTEM:
				var message =  createSystemMessage(lsb, input, inFile);
				return message;

			default:// not supported or some major problem
				return new InvalidMessage(status);
		}
	}
	
	
	

	function createSystemMessage (type:Int, input:BytesInput, inFile:Bool = false) :Message
	{
		switch (type)
		{
			case SystemMessageType.SONG_POSITION:
				var byte1 = input.readUnsignedByte();
				var byte2 = input.readUnsignedByte();
				return new SystemMessage(type,byte1, byte2);

			case SystemMessageType.SONG_SELECT:
				var byte1 = input.readUnsignedByte();
				return new SystemMessage(type, byte1);

			case SystemMessageType.SYSTEM_RESET:
				return inFile ? createMetaEventMessage( input) : new SystemMessage(type);

			case SystemMessageType.SYS_EX_START:
				return createSystemExclusiveMessage(type,  input);

			default:
				return new SystemMessage(type);
		}
	}

	function createMetaEventMessage (input:BytesInput) :Message
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
				return new TextMessage(type,utfBytesStr);

			case MetaEventMessageType.MIDI_PORT:
				var byte = input.readUnsignedByte();
				return new PortNumberMessage(byte);

			case MetaEventMessageType.SET_TEMPO:
				return createSetTempoMessage( input);

			case MetaEventMessageType.KEY_SIGNATURE:
				return createKeySignatureMessage( input);

			case MetaEventMessageType.TIME_SIGNATURE:
				return createTimeSignatureMessage( input);

			case MetaEventMessageType.END_OF_TRACK:
				return EndTrackMessage.END_OF_TRACK;

			case MetaEventMessageType.SEQUENCE_NUM:
				var byte1 = input.readUnsignedByte();
				var byte2 = input.readUnsignedByte();
				return new SequenceNumberMessage(byte1, byte2);

			default:
				return InvalidMessage.INVALID;
		}
	}

	function createSetTempoMessage (input:BytesInput) :Message
	{
		var a:UInt = input.readUnsignedByte();
		var b:UInt = input.readUnsignedByte();
		var c:UInt = input.readUnsignedByte();

		var micros:UInt = c | (b << 8) | (a << 16);
		return new SetTempoMessage(micros);
	}

	function createSystemExclusiveMessage (type:UInt,  input:BytesInput) :Message
	{
		throw "SystemExclusiveMessage - Not implemented";
		/*
		var len:UInt = readVariableLengthUint(data);
		var bytes:ByteArray = new ByteArray();

		// read all but the last 0xF7 into the data bytes for this SysEx
		data.readBytes(bytes, 0, len - 1);

		// gobble the trailing 0xF7
		if (data.readUnsignedByte() != 0xF7) {
			throw new InvalidFormatError("SysEx messages must be terminated by 0xF7");
		}
		return new SystemExclusiveMessage(type, bytes);
		*/
		return null;
	}

	function createKeySignatureMessage ( input:BytesInput) :Message
	{

		var numAccidentals:Int = input.readByte();
		// 0 for major, 1 for minor
		var isMinor:Bool = input.readUnsignedByte() == 1;
		return new KeySignatureMessage(numAccidentals, isMinor);
	}

	function createTimeSignatureMessage (input:BytesInput) :Message
	{
		var numerator:UInt = input.readUnsignedByte();
		var denominator:UInt = cast(Math.pow(2, input.readUnsignedByte()));// time sig denominator is represented as the power to which 2 should be raised
		var clocksPerClick:UInt = input.readUnsignedByte();
		var thirtySecondthsPerQuarter:UInt = input.readUnsignedByte();
		return new TimeSignatureMessage(numerator, denominator, clocksPerClick, thirtySecondthsPerQuarter);
	}
}

