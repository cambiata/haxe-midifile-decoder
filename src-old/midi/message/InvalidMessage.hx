package midi.message;
import midi.message.Message;
import midi.message.MessageStatus;

class InvalidMessage extends Message {
	
	public static var INVALID:Message = new InvalidMessage(MessageStatus.INVALID);
	
	public function new (status:Int) {
		super(status);
	}
	
	override public function toString () :String {
		return "[InvalidMessage(status=" + StringTools.hex(status) + ")]";
	}
}
