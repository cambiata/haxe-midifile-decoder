package midi;
import midi.MIDITrack2;
using Lambda;
class MIDIFile2 {
	
	public var format(default, null):UInt;
	public var division(default, null):UInt;
	public var tracks(default, null):Array<MIDITrack2>;
	public var numTracks(get, never):UInt;
	
	public function new (format:UInt, division:UInt, tracks:Array<MIDITrack2> = null) {
		this.format = format;
		this.division = division;
		this.tracks = (tracks != null) ? tracks : new Array<MIDITrack2>();
	}
	
	function get_numTracks () :UInt {
		return tracks.length;
	}
	
	public function toString () :String {
		return "[MIDIFile(format=" + format + " division=" + division + " numTracks=" + numTracks + " tracks=\n\t" + tracks.join("\n\t") + ")]";
	}
	
	
	
	public function eventsToString() return this.tracks.map(function(track) return track.events.join('\n\t')).join('\n\t');
	
	
}
