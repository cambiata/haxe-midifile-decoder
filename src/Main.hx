package;
import haxe.io.Bytes;
import haxe.io.BytesInput;
//import midi.MIDIFile2;
import midi.MidiFileDecoder;
import midi.MidiFile;
//import midi.MidiFileDecoder2;
import sys.io.File;


/**
 * ...
 * @author Jonas Nyström
 */
 
class Main
{
	static public function main() {
		var filename = 'testfiles/4.mid';
		
		var decoder = new MidiFileDecoder();
		var midiFile:MidiFile = decoder.decodeBytes(File.getBytes(filename));
		File.saveContent('midifile1.data', midiFile.trackEventsToString());
		
		/*
		var decoder = new MidiFileDecoder2();
		var midiFile2:MIDIFile2 = decoder.decodeBytes(File.getBytes(filename));
		File.saveContent('midifile2.data', midiFile2.eventsToString());
		*/
		
	}
	
}