package angel.game.script {
	import angel.common.Alert;
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
		
		private static const BOX_COLOR:uint = 0x7923BE;
		private static const BOX_WIDTH:uint = 512;
		private static const BOX_HEIGHT:uint = 140;
		private static const TEXT_COLOR:uint = 0xffffff;
		private static const TEXT_PORTRAIT_MARGIN:uint = 100;
		private static const TEXT_OTHER_MARGIN:uint = 20;

		/*
		[Embed(source = '../../../EmbeddedAssets/arial.ttf', fontName="Ariel", mimeType='application/x-font-truetype')]
		private var Ariel:Class;
		*/
		
		private var textX:int;
		private var textFields:Vector.<TextField> = new Vector.<TextField>();
		private var mySegments:Vector.<ConversationSegment>;
		
		// Currently taking bitmap, but this is likely to change to use a cataloged resource at some point
		public function ConversationBox(portraitBitmap:Bitmap, pc:Boolean) {
			
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
			
			addEventListener(MouseEvent.CLICK, clickListener);
			addEventListener(Event.ADDED_TO_STAGE, addedToStageListener);
		}
		
		private function addedToStageListener(event:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, addedToStageListener);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownListener);
		}
		
		private function finished(selected:ConversationSegment):void {
			removeEventListener(MouseEvent.CLICK, clickListener);
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDownListener);
			dispatchEvent(new ConversationEvent(ConversationEvent.SEGMENT_FINISHED, selected, true));
		}
		
		public function set segments(rawSegments:Vector.<ConversationSegment>):void {
			mySegments = new Vector.<ConversationSegment>();
			for (var i:int = 0; i < rawSegments.length; i++) {
				if (rawSegments[i].haveAllNeededFlags()) {
					mySegments.push(rawSegments[i]);
				}
			}
			
			for (i = 0; i < mySegments.length; i++) {
				var segment:ConversationSegment = mySegments[i];
				var textField:TextField = chatTextField();
				textField.width = BOX_WIDTH - TEXT_PORTRAIT_MARGIN - TEXT_OTHER_MARGIN;
				textField.wordWrap = true;
				textField.autoSize = TextFieldAutoSize.LEFT;
				textField.text = (mySegments.length > 1 ? String(i + 1) + ") " + segment.text : segment.text);
				textField.x = textX;
				if (i > 0) {
					textField.y = textFields[i - 1].y + textFields[i - 1].height;
				}
				addChild(textField);
				textFields.push(textField);
			}
			if (mySegments.length == 0) {
				Alert.show("Error! No valid choice for conversation box.");
			} else if (mySegments.length > 9) {
				Alert.show("Error! Too many valid choices in conversation box.");
			}
		}
		
		// If there's only one choice, they can click anywhere in the box.
		// If there are multiple choices, they must click on the text for their choice; other clicks are ignored.
		private function clickListener(event:MouseEvent):void {
			if (mySegments.length == 0) {
				finished(null);
			} else if (mySegments.length < 2) {
				finished(mySegments[0]);
			} else {
				var i:int = textFields.indexOf(event.target);
				if (i >= 0) {
					finished(mySegments[i]);
				}
			}
		}
		
	private function keyDownListener(event:KeyboardEvent):void {
			var i:int = event.charCode - "1".charCodeAt(0);
			if (i >= 0 && i < mySegments.length) {
				finished(mySegments[i]);
			} else {
				switch (event.keyCode) {
					case Keyboard.SPACE:
					case Keyboard.ENTER:
						if (mySegments.length == 0) {
							finished(null);
						} else {
							finished(mySegments[0]);
						}
					break;
				}
			}
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