package midi;

/**
 * Decoder2
 * @author Jonas Nyström
 */

import midi.MIDIFile;
import cx.MathTools;
import haxe.crypto.Base64;
import haxe.crypto.BaseCode;
import haxe.io.Bytes;
import haxe.io.BytesData;
import haxe.io.BytesInput;
import haxe.io.Input;
import haxe.io.Output;
import sys.io.File;
import sys.io.FileInput;
import sys.io.FileOutput;


//import com.newgonzo.midi.errors.InvalidFormatError;
import midi.MIDIFile;
import midi.MIDITrack;
import midi.message.MIDITrackEvent;
import midi.message.EndTrackMessage;
import midi.message.KeySignatureMessage;
import midi.message.MetaEventMessageType;
import midi.message.PortNumberMessage;
import midi.message.SequenceNumberMessage;
import midi.message.SetTempoMessage;
import midi.message.TextMessage;
import midi.message.TimeSignatureMessage;
import midi.message.ChannelMessage;
import midi.message.InvalidMessage;
import midi.message.Message;
import midi.message.MessageStatus;
import midi.message.SystemExclusiveMessage;
import midi.message.SystemMessage;
import midi.message.SystemMessageType;
import midi.message.VoiceMessage;

import flash.utils.ByteArray;
using MidiFileDecoder.ByteInputTools;
 
 


class Decoder2  {
	
	public static var MIDI_FILE_HEADER_TAG:UInt = 0x4D546864; // MThd
	public static var MIDI_FILE_HEADER_SIZE:UInt = 0x00000006;
	public static var MIDI_TRACK_HEADER_TAG:UInt = 0x4D54726B; // MTrk
	
	public function new () { }	
	
	function testPos(input:BytesInput, data:ByteArray) if (input.position != data.position) {
		throw ('POSITION ERROR: ' + input.position + '/ ' + data.position);
	}
	
	public function decodeFile (data:ByteArray, input:BytesInput) :MIDIFile {
		
		//var inputPos:InputPosition = 0;
		
		
		
		
		
		data.endian = flash.utils.Endian.BIG_ENDIAN;
		input.bigEndian = true;
		//-----------------------------------------------------
		var head = input.readInt32();
		if (head != cast(MIDI_FILE_HEADER_TAG)) {
			throw new InvalidFormatError("Invalid MIDI header tag: expected 0x4D546864 (MThd) vs :"+	head);
		}		
		var head = data.readInt();
		if (head != cast(MIDI_FILE_HEADER_TAG)) {
			throw new InvalidFormatError("Invalid MIDI header tag: expected 0x4D546864 (MThd) vs :"+	head);
		}		
		testPos(input, data);
		
		//-----------------------------------------------------
		
		if (data.readInt() != cast(MIDI_FILE_HEADER_SIZE)) {
			throw new InvalidFormatError("Invalid MIDI header size: expected 0x00000006");
		}
		
		if (input.readInt32() != cast(MIDI_FILE_HEADER_SIZE)) {
			throw new InvalidFormatError("Invalid MIDI header size: expected 0x00000006");
		}
		 testPos(input, data);
		
		
		//-----------------------------------------------------
		
		
		var format:UInt = input.readInt16();
		var numTracks:UInt = input.readInt16();
		var timeDivision:UInt = input.readInt16();
		// // trace( [format, numTracks, timeDivision]);
		
		var format:UInt = data.readShort();
		var numTracks:UInt = data.readShort();
		var timeDivision:UInt = data.readShort();
		// // trace( [format, numTracks, timeDivision]);
		

		testPos(input, data);		

		
		//-------------------------------------------------------------------------------------------------------------
		
		var tracks:Array<MIDITrack> = new Array<MIDITrack>();
		var track:MIDITrack;
		var trackHeader:Int;
		var trackSize:UInt;
		var trackEnd:UInt;
		var trackTime:UInt;
		
		var events:Array<MIDITrackEvent>;
		var events2:Array<MIDITrackEvent>;
		
		var event:MIDITrackEvent;
		var eventDelta:UInt;
		
		var messageBytes:ByteArray;
		var message:Message;
		
		// for midi running status
		var previousStatusByte:UInt = 0;
		
		// decode tracks
		var i:UInt = 0;
		
		for (i in 0...numTracks) {
			events = new Array<MIDITrackEvent>();
			events2 = new Array<MIDITrackEvent>();
			

			//------------------------------------------------------------------------
			
			trackHeader = input.readInt32();
			//var trackHeaderStr = input.readString(4);
			//trackHeader = Bytes.ofString(trackHeaderStr);
			
			
			//// // trace(StringTools.hex(trackHeader));
			//// trace(trackHeaderStr + ' ' + 'MTrk');
			/*
			if (trackHeader != cast(MIDI_TRACK_HEADER_TAG)) {
				throw new InvalidFormatError("Invalid MIDI track header tag at track "  + i + ": expected 0x4D54726B (MTrk)");
			}	
			*/
			
			trackHeader = data.readInt();
			// trace(trackHeader);
			//// trace(StringTools.hex(trackHeader));
			if (trackHeader != cast(MIDI_TRACK_HEADER_TAG)) {
				throw new InvalidFormatError("Invalid MIDI track header tag at track "  + i + ": expected 0x4D54726B (MTrk)");
			}			
			
			 testPos(input, data);		
			
			//------------------------------------------------------------------------
			// TODO
			// last byte might be a null byte
			//if (input.
			if (data.bytesAvailable == 0)	break;
			
			
			//------------------------------------------------------------------------
			trackSize = input.readInt32();
			// trace(trackSize);
			
			trackSize = data.readInt();
			// trace(trackSize);
			
			testPos(input, data);
			
			
			var dataPosition = data.position;
			// trace(dataPosition);
			testPos(input, data);
			
			trackEnd = input.position + trackSize;
			// trace(trackEnd);
			trackEnd = data.position + trackSize;
			// trace(trackEnd);
			
			//---------------------------------------------------------------------------
			
			
			trackTime = 0;			
			while (cast(data.position) < trackEnd) {
				eventDelta = readVariableLengthUint(data, input);
				
				trackTime += eventDelta;
				
				//var dataAtPosition = input.readByte();
				//input.position--;
				
				var dataAtPosition = input.getByteAtPosition();
				// trace('>>> input: ' + dataAtPosition);

				if (MessageStatus.isStatus(dataAtPosition & 0xF0)) {
					previousStatusByte = data[data.position];
					// trace('previousStatusByte  ' + previousStatusByte );
				}
				
				var dataAtPosition = data[data.position];
				// trace('>>> data: ' + dataAtPosition);
				testPos(input, data);

				if (MessageStatus.isStatus(dataAtPosition & 0xF0)) {
					previousStatusByte = data[data.position];
					// trace('previousStatusByte  ' + previousStatusByte );
				}
				
				/*
				if (MessageStatus.isStatus(data[data.position] & 0xF0)) {
					previousStatusByte = data[data.position];
				}
				*/
				
				
				message = decodeMessage(data, input, true, previousStatusByte);
				
				event = new MIDITrackEvent(trackTime, message);
				events.push(event);
			}
			
			
			
			
			
			
			
			track = new MIDITrack(events);
			tracks.push(track);
		}
		
		return new MIDIFile(format, timeDivision, tracks);
	}
	
