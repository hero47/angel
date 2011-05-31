package angel.game.script {
	import angel.common.Alert;
	import angel.game.event.QEvent;
	import angel.game.Settings;
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.text.Font;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;
	
	/**
	 * ...
	 * @author Beth Moursund
	 */
	
	// 0,0 of conversation box is the center of the top edge of the box.
	// The portrait overlaps left edge for NPC, right edge for PC, and may extend above and below box.
	// I'm going to try to avoid any assumptions about the portrait art size.
	public class ConversationBox extends Sprite {
		public static const CONVERSATION_ENTRY_FINISHED:String = "conversationEntryFinished";
		
		private static const BOX_COLOR:uint = 0x7923BE;
		private static const BOX_WIDTH:uint = 512;
		private static const BOX_HEIGHT:uint = 140;
		private static const TEXT_COLOR:uint = 0xffffff;
		private static const TEXT_PORTRAIT_MARGIN:uint = 100;
		private static const TEXT_OTHER_MARGIN:uint = 20;

		private var textX:int;
		private var textFields:Vector.<TextField> = new Vector.<TextField>();
		private var mySegments:Vector.<ConversationSegment>;
		private var isPrimary:Boolean;
		
		private var numberOfHeaders:int = 0;
		private var anyKeySelectsSegment:ConversationSegment;
		
		// Currently taking bitmap, but this is likely to change to use a cataloged resource at some point
		// If a conversation entry has only one conversation box, then that box is primary.  Otherwise, the PC box is
		// primary.  The primary box sends ENTRY_FINISHED event when user makes a selection.
		public function ConversationBox(portraitBitmap:Bitmap, pc:Boolean, rawSegments:Vector.<ConversationSegment>, primary:Boolean) {
			graphics.beginFill(BOX_COLOR, 0.8);
			graphics.drawRoundRect( -BOX_WIDTH / 2, 0, BOX_WIDTH, BOX_HEIGHT, 20);
			
			addChild(portraitBitmap);
			portraitBitmap.y = (BOX_HEIGHT - portraitBitmap.height) / 2;
			if (pc) {
				portraitBitmap.x = (BOX_WIDTH - portraitBitmap.width) / 2;
				textX = -BOX_WIDTH/2 + TEXT_OTHER_MARGIN;
			} else {
				portraitBitmap.x = -(BOX_WIDTH + portraitBitmap.width) / 2;
				textX = -BOX_WIDTH/2 + TEXT_PORTRAIT_MARGIN;
			}
			segments = rawSegments;
			
			if (primary) {
				addEventListener(MouseEvent.CLICK, clickListener);
				addEventListener(Event.ADDED_TO_STAGE, addedToStageListener);
			}
		}
		
		private function addedToStageListener(event:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, addedToStageListener);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownListener);
		}
		
		private function finished(selected:ConversationSegment):void {
			removeEventListener(MouseEvent.CLICK, clickListener);
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDownListener);
			Settings.gameEventQueue.dispatch(new QEvent(this, ConversationBox.CONVERSATION_ENTRY_FINISHED, selected));
		}
		
		public function set segments(rawSegments:Vector.<ConversationSegment>):void {
			mySegments = new Vector.<ConversationSegment>();
			for (var i:int = 0; i < rawSegments.length; i++) {
				if (rawSegments[i].haveAllNeededFlags()) {
					if (rawSegments[i].header) {
						++numberOfHeaders;
					}
					mySegments.push(rawSegments[i]);
				}
			}
			
			if (numberOfHeaders == mySegments.length - 1) {
				anyKeySelectsSegment = mySegments[numberOfHeaders];
			}
			
			for (i = 0; i < mySegments.length; i++) {
				var segment:ConversationSegment = mySegments[i];
				var textField:TextField = chatTextField();
				textField.width = BOX_WIDTH - TEXT_PORTRAIT_MARGIN - TEXT_OTHER_MARGIN;
				textField.wordWrap = true;
				textField.autoSize = TextFieldAutoSize.LEFT;
				textField.text = segment.text;
				if ((!segment.header) && (anyKeySelectsSegment == null)) {
					textField.text = String(i - numberOfHeaders + 1) + ") " + textField.text;
				}
				textField.x = textX;
				if (i > 0) {
					textField.y = textFields[i - 1].y + textFields[i - 1].height;
				}
				addChild(textField);
				textFields.push(textField);
			}
			if (numberOfHeaders >= mySegments.length) {
				Alert.show("Error! No valid choice for conversation box.");
			} else if (mySegments.length > 9) {
				Alert.show("Error! Too many valid choices in conversation box.");
			}
		}
		
		public function addDisplayedHeadersToList(list:Vector.<ConversationSegment>):void {
			for (var i:int = 0; i < numberOfHeaders; i++) {
				list.push(mySegments[i]);
			}
		}
		
		// If there's only one choice, they can click anywhere in the box.
		// If there are multiple choices, they must click on the text for their choice; other clicks are ignored.
		private function clickListener(event:MouseEvent):void {
			if (numberOfHeaders >= mySegments.length) {
				finished(null);
			} else if (anyKeySelectsSegment != null) {
				finished(anyKeySelectsSegment);
			} else {
				var i:int = textFields.indexOf(event.target);
				if ((i >= 0) && (!mySegments[i].header)) {
					finished(mySegments[i]);
				}
			}
		}
		
		// If there's only one choice, press any key at all to accept it.
		// If there are multiple choices, "1" or space or enter picks the first one, other numbers pick that number,
		// and other keys are ignored.
		private function keyDownListener(event:KeyboardEvent):void {
			if (numberOfHeaders >= mySegments.length) {
				finished(null);
				return;
			}
			if (anyKeySelectsSegment != null) {
				finished(anyKeySelectsSegment);
				return;
			}
			
			var choice:ConversationSegment;
			var numberPressed:int = event.charCode - "1".charCodeAt(0);
			if (numberPressed <= mySegments.length - numberOfHeaders) {
				choice = mySegments[numberPressed - numberOfHeaders];
			} else {
				switch (event.keyCode) {
					case Keyboard.SPACE:
					case Keyboard.ENTER:
						choice = mySegments[numberOfHeaders];
					break;
					default:
						return;
					break;
				}
			}
			finished(choice);
		}
		
		private function chatTextField():TextField {
			var myTextField:TextField = new TextField();
			myTextField.textColor = TEXT_COLOR;
			myTextField.selectable = false;
			myTextField.width = width;
			myTextField.height = height;
			myTextField.type = TextFieldType.DYNAMIC;
			myTextField.border = false;
			myTextField.multiline = true;
			myTextField.wordWrap = true;
			
//var myTextFormat:TextFormat = new TextFormat(ARIEL, 14, 0xFFFFFFFF);

			var myTextFormat:TextFormat = new TextFormat();
			myTextFormat.font = "Arial";
			myTextFormat.size = 15;
			myTextFormat.color = TEXT_COLOR;
			
			myTextField.defaultTextFormat = myTextFormat;
//			myTextField.embedFonts = true;
			
			return myTextField;
		}
		
	}

}