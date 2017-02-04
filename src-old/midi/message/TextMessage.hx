package midi.message;
import midi.message.MetaEventMessage;

class TextMessage extends MetaEventMessage {
	
	var text(default, null):String;
	
	public function new (type:Int, text:String) {
		super(type);
		
		this.text = text;
	}
	
	override public function toString () :String {
		return "[TextMessage(type=" + type + " text=" + text + ")]";
	}
	
}