			function readVariableLengthUint (data:ByteArray, input:BytesInput) :UInt {
				var temp:ByteArray = new ByteArray();
				var byte:Int;
				// trace('----------------------------------------------------------------------');
				do {
					if (input != null) {
						byte = input.readByte();
						// trace('input:' + StringTools.hex(byte));						
					}
					
					byte = data.readByte();
					// trace('byte:' + StringTools.hex(byte));
					temp.writeByte(byte);
					if (input != null) testPos(input, data);
					
					
				} while (byte & 0x80 != 0);				
				// trace('lenght: ' + temp.length);
				
				var value:UInt = 0;
				var e:Int = temp.length - 1;				
				temp.position = 0;
				
				while (e >= 0) {
					value += (temp.readByte() & 0x7F) << (7*e);
					e--;
				}
				// trace('value: ' + value);
				
			
				
				
				
				return value;
			}		
	
	
	public function decodeMessages (data:ByteArray, input:BytesInput) :Array<Message> {
		var messages:Array<Message> = new Array<Message>();
		while (data.bytesAvailable > 0) {
			messages.push(decodeMessage(data, input));
		}
		return messages;
	}
	
	public function decodeMessage (data:ByteArray, input:BytesInput, inFile:Bool = false, previousStatusByte:UInt = 0) :Message {
		var byte:UInt;
		var status:UInt;
		var lsb:UInt;
		
		// Need to use the bytes as unsigned. This can be done
		// by using ByteArray's readUnsignedByte() or by masking
		// the bits we care about: readByte() & OxFF
		byte = input.readByte() & 0xFF;
		// trace('==== XInput: ' + byte);
		
		byte = data.readUnsignedByte();
		// trace('===== XData: ' + byte);
		testPos(input, data);
		
		// isolate the first and second 4-bits
		status = byte & 0xF0;
		
		// for midi running status: see http://everything2.com/user/arfarf/writeups/MIDI+running+status
		if (inFile && !MessageStatus.isStatus(status)) {
			// back up the data stream
			data.position--;
			input.position--;
			
			byte = previousStatusByte;
			status = byte & 0xF0;
		}
		testPos(input, data);
		// channel or system message type
		lsb = byte & 0x0F;
		
		// MIDI Realtime messages can appear ANYWHERE, even
		// between the two data bytes of a Voice message.
		// TODO: set up handling of real time messages
		
		switch (status) {
			case MessageStatus.NOTE_ON, MessageStatus.NOTE_OFF, MessageStatus.KEY_PRESSURE:
				
				// trace('case MessageStatus.NOTE_ON, MessageStatus.NOTE_OFF, MessageStatus.KEY_PRESSURE:');
			//return new VoiceMessage(status, lsb, data.readUnsignedByte(), data.readUnsignedByte());
				var byte1 = input.readUnsignedByte();
				// trace(byte1);
				var byte1 = data.readUnsignedByte();
				// trace(byte1);
				testPos(input, data);
				var byte2 = input.readUnsignedByte();
				// trace(byte2);				
				var byte2 = data.readUnsignedByte();
				// trace(byte2);
				testPos(input, data);
				
				var message = new VoiceMessage(status, lsb, byte1, byte2);
				
				
				return message;
				
				
			case MessageStatus.CONTROL_CHANGE, MessageStatus.PITCH_BEND:
				// trace('case MessageStatus.CONTROL_CHANGE, MessageStatus.PITCH_BEND:');
				
				var byte1 = input.readUnsignedByte();
				// trace(byte1);
				var byte1 = data.readUnsignedByte();
				// trace(byte1);
				testPos(input, data);
				var byte2 = input.readUnsignedByte();
				// trace(byte2);				
				var byte2 = data.readUnsignedByte();
				// trace(byte2);
				testPos(input, data);				
				
				
				var message = new ChannelMessage(status, lsb,byte1, byte2);
				return message;
			
			case MessageStatus.PROGRAM_CHANGE, MessageStatus.CHANNEL_PRESSURE:
				// trace('case MessageStatus.PROGRAM_CHANGE, MessageStatus.CHANNEL_PRESSURE:');
				
				var byte1 = input.readUnsignedByte();
				// trace(byte1);
				var byte1 = data.readUnsignedByte();
				// trace(byte1);
				testPos(input, data);				
				
				
				var message =  new ChannelMessage(status, lsb, byte1);
				return message;
				
			case MessageStatus.SYSTEM:
				// trace('case MessageStatus.SYSTEM:');
				var message =  createSystemMessage(lsb, data, input, inFile);
				return message;
				
			default:// not supported or some major problem
				// trace('return new InvalidMessage(status);');
				return new InvalidMessage(status);
		}
	}
	
