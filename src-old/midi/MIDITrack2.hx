package midi;
import midi.message.MIDITrackEvent;
class MIDITrack2 extends MidiTrack {
	
	public var events(default, null):Array<MIDITrackEvent>;
	
	public function new (events:Array<MIDITrackEvent>) {
		super(null);
		this.events = events;
	}

	public function eventsToString(): String return events.join("\n\t");
	
}




