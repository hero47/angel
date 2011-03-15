package angel.common {
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class Util {
		
		public function Util() {
			
		}
		
		public static const DEFAULT_TEXT_WIDTH:int = 100;
		public static const DEFAULT_TEXT_HEIGHT:int = 20;
		public static function textBox(text:String, width:int = DEFAULT_TEXT_WIDTH, height:int = DEFAULT_TEXT_HEIGHT, align:String = TextFormatAlign.LEFT,
					editable:Boolean=false, textColor:uint = 0):TextField {
			var myTextField:TextField = new TextField();
			myTextField.textColor = textColor;
			myTextField.selectable = editable;
			myTextField.width = width;
			myTextField.height = height;
			myTextField.type = (editable ? TextFieldType.INPUT : TextFieldType.DYNAMIC);
			myTextField.border = editable;
			
			var myTextFormat:TextFormat = new TextFormat();
			myTextFormat.size = height - 6;
			myTextFormat.align = align;
			myTextField.defaultTextFormat = myTextFormat;
			
			myTextField.text = text;
			return myTextField;
		}
		
	}

}