	function createSystemMessage (type:Int, data:ByteArray, input:BytesInput, inFile:Bool = false) :Message {
		switch (type) {
			case SystemMessageType.SONG_POSITION:
				// trace('--  case SystemMessageType.SONG_POSITION:  ');
				var byte1 = input.readUnsignedByte();
				// trace(byte1);
				var byte1 = data.readUnsignedByte();
				// trace(byte1);
				testPos(input, data);
				var byte2 = input.readUnsignedByte();
				// trace(byte2);				
				var byte2 = data.readUnsignedByte();
				// trace(byte2);
				testPos(input, data);					
				
				
				return new SystemMessage(type,byte1, byte2);
			
			case SystemMessageType.SONG_SELECT:
				// trace('-- case SystemMessageType.SONG_SELECT:  ');
				
				var byte1 = input.readUnsignedByte();
				// trace(byte1);
				var byte1 = data.readUnsignedByte();
				// trace(byte1);
				testPos(input, data);				
				return new SystemMessage(type, byte1);
				
			case SystemMessageType.SYSTEM_RESET:
				// trace('--  case SystemMessageType.SYSTEM_RESET:  ');
				return inFile ? createMetaEventMessage(data, input) : new SystemMessage(type);
				
			case SystemMessageType.SYS_EX_START:
				// trace('--  case SystemMessageType.SYS_EX_START:  ');
				return createSystemExclusiveMessage(type, data, input);
				
			default:
				// trace('--  return new SystemMessage(type);  ');
				return new SystemMessage(type);
		}
	}
	
