package midi;
using Lambda;
class MidiFile {
	
	public var format(default, null):UInt;
	public var division(default, null):UInt;
	public var tracks(default, null):Array<MidiTrack>;
	public var numTracks(get, never):UInt;
	
	public function new (format:UInt, division:UInt, tracks:Array<MidiTrack> = null) {
		this.format = format;
		this.division = division;
		this.tracks = (tracks != null) ? tracks : new Array<MidiTrack>();
	}
	
	function get_numTracks () :UInt {
		return tracks.length;
	}
	
	public function toString () :String {
		return "[MIDIFile(format=" + format + " division=" + division + " numTracks=" + numTracks + " tracks=\n\t" + tracks.join("\n\t") + ")]";
	}
	
	
	
	public function trackEventsToString() return this.tracks.map(function(track) return track.trackEvents.join('\n\t')).join('\n\t');
	
	
}
