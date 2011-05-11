package angel.roomedit {
	import angel.common.SimplerButton;
	import angel.common.Util;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormatAlign;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class FilenameControl extends Sprite {
		private static const DEFAULT_WIDTH:int = 250;
		private static const BUTTON_WIDTH:int = 55;
		private static const CLEAR_BUTTON_WIDTH:int = 12;
		private var textField:TextField;
		private var button:SimplerButton;
		private var clearButton:SimplerButton;
		
		public function FilenameControl(includeClearButton:Boolean = false, labelText:String = null, controlWidth:int = DEFAULT_WIDTH, labelWidth:int = 0) {
			var label:TextField;
			var finalLabelWidth:int = 0;
			if (labelText != null) {
				label = Util.textBox(labelText + ":", labelWidth, 20);
				if (labelWidth == 0) {
					label.autoSize = TextFieldAutoSize.LEFT;
				}
				addChild(label);
				finalLabelWidth = label.width + 2;
			}
			
			textField = Util.textBox("", controlWidth - finalLabelWidth - BUTTON_WIDTH - 5, 20);
			textField.x = finalLabelWidth;
			addChild(textField);
					
			button = new SimplerButton("Change", clickedButton);
			button.width = BUTTON_WIDTH;
			button.x = controlWidth - BUTTON_WIDTH;
			addChild(button);
			
			if (includeClearButton) {		
				clearButton = new SimplerButton("X", clickedClearButton);
				clearButton.width = CLEAR_BUTTON_WIDTH;
				clearButton.x = controlWidth - BUTTON_WIDTH - CLEAR_BUTTON_WIDTH;
				addChild(clearButton);
				textField.width -= CLEAR_BUTTON_WIDTH;
			}
		}
		
		public function set text(value:String):void {
			if (value == null) {
				value = "";
			}
			textField.text = value;
		}
		
		public function get text():String {
			return textField.text;
		}
		
		private function clickedButton(event:Event):void {
			new FileChooser(userSelectedNewFile, null, false);
		}
		
		private function userSelectedNewFile(filename:String):void {
			textField.text = filename;
			dispatchEvent(new Event(Event.CHANGE, true));
		}
		
		private function clickedClearButton(event:Event):void {
			textField.text = "";
			dispatchEvent(new Event(Event.CHANGE, true));
		}
		
		public function cleanup():void {
			button.cleanup();
			if (parent != null) {
				parent.removeChild(this);
			}
		}

		public static function createBelow(previousControl:DisplayObject, includeClearButton:Boolean, labelText:String, labelWidth:int, controlWidth:int, changeHandler:Function, optionalXInsteadOfAligning:int = int.MAX_VALUE):FilenameControl {
			var control:FilenameControl = new FilenameControl(includeClearButton, labelText, controlWidth, labelWidth);
			Util.addBelow(control, previousControl);
			if (optionalXInsteadOfAligning != int.MAX_VALUE) {
				control.x = optionalXInsteadOfAligning;
			}
			control.addEventListener(Event.CHANGE, changeHandler);
			return control;
		}
		
	}

}