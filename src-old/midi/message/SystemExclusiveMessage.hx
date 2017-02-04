package midi.message;

import flash.utils.ByteArray;
import midi.message.Message;
import midi.message.MessageStatus;

class SystemExclusiveMessage extends Message {
	
	var type(default, null):UInt;
	var data(default, null):ByteArray;
	
	public function new (type:UInt, data:ByteArray) {
		super(MessageStatus.SYSTEM);
		
		this.type = type;
		this.data = data;
	}
	
	override public function toString () :String {
		return "[SystemExclusiveMessage(type=" + type + " data=" + data + ")]";
	}
	
}