	function createMetaEventMessage (data:ByteArray, input:BytesInput) :Message {
		
		var type:UInt = input.readUnsignedByte();
		// trace(type);		
		var type:UInt = data.readUnsignedByte();
		// trace(type);
		testPos(input, data);
		
		var len:UInt = readVariableLengthUint(data, input);
		// trace(len);
		
		testPos(input, data);
		
		switch (type) {
			case MetaEventMessageType.TEXT,
				MetaEventMessageType.COPYRIGHT,
				MetaEventMessageType.TRACK_NAME,
				MetaEventMessageType.INSTRUMENT_NAME,
				MetaEventMessageType.LYRIC,
				MetaEventMessageType.MARKER,
				MetaEventMessageType.CUE_POINT,
				MetaEventMessageType.PROGRAM_NAME,
				MetaEventMessageType.DEVICE_NAME:
					
					// trace('MetaEventMessageType TEXT');
					
				var utfBytesStr:String = input.readString(len);
				// trace(utfBytesStr);
					
				var utfBytesStr:String = data.readUTFBytes(len);
				// trace(utfBytesStr);
				testPos(input, data);
					
				return new TextMessage(type,utfBytesStr);
			
			case MetaEventMessageType.MIDI_PORT:
				
				var byte = input.readUnsignedByte();
				// trace(byte);
				var byte = data.readUnsignedByte();
				// trace(byte);
				testPos(input, data);
				
				return new PortNumberMessage(byte);
				
			case MetaEventMessageType.SET_TEMPO:
				
				return createSetTempoMessage(data, input);
				
			case MetaEventMessageType.KEY_SIGNATURE:
				return createKeySignatureMessage(data, input);
				
			case MetaEventMessageType.TIME_SIGNATURE:
				return createTimeSignatureMessage(data, input);
				
			case MetaEventMessageType.END_OF_TRACK:
				return EndTrackMessage.END_OF_TRACK;
				
			case MetaEventMessageType.SEQUENCE_NUM:
				return new SequenceNumberMessage(data.readUnsignedByte(), data.readUnsignedByte());
			
			default:
				return InvalidMessage.INVALID;
		}
	}
	
	function createSetTempoMessage (data:ByteArray, input:BytesInput) :Message {
		
		var a:UInt = input.readUnsignedByte();
		var b:UInt = input.readUnsignedByte();
		var c:UInt = input.readUnsignedByte();		
		// trace([a, b, c]);
		
		var a:UInt = data.readUnsignedByte();
		var b:UInt = data.readUnsignedByte();
		var c:UInt = data.readUnsignedByte();
		// trace([a, b, c]);
		testPos(input, data);
		
		var micros:UInt = c | (b << 8) | (a << 16);
		
		return new SetTempoMessage(micros);
	}
	
	function createSystemExclusiveMessage (type:UInt, data:ByteArray, input:BytesInput) :Message {
		var len:UInt = readVariableLengthUint(data, input);
		var bytes:ByteArray = new ByteArray();
		
		// read all but the last 0xF7 into the data bytes for this SysEx
		data.readBytes(bytes, 0, len - 1);
		
		// gobble the trailing 0xF7
		if (data.readUnsignedByte() != 0xF7) {
			throw new InvalidFormatError("SysEx messages must be terminated by 0xF7");
		}
		return new SystemExclusiveMessage(type, bytes);
	}
	
	function createKeySignatureMessage (data:ByteArray, input:BytesInput) :Message {
		
		var numAccidentals:Int = input.readByte();
		// trace(numAccidentals);
		
		var numAccidentals:Int = data.readByte();
		// trace(numAccidentals);
		testPos(input, data);
		
		// 0 for major, 1 for minor
		
		var isMinor:Bool = input.readUnsignedByte() == 1;
		// trace(isMinor);		
		var isMinor:Bool = data.readUnsignedByte() == 1;
		// trace(isMinor);
		testPos(input, data);
		
		return new KeySignatureMessage(numAccidentals, isMinor);
	}
	
	function createTimeSignatureMessage (data:ByteArray, input:BytesInput) :Message {
		var numerator:UInt = input.readUnsignedByte();
		// trace(numerator);
		var numerator:UInt = data.readUnsignedByte();
		// trace(numerator);
		testPos(input, data);
		
		var denominator:UInt = cast(Math.pow(2, input.readUnsignedByte()));// time sig denominator is represented as the power to which 2 should be raised
		// trace(denominator);
		var denominator:UInt = cast(Math.pow(2, data.readUnsignedByte()));// time sig denominator is represented as the power to which 2 should be raised
		// trace(denominator);
		testPos(input, data);
		
		var clocksPerClick:UInt = input.readUnsignedByte();
		var clocksPerClick:UInt = data.readUnsignedByte();
		var thirtySecondthsPerQuarter:UInt = input.readUnsignedByte();
		var thirtySecondthsPerQuarter:UInt = data.readUnsignedByte();
		testPos(input, data);
		
		return new TimeSignatureMessage(numerator, denominator, clocksPerClick, thirtySecondthsPerQuarter);
	}
}

