package midi.message;
import midi.message.MetaEventMessage;
import midi.message.MetaEventMessageType;

class PortNumberMessage extends MetaEventMessage {
	
	var port(default, null):UInt;
	
	public function new (port:UInt) {
		super(MetaEventMessageType.MIDI_PORT);
	
		this.port = port;
	}
	
	override public function toString () :String {
		return "[PortNumberMessage(port=" + port + ")]";
	}
}
