package midi.message;

class Message {
	
	public var status(default, null):UInt;
	
	public function new (status:UInt) {
		this.status = status;
	}
	
	public function toString () :String {
		return "[Message(status=" + MessageStatus.toString(status) + ")]";
	}
}
