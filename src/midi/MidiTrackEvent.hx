package midi;
import midi.MidiMessage;

/**
 * @author Jonas Nyström
 */

typedef MidiTrackEvent =
{
	time:UInt,
	message:MidiMessage,
}