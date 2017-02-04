package midi.message;

import midi.message.Message;

class EndTrackMessage extends MetaEventMessage {
	
	public static var END_OF_TRACK:Message = new EndTrackMessage(MetaEventMessageType.END_OF_TRACK);
	
	public function new (type:UInt) {
		super(type);
	}
	
}
