package angel.common {
	import flash.geom.Point;
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
		
		public static function pointOnCircleFromFacing(radius:Number, facing:Number, center:Point = null):Point {
			var loc:Point = new Point();

			loc.x = radius*Math.cos(facing*(Math.PI/180));
            loc.y = radius*Math.sin(facing*(Math.PI/180));
			if (center != null) {
				loc.x += center.x;
				loc.y += center.y;
			}
            return loc;
		}
		
		public static function findRotFacingVector(vector:Point):Number {
			return Math.atan2(vector.y, vector.x ) * 180 / Math.PI;
		}

		// Fisher-Yates shuffle
		// declaring v:Vector isn't allowed, but Object works. Yay CS5.
		public static function shuffle(v:Object):void {
			for (var i:int = v.length - 1; i > 0; i--)
			{
				var j:int = Math.floor(Math.random() * (i + 1));
				if (j != i) {
					var temp:* = v[i];
					v[i] = v[j];
					v[j] = temp;
				}
			}
		}
		
	}

}