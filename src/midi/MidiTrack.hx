package midi;

class MidiTrack {
	
	public var trackEvents(default, null):Array<MidiTrackEvent>;
		
	public function new(trackEvents:Array<MidiTrackEvent>) {
		this.trackEvents = trackEvents;
	}
	
	
	public function toString () :String {
		return "[MIDITrack(events=\n\t" + trackEvents.join("\n\t") + ")]";
	}
	
	//public function eventsToString(): String return events.join("\n\t");
	public function trackEventsToString(): String return trackEvents.join("\n\t");
	
	
}



