package angel.roomedit {
	import angel.common.Util;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.text.TextField;
	import flash.text.TextFormatAlign;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class LabeledTextField extends Sprite {
		public var label:TextField;
		public var textField:TextField;
		
		public function LabeledTextField(labelText:String = null, labelWidth:int = 0, textWidth:int = 0,
				changeHandler:Function = null) {
			if (labelText != null) {
				labelText += ":  ";
			} else {
				labelText = "";
			}
			label = Util.textBox(labelText, labelWidth);
			textField = Util.textBox("", textWidth > 0 ? textWidth : Util.DEFAULT_TEXT_WIDTH, Util.DEFAULT_TEXT_HEIGHT, TextFormatAlign.LEFT, true);
			if (labelWidth == 0) {
				label.width = label.textWidth;
			}
			addChild(label);
			if (labelWidth > 0) {
				label.width = labelWidth;
			}
			Util.addBeside(textField, label);
			if (changeHandler != null) {
				textField.addEventListener(Event.CHANGE, changeHandler);
			}
		}
		
		public function get text():String {
			return textField.text;
		}
		
		public function set text(text:String):void {
			textField.text = text;
		}
		
		override public function set height(height:Number):void {
			label.height = height;
			textField.height = height;
		}
		
		public function set labelWidth(width:int):void {
			label.width = width;
			textField.width = this.width - width;
			textField.x = width;
		}
		
		public static function createBelow(existingControl:DisplayObject, labelText:String = null, labelWidth:int = 0, textWidth:int = 0,
				changeHandler:Function = null, optionalXInsteadOfAligning:int = int.MAX_VALUE):LabeledTextField {
			var field:LabeledTextField = new LabeledTextField(labelText, labelWidth, textWidth, changeHandler);
			Util.addBelow(field, existingControl, 5);
			if (optionalXInsteadOfAligning != int.MAX_VALUE) {
				field.x = optionalXInsteadOfAligning;
			}
			return field;
		}
		
	}

}