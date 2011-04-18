package angel.game {
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.text.Font;
	import flash.text.TextField;
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
		
		[Embed(source='../../../EmbeddedAssets/conversation_action_box.png')]
		private static const ActionBox:Class;
		[Embed(source='../../../EmbeddedAssets/conversation_npc_arrow.png')]
		private static const NpcActionIcon:Class;
		[Embed(source='../../../EmbeddedAssets/conversation_pc_arrow.png')]
		private static const PcActionIcon:Class;

		/*
		[Embed(source = '../../../EmbeddedAssets/arial.ttf', fontName="Ariel", mimeType='application/x-font-truetype')]
		private var Ariel:Class;
		*/
		
		private var textField:TextField;
		
		// Currently taking bitmap, but this is likely to change to use a cataloged resource at some point
		public function ConversationBox(portraitBitmap:Bitmap, pc:Boolean) {
			
			graphics.beginFill(BOX_COLOR, 0.8);
			graphics.drawRoundRect( -BOX_WIDTH / 2, 0, BOX_WIDTH, BOX_HEIGHT, 20);
			
			var actionBox:Bitmap = new ActionBox();
			actionBox.x = -actionBox.width/2;
			actionBox.y = BOX_HEIGHT - (actionBox.height / 2);
			addChild(actionBox);
			
			textField = chatTextField();
			textField.width = BOX_WIDTH - TEXT_PORTRAIT_MARGIN - TEXT_OTHER_MARGIN;
			textField.height = BOX_HEIGHT - (actionBox.height / 2);
			addChild(textField);
			
			var actionIcon:Bitmap;
			
			addChild(portraitBitmap);
			portraitBitmap.y = (BOX_HEIGHT - portraitBitmap.height) / 2;
			if (pc) {
				portraitBitmap.x = (BOX_WIDTH - portraitBitmap.width) / 2;
				actionIcon = new PcActionIcon();
				textField.x = -BOX_WIDTH/2 + TEXT_OTHER_MARGIN;
			} else {
				portraitBitmap.x = -(BOX_WIDTH + portraitBitmap.width) / 2;
				actionIcon = new NpcActionIcon();
				textField.x = -BOX_WIDTH/2 + TEXT_PORTRAIT_MARGIN;
			}
			actionIcon.x = actionBox.x;
			actionIcon.y = actionBox.y;
			addChild(actionIcon);
			
			addEventListener(MouseEvent.CLICK, clickListener);
			addEventListener(Event.ADDED_TO_STAGE, addedToStageListener);
		}
		
		private function addedToStageListener(event:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, addedToStageListener);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownListener);
		}
		
		private function finished():void {
			removeEventListener(MouseEvent.CLICK, clickListener);
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDownListener);
			dispatchEvent(new Event(Event.COMPLETE));
		}
		
		public function set text(value:String):void {
			textField.text = value;
		}
		
		private function clickListener(event:MouseEvent):void {
			finished();
		}
		
		private function keyDownListener(event:KeyboardEvent):void {
			switch (event.keyCode) {
				case Keyboard.SPACE:
				case Keyboard.ENTER:
					finished();
				break;
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