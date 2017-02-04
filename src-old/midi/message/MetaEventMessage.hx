package midi.message;

import midi.message.Message;
import midi.message.MessageStatus;
import midi.message.SystemMessageType;

class MetaEventMessage extends Message {
	
	public var type(default, null):UInt;
	
	public function new (type:UInt) {
		super(SystemMessageType.SYSTEM_RESET);
		
		this.type = type;
	}
	
	override public function toString () :String {
		return "[MetaEventMessage(status=" + StringTools.hex(status) + " type=" + MetaEventMessageType.toString(type) + ")]";
	}
}
